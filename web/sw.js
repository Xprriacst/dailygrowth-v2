// Service Worker pour PWA DailyGrowth
const CACHE_NAME = 'dailygrowth-v1';
const urlsToCache = [
  '/',
  '/main.dart.js',
  '/flutter.js',
  '/manifest.json',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
  '/favicon.png'
];

// Installation du service worker
self.addEventListener('install', function(event) {
  console.log('[SW] Installing...');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(function(cache) {
        console.log('[SW] Caching files');
        return cache.addAll(urlsToCache);
      })
  );
  self.skipWaiting();
});

// Activation du service worker
self.addEventListener('activate', function(event) {
  console.log('[SW] Activating...');
  event.waitUntil(
    caches.keys().then(function(cacheNames) {
      return Promise.all(
        cacheNames.map(function(cacheName) {
          if (cacheName !== CACHE_NAME) {
            console.log('[SW] Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
  self.clients.claim();
});

// Stratégie de cache : Network First avec fallback sur cache
self.addEventListener('fetch', function(event) {
  event.respondWith(
    fetch(event.request)
      .then(function(response) {
        // Si la requête réussit, mettre en cache et retourner
        if (response.status === 200) {
          const responseClone = response.clone();
          caches.open(CACHE_NAME)
            .then(function(cache) {
              cache.put(event.request, responseClone);
            });
        }
        return response;
      })
      .catch(function() {
        // En cas d'échec, utiliser le cache
        return caches.match(event.request);
      })
  );
});

// Badge API pour iOS Safari 16.4+
self.addEventListener('message', function(event) {
  if (event.data && event.data.type === 'SET_BADGE') {
    const count = event.data.count;
    
    // Utiliser Badge API si disponible (iOS Safari 16.4+)
    if ('setAppBadge' in navigator) {
      if (count > 0) {
        navigator.setAppBadge(count);
        console.log('[SW] Badge mis à jour:', count);
      } else {
        navigator.clearAppBadge();
        console.log('[SW] Badge effacé');
      }
    }
  }
});

console.log('[SW] Service Worker principal chargé');