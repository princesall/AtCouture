# Déploiement web StyleConnect — usage : .\scripts\deploy_web.ps1
#
# Deux détails volontairement encodés ici, appris à la dure :
#
# 1. --pwa-strategy=none : sans ce drapeau, Flutter régénère un service worker
#    complet qui met en cache index.html ET main.dart.js. Après un déploiement,
#    le navigateur peut alors servir l'ANCIENNE application pendant des heures,
#    et même le script de désenregistrement d'index.html ne s'exécute pas
#    puisque c'est justement l'ancien index.html qui est servi.
#
# 2. Le déploiement passe par Firebase Hosting avec --project explicite pour ne
#    jamais viser un autre projet par erreur.
#
# Après déploiement, vérification automatique que le service worker déployé est
# bien vide (0 octet) : c'est la garantie que la neutralisation a fonctionné.

param(
    [string]$Project = "styleconnect-25e1c"
)

$ErrorActionPreference = "Stop"

Write-Host ">> Build web (release, sans PWA)" -ForegroundColor Cyan
flutter build web --release --pwa-strategy=none
if ($LASTEXITCODE -ne 0) { throw "flutter build web a échoué" }

$sw = "build/web/flutter_service_worker.js"
if (Test-Path $sw) {
    $size = (Get-Item $sw).Length
    Write-Host "   flutter_service_worker.js = $size octet(s)" -ForegroundColor DarkGray
    if ($size -gt 0) {
        throw "Le service worker n'est pas vide : le drapeau --pwa-strategy=none n'a pas été pris en compte."
    }
}

Write-Host ">> Déploiement Firebase Hosting ($Project)" -ForegroundColor Cyan
firebase deploy --only hosting --project $Project
if ($LASTEXITCODE -ne 0) { throw "firebase deploy a échoué" }

Write-Host ">> Terminé : https://styleconnect.web.app" -ForegroundColor Green
