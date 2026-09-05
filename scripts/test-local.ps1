param(
    [switch]$KeepEnvironment,
    [switch]$IncludeTerraform,
    [ValidateRange(30, 300)]
    [int]$HealthTimeoutSeconds = 180,
    [string]$ComposeNetwork = "fase-2-local_default"
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$composeFile = Join-Path $repoRoot "fase-2-local\docker-compose.yml"
$gitOpsValidator = Join-Path $PSScriptRoot "validate-gitops.ps1"
$terraformDirectory = Join-Path $repoRoot "fase-2-cloud\terraform"
$composeStarted = $false

function Invoke-Compose {
    param([string[]]$Arguments)

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $composeOutput = @(& docker compose -f $script:composeFile @Arguments 2>&1)
        $composeExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    $composeOutput | ForEach-Object { Write-Host $_ }

    if ($composeExitCode -ne 0) {
        $outputText = $composeOutput -join [Environment]::NewLine
        throw "docker compose failed with exit code ${composeExitCode}: $($Arguments -join ' ')`n$outputText"
    }
}

function Wait-ForHealthyServices {
    $healthEndpoints = @(
        "http://localhost:8001/health",
        "http://localhost:8002/health",
        "http://localhost:8003/health",
        "http://localhost:8004/health",
        "http://localhost:8005/health"
    )
    $deadline = (Get-Date).AddSeconds($HealthTimeoutSeconds)

    do {
        $unhealthyEndpoints = @()

        foreach ($endpoint in $healthEndpoints) {
            try {
                Invoke-RestMethod -Uri $endpoint -TimeoutSec 5 | Out-Null
            }
            catch {
                $unhealthyEndpoints += $endpoint
            }
        }

        if ($unhealthyEndpoints.Count -eq 0) {
            Write-Host "[OK] Todos os cinco servicos responderam ao health check."
            return
        }

        Start-Sleep -Seconds 3
    } while ((Get-Date) -lt $deadline)

    throw "Timeout aguardando health checks: $($unhealthyEndpoints -join ', ')"
}

function Wait-ForAnalyticsEvent {
    param([string]$FlagName)

    $deadline = (Get-Date).AddSeconds(60)

    do {
        $scanOutput = & docker run --rm `
            --network $ComposeNetwork `
            -e AWS_ACCESS_KEY_ID=dummy `
            -e AWS_SECRET_ACCESS_KEY=dummy `
            -e AWS_REGION=us-east-1 `
            amazon/aws-cli:2.15.57 `
            dynamodb scan `
            --table-name ToggleMasterAnalytics `
            --endpoint-url http://dynamodb-local:8000

        if ($LASTEXITCODE -ne 0) {
            throw "Nao foi possivel consultar o DynamoDB Local."
        }

        if (($scanOutput -join [Environment]::NewLine) -match [regex]::Escape($FlagName)) {
            Write-Host "[OK] Evento da avaliacao encontrado no DynamoDB Local."
            return
        }

        Start-Sleep -Seconds 3
    } while ((Get-Date) -lt $deadline)

    throw "Timeout aguardando o analytics registrar o evento da flag $FlagName."
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker Desktop e Docker Compose sao necessarios para a validacao local."
}

& docker version --format "{{.Server.Version}}" | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "O daemon do Docker nao esta em execucao. Abra o Docker Desktop e tente novamente."
}

if (-not (Test-Path -LiteralPath $composeFile)) {
    throw "Compose file not found: $composeFile"
}

try {
    Write-Host "[1/6] Validando Docker Compose..."
    Invoke-Compose -Arguments @("config", "-q")

    Write-Host "[2/6] Subindo ambiente local e compilando imagens..."
    Invoke-Compose -Arguments @("up", "-d", "--build")
    $composeStarted = $true

    Write-Host "[3/6] Aguardando os cinco servicos..."
    Wait-ForHealthyServices

    Write-Host "[4/6] Executando fluxo de autenticacao, flag, regra e avaliacao..."
    $headers = @{ Authorization = "Bearer tm_key_evaluation_local" }
    $flagName = "validation-$([guid]::NewGuid().ToString('N').Substring(0, 8))"

    Invoke-RestMethod -Uri "http://localhost:8001/validate" -Headers $headers | Out-Null

    $flagBody = @{
        name        = $flagName
        description = "Flag criada pela validacao local automatizada"
        is_enabled  = $true
    } | ConvertTo-Json -Compress
    Invoke-RestMethod -Uri "http://localhost:8002/flags" -Method Post -Headers $headers -ContentType "application/json" -Body $flagBody | Out-Null

    $ruleBody = @{
        flag_name  = $flagName
        is_enabled = $true
        rules      = @{
            type  = "PERCENTAGE"
            value = 50
        }
    } | ConvertTo-Json -Depth 3 -Compress
    Invoke-RestMethod -Uri "http://localhost:8003/rules" -Method Post -Headers $headers -ContentType "application/json" -Body $ruleBody | Out-Null

    Invoke-RestMethod -Uri "http://localhost:8004/evaluate?user_id=validation-user&flag_name=$flagName" | Out-Null
    Invoke-RestMethod -Uri "http://localhost:8004/evaluate?user_id=validation-user&flag_name=$flagName" | Out-Null
    Write-Host "[OK] Fluxo de negocio e segunda avaliacao para cache executados."

    Write-Host "[5/6] Confirmando consumo do evento pelo analytics..."
    Wait-ForAnalyticsEvent -FlagName $flagName

    Write-Host "[6/6] Validando renderizacao do GitOps..."
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        throw "kubectl e necessario para validar os manifestos GitOps."
    }
    & $gitOpsValidator

    if ($IncludeTerraform) {
        if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
            throw "Terraform e necessario quando -IncludeTerraform for informado."
        }

        Write-Host "Validando formatacao e sintaxe do Terraform sem acessar a AWS..."
        Push-Location $terraformDirectory
        try {
            & terraform fmt -check -recursive .
            if ($LASTEXITCODE -ne 0) { throw "terraform fmt -check failed." }

            & terraform init -reconfigure -backend=false -input=false
            if ($LASTEXITCODE -ne 0) { throw "terraform init -backend=false failed." }

            & terraform validate
            if ($LASTEXITCODE -ne 0) { throw "terraform validate failed." }
        }
        finally {
            Pop-Location
        }
    }

    Write-Host ""
    Write-Host "Validacao local concluida com sucesso."
}
catch {
    Write-Host ""
    Write-Host "Falha na validacao local. Ultimos logs do Compose:" -ForegroundColor Red
    & docker compose -f $composeFile logs --tail 100
    throw
}
finally {
    if ($composeStarted -and -not $KeepEnvironment) {
        Write-Host "Encerrando o ambiente local. Use -KeepEnvironment para preserva-lo."
        & docker compose -f $composeFile down
    }
}
