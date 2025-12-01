// Service Worker simplifié pour DailyGrowth - basé sur la version testée et fonctionnelle
const CACHE_NAME = 'dailygrowth-notifications-v1';

// Installation du service worker
self.addEventListener('install', (event) => {
  console.log('🔧 DailyGrowth SW installé');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('📦 Cache ouvert');
        return cache.addAll([
          '/',
          '/index.html',
          '/manifest.json',
          '/main.dart.js',
          '/flutter.js',
          '/sw.js'
        ]);
      })
  );
});

// Activation du service worker
self.addEventListener('activate', (event) => {
  console.log('🔄 DailyGrowth SW activé');
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

// Gestion des push notifications
self.addEventListener('push', (event) => {
  console.log('📨 Push notification reçu:', event);
  
  let notificationData = {
    title: '🔔 DailyGrowth',
    body: 'Vous avez une nouvelle notification !',
    icon: '/icon-192.png',
    badge: '/icon-192.png',
    tag: 'dailygrowth-push',
    data: {
      url: '/',
      timestamp: Date.now()
    },
    actions: [
      {
        action: 'open',
        title: 'Ouvrir',
        icon: '/icon-192.png'
      },
      {
        action: 'dismiss',
        title: 'Ignorer',
        icon: '/icon-192.png'
      }
    ]
  };

  // Essayer de parser les données du push
  if (event.data) {
    try {
      const pushData = event.data.json();
      console.log('📋 Données push reçues:', pushData);
      
      notificationData = {
        ...notificationData,
        ...pushData
      };
    } catch (e) {
      console.warn('⚠️ Erreur parsing push data:', e);
    }
  }

  event.waitUntil(
    self.registration.showNotification(notificationData.title, notificationData)
  );
});

// Gestion du clic sur notification
self.addEventListener('notificationclick', (event) => {
  console.log('📱 Notification cliquée:', event);
  
  event.notification.close();
  
  const action = event.action;
  const notificationData = event.notification.data || {};
  
  if (action === 'open' || !action) {
    // Ouvrir l'application
    const urlToOpen = notificationData.url || '/';
    
    event.waitUntil(
      clients.matchAll({ type: 'window', includeUncontrolled: true })
        .then(clientList => {
          // Chercher une fenêtre existante
          for (const client of clientList) {
            if (client.url === urlToOpen && 'focus' in client) {
              return client.focus();
            }
          }
          
          // Ouvrir une nouvelle fenêtre
          if (clients.openWindow) {
            return clients.openWindow(urlToOpen);
          }
        })
    );
  }
  
  console.log('✅ Action traitée:', action);
});

// Gestion de la fermeture de notification
self.addEventListener('notificationclose', (event) => {
  console.log('🔕 Notification fermée:', event.notification.data);
});

// Écouter les messages du client (pour les notifications programmées)
self.addEventListener('message', (event) => {
  console.log('💬 Message reçu du client:', event.data);
  
  if (event.data && event.data.type === 'SHOW_NOTIFICATION') {
    const notificationData = {
      title: event.data.title || '🔔 DailyGrowth',
      body: event.data.body || 'Message de DailyGrowth',
      icon: '/icon-192.png',
      badge: '/icon-192.png',
      tag: event.data.tag || 'dailygrowth-message',
      data: event.data.data || {},
      requireInteraction: event.data.requireInteraction || false
    };
    
    event.waitUntil(
      self.registration.showNotification(notificationData.title, notificationData)
    );
  }
  
  if (event.data && event.data.type === 'SCHEDULE_NOTIFICATION') {
    console.log('⏰ Notification programmée reçue:', event.data);
    // Ici on pourrait implémenter une logique de programmation simple
    // Pour l'instant on affiche juste un message de confirmation
    const notificationData = {
      title: '⏰ DailyGrowth',
      body: `Notification programmée pour ${event.data.time}`,
      icon: '/icon-192.png',
      tag: 'scheduled-confirmation',
      data: { scheduled: true, time: event.data.time }
    };
    
    event.waitUntil(
      self.registration.showNotification(notificationData.title, notificationData)
    );
  }
});

// Gestion des requêtes fetch (cache first)
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request)
      .then(response => {
        // Cache hit - return response
        if (response) {
          console.log('📦 Servi depuis cache:', event.request.url);
          return response;
        }

        // Clone la requête
        const fetchRequest = event.request.clone();

        return fetch(fetchRequest).then(response => {
          // Vérifier si la réponse est valide
          if (!response || response.status !== 200 || response.type !== 'basic') {
            console.log('🌐 Servi depuis réseau (non cachable):', event.request.url);
            return response;
          }

          // Clone la réponse
          const responseToCache = response.clone();

          // Ajouter au cache
          caches.open(CACHE_NAME)
            .then(cache => {
              console.log('💾 Ajouté au cache:', event.request.url);
              cache.put(event.request, responseToCache);
            });

          console.log('🌐 Servi depuis réseau:', event.request.url);
          return response;
        }).catch(error => {
          console.error('❌ Erreur fetch:', error);
          // En cas d'erreur, essayer de servir depuis cache même si expiré
          return caches.match(event.request);
        });
      })
  );
});

// Synchronisation en arrière-plan (optionnel)
self.addEventListener('sync', (event) => {
  console.log('🔄 Background sync:', event.tag);
  
  if (event.tag === 'daily-sync') {
    event.waitUntil(
      // Logique de synchronisation ici
      console.log('🔄 Synchronisation quotidienne effectuée')
    );
  }
});

console.log('🚀 DailyGrowth Service Worker chargé avec succès');
