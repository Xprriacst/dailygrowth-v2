// Service Worker pour ChallengeMe PWA - Optimisé pour iOS Safari 16.4+
// IMPORTANT: iOS Safari est très strict sur le timing des notifications push
const CACHE_NAME = 'challengeme-v2';
const SW_VERSION = '__SW_VERSION__';

// Détecter iOS
const isIOS = () => {
  return /iPad|iPhone|iPod/.test(self.navigator?.userAgent || '');
};

console.log('🚀 ChallengeMe SW loading, version:', SW_VERSION, 'iOS:', isIOS());

// Installation du service worker
self.addEventListener('install', (event) => {
  console.log('🔧 ChallengeMe SW installé, version:', SW_VERSION);
  // Skip waiting pour activer immédiatement le nouveau SW
  self.skipWaiting();
  
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('📦 Cache ouvert');
        // Cache minimal pour PWA - éviter de bloquer l'installation
        return cache.addAll([
          '/',
          '/index.html',
          '/manifest.json'
        ]).catch(err => {
          console.warn('⚠️ Cache addAll failed (non-fatal):', err);
        });
      })
  );
});

// Activation du service worker
self.addEventListener('activate', (event) => {
  console.log('🔄 ChallengeMe SW activé, version:', SW_VERSION);
  // Prendre le contrôle immédiatement
  event.waitUntil(
    Promise.all([
      self.clients.claim(),
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
    ])
  );
});

// Gestion des push notifications - CRITIQUE POUR iOS
// iOS Safari révoque les permissions si on ne montre pas la notification IMMÉDIATEMENT
self.addEventListener('push', (event) => {
  console.log('📨 Push notification reçu sur', isIOS() ? 'iOS' : 'autre plateforme');
  
  // Préparer les données par défaut AVANT tout traitement
  let notificationData = {
    title: '🎯 ChallengeMe',
    body: 'Votre défi vous attend !',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: 'challengeme-push-' + Date.now(),
    renotify: true,
    requireInteraction: !isIOS(), // iOS gère différemment
    data: {
      url: '/',
      timestamp: Date.now()
    }
  };

  // Essayer de parser les données du push - avec gestion d'erreur robuste
  if (event.data) {
    try {
      const pushData = event.data.json();
      console.log('📋 Données push reçues:', pushData);
      
      // Fusionner avec les données par défaut
      if (pushData.title) notificationData.title = pushData.title;
      if (pushData.body) notificationData.body = pushData.body;
      if (pushData.icon) notificationData.icon = pushData.icon;
      if (pushData.url) notificationData.data.url = pushData.url;
      if (pushData.tag) notificationData.tag = pushData.tag;
      if (pushData.data) notificationData.data = { ...notificationData.data, ...pushData.data };
    } catch (e) {
      console.warn('⚠️ Erreur parsing push data (utilisation des valeurs par défaut):', e);
      // On continue avec les valeurs par défaut - NE PAS bloquer la notification
    }
  }

  // CRITIQUE: Afficher la notification IMMÉDIATEMENT dans waitUntil
  // Ne pas faire d'opérations asynchrones lourdes avant showNotification sur iOS
  event.waitUntil(
    self.registration.showNotification(notificationData.title, {
      body: notificationData.body,
      icon: notificationData.icon,
      badge: notificationData.badge,
      tag: notificationData.tag,
      renotify: notificationData.renotify,
      requireInteraction: notificationData.requireInteraction,
      data: notificationData.data
    }).then(() => {
      console.log('✅ Notification affichée avec succès');
    }).catch(err => {
      console.error('❌ Erreur affichage notification:', err);
    })
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

// Écouter les messages du client
self.addEventListener('message', (event) => {
  console.log('💬 Message reçu du client:', event.data);
  
  // Demande de skip waiting (mise à jour du SW)
  if (event.data && event.data.type === 'SKIP_WAITING') {
    console.log('🔄 Skip waiting demandé');
    self.skipWaiting();
  }
  
  // Affichage d'une notification depuis le client
  if (event.data && event.data.type === 'SHOW_NOTIFICATION') {
    const notificationData = {
      title: event.data.title || '🎯 ChallengeMe',
      body: event.data.body || 'Message de ChallengeMe',
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      tag: event.data.tag || 'challengeme-message',
      data: event.data.data || {},
      requireInteraction: !isIOS()
    };
    
    event.waitUntil(
      self.registration.showNotification(notificationData.title, notificationData)
    );
  }
  
  // Test de notification
  if (event.data && event.data.type === 'TEST_NOTIFICATION') {
    console.log('🧪 Test notification demandé');
    const notificationData = {
      title: '🧪 Test ChallengeMe',
      body: 'Les notifications push fonctionnent sur votre appareil !',
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      tag: 'test-' + Date.now(),
      data: { test: true, timestamp: Date.now() }
    };
    
    event.waitUntil(
      self.registration.showNotification(notificationData.title, notificationData)
        .then(() => {
          // Répondre au client
          if (event.source) {
            event.source.postMessage({ type: 'TEST_SUCCESS', timestamp: Date.now() });
          }
        })
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
