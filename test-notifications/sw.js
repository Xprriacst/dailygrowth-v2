// Service Worker simplifié pour test notifications
const CACHE_NAME = 'test-notifications-v1';

self.addEventListener('install', (event) => {
  console.log('🔧 SW installé');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(['/index.html', '/manifest.json']))
  );
});

self.addEventListener('activate', (event) => {
  console.log('🔄 SW activé');
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheName !== CACHE_NAME) {
            console.log('🗑️ Suppression ancien cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
});

self.addEventListener('push', (event) => {
  console.log('📨 Push reçu:', event);
  
  const options = {
    body: 'Notification push reçue avec succès!',
    icon: '/icon-192.png',
    badge: '/icon-192.png',
    vibrate: [200, 100, 200],
    data: {
      dateOfArrival: Date.now(),
      primaryKey: 1
    },
    actions: [
      {
        action: 'explore',
        title: 'Voir',
        icon: '/icon-192.png'
      },
      {
        action: 'close',
        title: 'Fermer',
        icon: '/icon-192.png'
      }
    ]
  };

  event.waitUntil(
    self.registration.showNotification('🔔 Test Push', options)
  );
});

self.addEventListener('notificationclick', (event) => {
  console.log('📱 Notification cliquée:', event.notification.data);
  
  event.notification.close();
  
  if (event.action === 'explore') {
    event.waitUntil(
      clients.openWindow('/')
    );
  }
});

// Écouter les messages du client
self.addEventListener('message', (event) => {
  console.log('💬 Message reçu du client:', event.data);
  
  if (event.data && event.data.type === 'SHOW_NOTIFICATION') {
    const options = {
      body: event.data.body || 'Message du service worker',
      icon: '/icon-192.png',
      badge: '/icon-192.png',
      tag: 'test-sw-notification'
    };
    
    event.waitUntil(
      self.registration.showNotification(event.data.title || '🔔 Message SW', options)
    );
  }
});

// Fetch simple
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request)
      .then(response => {
        return response || fetch(event.request);
      })
  );
});
