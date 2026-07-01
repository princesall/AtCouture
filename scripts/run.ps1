# Script de lancement StyleConnect (contourne le bug Windows + espaces dans le chemin)
# Usage : .\scripts\run.ps1
#         .\scripts\run.ps1 -Device windows

param(
    [string]$Device = "chrome"
)

$ErrorActionPreference = "Stop"

# Cache Pub sans espace (obligatoire sur Windows si le profil contient un espace)
$env:PUB_CACHE = "C:\pub-cache"
New-Item -ItemType Directory -Force -Path $env:PUB_CACHE | Out-Null

# Projet sans espace dans le chemin
$source = Split-Path -Parent $PSScriptRoot
$target = "C:\AtCouture"

Write-Host ">> Synchronisation vers $target ..." -ForegroundColor Cyan
robocopy $source $target /E /XD build .dart_tool .git /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null

Set-Location $target
Write-Host ">> flutter pub get ..." -ForegroundColor Cyan
flutter pub get

Write-Host ">> flutter run -d $Device ..." -ForegroundColor Green
flutter run -d $Device
