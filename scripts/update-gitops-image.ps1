param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("auth-service", "flag-service", "targeting-service", "evaluation-service", "analytics-service")]
    [string]$Service,

    [Parameter(Mandatory = $true)]
    [string]$Tag,

    [string]$KustomizationPath = (Join-Path $PSScriptRoot "..\gitops\togglemaster\kustomization.yaml")
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $KustomizationPath)) {
    throw "Kustomization file not found: $KustomizationPath"
}

$resolvedKustomizationPath = (Resolve-Path -LiteralPath $KustomizationPath).Path
$content = Get-Content -LiteralPath $resolvedKustomizationPath -Raw
$pattern = "(?ms)(- name:\s+.*\/$([regex]::Escape($Service))\s+newTag:\s+)(\S+)"

if ($content -notmatch "/$([regex]::Escape($Service))") {
    throw "Service image not found in ${resolvedKustomizationPath}: $Service"
}

$updated = [regex]::Replace($content, $pattern, "`$1$Tag")
Set-Content -LiteralPath $resolvedKustomizationPath -Value $updated -NoNewline

Write-Host "Updated $Service in $resolvedKustomizationPath to tag $Tag"
