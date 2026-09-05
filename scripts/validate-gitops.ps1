param(
    [string]$OverlayPath = (Join-Path $PSScriptRoot "..\gitops\togglemaster")
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $OverlayPath)) {
    throw "Overlay path not found: $OverlayPath"
}

$resolvedOverlayPath = (Resolve-Path -LiteralPath $OverlayPath).Path
kubectl kustomize --load-restrictor=LoadRestrictionsNone $resolvedOverlayPath | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "kubectl kustomize failed for $resolvedOverlayPath"
}

Write-Host "GitOps overlay rendered successfully: $resolvedOverlayPath"
