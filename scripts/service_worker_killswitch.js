// ─────────────────────────────────────────────────────────────────────────────
// Service worker « sans cache » — StyleConnect
//
// POURQUOI CE FICHIER EXISTE
//
// Flutter web génère par défaut un service worker qui met en cache index.html,
// main.dart.js et les assets. Conséquence : après un déploiement, un navigateur
// déjà venu peut servir l'ANCIENNE application pendant des heures. Pire, comme
// l'ancien index.html est lui-même mis en cache par ce service worker, le
// script de désenregistrement placé dans le NOUVEL index.html ne s'exécute
// jamais : le navigateur tourne en rond sur l'ancienne version.
//
// Le seul fichier que le navigateur revalide à chaque visite est le script du
// service worker lui-même. Celui-ci remplace donc le fichier généré par Flutter
// (voir scripts/deploy_web.ps1) et se contente de purger les caches, sans
// jamais intercepter de requête : l'application est toujours chargée depuis le
// réseau, donc toujours à jour.
//
// Il NE se désenregistre pas volontairement : le bootstrap de Flutter réenregistre
// un service worker à chaque chargement, et un désenregistrement suivi d'un
// rechargement provoquerait une boucle. Un service worker inactif (aucun
// gestionnaire `fetch`) est inoffensif.
// ─────────────────────────────────────────────────────────────────────────────

self.addEventListener('install', () => {
  // Pas de phase d'attente : on veut nettoyer tout de suite.
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      let deleted = 0;

      // 1. Purger tous les caches (anciennes versions de l'application).
      try {
        const cacheNames = await caches.keys();
        const results = await Promise.all(
          cacheNames.map((name) => caches.delete(name)),
        );
        deleted = results.filter(Boolean).length;
      } catch (_) {
        // API `caches` indisponible : rien à purger, on continue.
      }

      // 2. Prendre la main sur les onglets déjà ouverts.
      try {
        await self.clients.claim();
      } catch (_) {}

      // 3. Recharger uniquement si l'on vient réellement de purger quelque
      //    chose. Sans cette condition, un rechargement à chaque activation
      //    ferait boucler la page indéfiniment (le bootstrap réenregistre un
      //    service worker à chaque chargement).
      if (deleted === 0) return;

      try {
        const clients = await self.clients.matchAll({ type: 'window' });
        for (const client of clients) {
          if ('navigate' in client) {
            await client.navigate(client.url);
          }
        }
      } catch (_) {}
    })(),
  );
});

// Aucun gestionnaire `fetch` : les requêtes vont toujours au réseau. C'est ce
// qui garantit qu'aucune version périmée ne peut être servie.
