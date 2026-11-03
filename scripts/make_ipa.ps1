# Conversion .app -> .ipa pour Sideloadly (Windows)
#
# Pourquoi ce script : Codemagic produit une application iOS NON SIGNÉE
# (build/ios/iphoneos/Runner.app, livrée en .zip dans les artefacts), alors que
# Sideloadly attend un .ipa. Un .ipa n'est rien d'autre qu'un ZIP dont la racine
# contient un dossier « Payload » renfermant l'application. Ce script fait cette
# conversion sans dépendance externe (Compress-Archive est fourni avec
# Windows PowerShell 5.1).
#
# Ensuite : glisser le .ipa dans Sideloadly, saisir son Apple ID (gratuit),
# démarrer l'installation, puis sur l'iPhone faire confiance au certificat
# (Réglages > Général > VPN et gestion de l'appareil) et activer le mode
# développeur (Réglages > Confidentialité et sécurité > Mode développeur).
#
# Rappel : avec un Apple ID gratuit, l'app expire au bout de 7 jours et il faut
# relancer Sideloadly ; 3 applications maximum par compte.
#
# Exemples :
#   .\scripts\make_ipa.ps1 -Path "$HOME\Downloads\Runner.app"
#   .\scripts\make_ipa.ps1 -Path "$HOME\Downloads\Runner.zip" -Output "$HOME\Desktop\StyleConnect.ipa"

param(
    [Parameter(Mandatory = $true, HelpMessage = "Chemin du Runner.app ou du .zip téléchargé depuis Codemagic")]
    [string]$Path,

    [string]$Output
)

$ErrorActionPreference = "Stop"

$source = (Resolve-Path -Path $Path).Path

# Le dossier de travail reste dans le TEMP : on n'écrit rien à côté des fichiers
# téléchargés tant que la conversion n'a pas réussi.
$work = Join-Path $env:TEMP ("make_ipa_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $work | Out-Null

try {
    $app = $null

    if (Test-Path -Path $source -PathType Container) {
        # Cas direct : l'utilisateur pointe le dossier Runner.app
        if ($source -notlike "*.app") {
            throw "Le dossier fourni n'est pas une application iOS (.app) : $source"
        }
        $app = $source
    }
    else {
        # Cas le plus courant : Codemagic livre un .zip contenant Runner.app
        if ($source -notlike "*.zip") {
            throw "Fichier non pris en charge : $source (attendu : .app ou .zip)"
        }
        Write-Host ">> Extraction de $([IO.Path]::GetFileName($source))" -ForegroundColor Cyan
        Expand-Archive -Path $source -DestinationPath (Join-Path $work "unzipped") -Force
        $found = @(Get-ChildItem -Path (Join-Path $work "unzipped") -Filter "*.app" -Recurse -Directory)
        if ($found.Count -eq 0) {
            throw "Aucun .app trouvé dans l'archive $source"
        }
        if ($found.Count -gt 1) {
            throw "Plusieurs .app trouvés dans l'archive, précisez le bon chemin manuellement : $($found.FullName -join ', ')"
        }
        $app = $found[0].FullName
    }

    # Contrôle minimal : une app iOS contient toujours un Info.plist et un
    # exécutable portant le nom du bundle. Sans ça, on produirait un .ipa que
    # Sideloadly refuserait, avec un message peu explicite.
    $infoPlist = Join-Path $app "Info.plist"
    if (-not (Test-Path -Path $infoPlist)) {
        throw "Info.plist absent de $app : ce dossier n'est pas une application iOS valide."
    }
    $exeName = Split-Path -Path $app -Leaf
    $exeName = $exeName.Substring(0, $exeName.Length - 4)  # retire « .app »
    if (-not (Test-Path -Path (Join-Path $app $exeName))) {
        throw "Exécutable « $exeName » absent de $app : build incomplet (l'app n'a pas été compilée en release ?)."
    }

    $appName = Split-Path -Path $app -Leaf
    if (-not $Output) {
        $Output = Join-Path (Split-Path -Path $source -Parent) ([IO.Path]::GetFileNameWithoutExtension($appName) + ".ipa")
    }
    $Output = [IO.Path]::GetFullPath($Output)

    Write-Host ">> Préparation de la structure Payload" -ForegroundColor Cyan
    $payload = Join-Path $work "stage\Payload"
    New-Item -ItemType Directory -Path $payload | Out-Null
    Copy-Item -Path $app -Destination $payload -Recurse

    # Compress-Archive crée ici une archive dont la racine est « Payload/ »,
    # exactement ce qu'attend Sideloadly.
    $zip = Join-Path $work "payload.zip"
    Write-Host ">> Compression" -ForegroundColor Cyan
    Compress-Archive -Path (Join-Path $work "stage\Payload") -DestinationPath $zip -CompressionLevel Optimal

    Copy-Item -Path $zip -Destination $Output -Force

    $sizeMb = [math]::Round((Get-Item $Output).Length / 1MB, 2)
    Write-Host ""
    Write-Host ">> IPA prêt : $Output ($sizeMb Mo)" -ForegroundColor Green
    Write-Host "   1. Ouvrir Sideloadly et brancher l'iPhone (déverrouillé, « Faire confiance »)."
    Write-Host "   2. Glisser le .ipa dans Sideloadly, saisir l'Apple ID, cliquer sur Start."
    Write-Host "   3. Sur l'iPhone : Réglages > Général > VPN et gestion de l'appareil > faire confiance."
    Write-Host "   4. iOS 16+ : Réglages > Confidentialité et sécurité > Mode développeur, puis redémarrer."
    Write-Host "   Rappel : compte gratuit = l'app expire au bout de 7 jours."
}
finally {
    if (Test-Path -Path $work) {
        Remove-Item -Path $work -Recurse -Force -ErrorAction SilentlyContinue
    }
}
