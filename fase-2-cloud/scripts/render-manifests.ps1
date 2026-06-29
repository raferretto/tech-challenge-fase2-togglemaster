param(
    [string]$TerraformDir = (Join-Path $PSScriptRoot "..\terraform"),
    [string]$SourceDir = (Join-Path $PSScriptRoot "..\k8s"),
    [string]$OutputDir = (Join-Path $PSScriptRoot "..\generated-k8s")
)

$ErrorActionPreference = "Stop"

function Get-TerraformOutputs {
    param([string]$Dir)

    $rawJson = terraform -chdir=$Dir output -json
    if (-not $rawJson) {
        throw "terraform output -json returned no data from $Dir"
    }

    return $rawJson | ConvertFrom-Json
}

function Get-OutputValue {
    param(
        [Parameter(Mandatory = $true)] $Outputs,
        [Parameter(Mandatory = $true)] [string]$Name
    )

    if (-not $Outputs.PSObject.Properties.Name.Contains($Name)) {
        throw "Missing Terraform output: $Name"
    }

    return $Outputs.$Name.value
}

function Assert-PlaceholderReplaced {
    param(
        [string]$Path,
        [string[]]$Needles
    )

    $content = Get-Content -Path $Path -Raw
    foreach ($needle in $Needles) {
        if ($content -match [regex]::Escape($needle)) {
            throw "Placeholder '$needle' was not replaced in $Path"
        }
    }
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$outputs = Get-TerraformOutputs -Dir $TerraformDir
$ecrUrls = Get-OutputValue -Outputs $outputs -Name "ecr_repository_urls"
$secretValues = @{
    "auth-service-secret.DATABASE_URL"                = Get-OutputValue -Outputs $outputs -Name "auth_service_database_url_b64"
    "auth-service-secret.MASTER_KEY"                  = Get-OutputValue -Outputs $outputs -Name "auth_service_master_key_b64"
    "auth-service-secret.SERVICE_API_KEY"             = Get-OutputValue -Outputs $outputs -Name "service_api_key_b64"
    "flag-service-secret.DATABASE_URL"                = Get-OutputValue -Outputs $outputs -Name "flag_service_database_url_b64"
    "targeting-service-secret.DATABASE_URL"           = Get-OutputValue -Outputs $outputs -Name "targeting_service_database_url_b64"
    "evaluation-service-secret.REDIS_URL"             = Get-OutputValue -Outputs $outputs -Name "evaluation_service_redis_url_b64"
    "evaluation-service-secret.AWS_SQS_URL"            = Get-OutputValue -Outputs $outputs -Name "evaluation_service_sqs_url_b64"
    "evaluation-service-secret.SERVICE_API_KEY"       = Get-OutputValue -Outputs $outputs -Name "service_api_key_b64"
    "analytics-service-secret.AWS_SQS_URL"             = Get-OutputValue -Outputs $outputs -Name "analytics_service_sqs_url_b64"
}

Get-ChildItem -Path $SourceDir -Filter *.yaml -File | ForEach-Object {
    $destination = Join-Path $OutputDir $_.Name
    $content = Get-Content -Path $_.FullName -Raw

    if ($content -match "REPLACE_ME_ECR_URI") {
        foreach ($serviceName in @("auth-service", "flag-service", "targeting-service", "evaluation-service", "analytics-service")) {
            if (-not $ecrUrls.PSObject.Properties.Name.Contains($serviceName)) {
                throw "Missing ECR URL output for service: $serviceName"
            }

            $content = $content.Replace("REPLACE_ME_ECR_URI/$serviceName:latest", "$($ecrUrls.$serviceName):latest")
        }
    }

    foreach ($entry in $secretValues.GetEnumerator()) {
        $content = $content.Replace("UkVQTEFDRV9NRQ==", $entry.Value)
    }

    Set-Content -Path $destination -Value $content -NoNewline
}

Assert-PlaceholderReplaced -Path (Join-Path $OutputDir "auth-service.yaml") -Needles @("REPLACE_ME_ECR_URI")
Assert-PlaceholderReplaced -Path (Join-Path $OutputDir "flag-service.yaml") -Needles @("REPLACE_ME_ECR_URI")
Assert-PlaceholderReplaced -Path (Join-Path $OutputDir "targeting-service.yaml") -Needles @("REPLACE_ME_ECR_URI")
Assert-PlaceholderReplaced -Path (Join-Path $OutputDir "evaluation-service.yaml") -Needles @("REPLACE_ME_ECR_URI")
Assert-PlaceholderReplaced -Path (Join-Path $OutputDir "analytics-service.yaml") -Needles @("REPLACE_ME_ECR_URI")
Assert-PlaceholderReplaced -Path (Join-Path $OutputDir "secrets.yaml") -Needles @("UkVQTEFDRV9NRQ==")

Write-Host "Rendered Kubernetes manifests in $OutputDir"
