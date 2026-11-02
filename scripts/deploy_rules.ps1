# Déploiement des règles Firestore + Storage — usage : .\scripts\deploy_rules.ps1
#
# À lancer après toute modification de firestore.rules ou storage.rules.
# Les nouvelles fonctionnalités de la console admin en dépendent :
#  - systemConfig/app (maintenance, feature flags, notes de version) ;
#  - featureEvents (télémétrie d'usage) ;
#  - systemErrors (journal d'erreurs) ;
#  - lastLoginAt (contrôle d'inactivité) ;
#  - lecture admin des mémos vocaux (mesure du stockage).

param(
    [string]$Project = "styleconnect-25e1c"
)

$ErrorActionPreference = "Stop"

Write-Host ">> Déploiement des règles Firestore ($Project)" -ForegroundColor Cyan
firebase deploy --only firestore:rules --project $Project
if ($LASTEXITCODE -ne 0) { throw "firebase deploy (règles Firestore) a échoué" }

# Le bucket Storage doit d'abord être initialisé dans la console Firebase
# (Storage > Get Started). Sinon le déploiement des règles Storage échoue et
# ne doit pas empêcher les règles Firestore d'être publiées.
Write-Host ">> Déploiement des règles Storage ($Project)" -ForegroundColor Cyan
firebase deploy --only storage --project $Project
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Règles Storage non déployées : initialisez Storage dans la console Firebase (Storage > Get Started), puis relancez ce script."
    exit 0
}

Write-Host ">> Règles Firestore + Storage déployées." -ForegroundColor Green
