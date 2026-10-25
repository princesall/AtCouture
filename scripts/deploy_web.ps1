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

# Le service worker généré par Flutter met en cache l'application : après un
# déploiement, un navigateur déjà venu peut servir l'ancienne version pendant
# des heures. On le remplace donc par un service worker « auto-destructeur »
# qui purge les caches et se désenregistre (voir le fichier source : il explique
# le mécanisme). C'est la seule façon de débloquer aussi les navigateurs déjà
# bloqués sur une ancienne version.
$killswitch = Join-Path $PSScriptRoot "service_worker_killswitch.js"
if (-not (Test-Path $killswitch)) { throw "Introuvable : $killswitch" }
Copy-Item $killswitch $sw -Force

if ((Get-Content $sw -Raw) -notmatch 'self\.registration\.unregister') {
    throw "Le service worker auto-destructeur n'a pas été copié correctement dans $sw."
}
Write-Host "   service worker auto-destructeur en place" -ForegroundColor DarkGray

Write-Host ">> Déploiement Firebase Hosting ($Project)" -ForegroundColor Cyan
firebase deploy --only hosting --project $Project
if ($LASTEXITCODE -ne 0) { throw "firebase deploy a échoué" }

Write-Host ">> Terminé : https://styleconnect.web.app" -ForegroundColor Green
