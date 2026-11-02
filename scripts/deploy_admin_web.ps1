# Déploiement de la CONSOLE ADMIN — usage : .\scripts\deploy_admin_web.ps1
#
# Prérequis unique (une seule fois par projet) : créer le site Hosting dédié.
#   firebase hosting:sites:create styleconnect-admin --project styleconnect-25e1c
#
# Ensuite ce script construit l'entrypoint admin (lib/main_admin.dart) dans un
# dossier séparé (build/admin_web) et déploie uniquement la cible Hosting
# "admin" — jamais le site client, jamais l'inverse.
#
# Le service worker « sans cache » est répliqué ici pour la même raison que
# côté client : après un déploiement, un navigateur déjà venu ne doit pas
# servir une ancienne version de la console pendant des heures.

param(
    [string]$Project = "styleconnect-25e1c"
)

$ErrorActionPreference = "Stop"

Write-Host ">> Build web admin (release, sans PWA)" -ForegroundColor Cyan
flutter build web -t lib/main_admin.dart --release --pwa-strategy=none -o build/admin_web
if ($LASTEXITCODE -ne 0) { throw "flutter build web (admin) a échoué" }

$sw = "build/admin_web/flutter_service_worker.js"

$killswitch = Join-Path $PSScriptRoot "service_worker_killswitch.js"
if (-not (Test-Path $killswitch)) { throw "Introuvable : $killswitch" }

# Le fichier doit exister dans la sortie du build avant remplacement.
if (-not (Test-Path (Split-Path $sw))) {
    throw "Dossier de build introuvable : $(Split-Path $sw). Le build Flutter a-t-il abouti ?"
}

Copy-Item $killswitch $sw -Force

# Vérifie le marqueur RÉEL du killswitch actuel : il purge les caches et
# n'intercepte aucune requête. Il ne se désenregistre pas volontairement
# (voir scripts/service_worker_killswitch.js) — chercher
# `self.registration.unregister` faisait échouer le script alors que la copie
# était correcte.
$swContent = Get-Content $sw -Raw
if ($swContent -notmatch 'caches\.keys' -or $swContent -notmatch 'self\.skipWaiting') {
    throw "Le service worker sans cache n'a pas été copié correctement dans $sw."
}
Write-Host "   service worker sans cache en place" -ForegroundColor DarkGray

Write-Host ">> Déploiement Firebase Hosting — cible admin ($Project)" -ForegroundColor Cyan
firebase deploy --only hosting:admin --project $Project
if ($LASTEXITCODE -ne 0) { throw "firebase deploy (admin) a échoué" }

Write-Host ">> Terminé : https://styleconnect-admin.web.app" -ForegroundColor Green
