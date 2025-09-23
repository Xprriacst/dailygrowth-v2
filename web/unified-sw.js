// Service Worker unifié pour DailyGrowth PWA
// Combine les fonctionnalités de caching, notifications locales et Firebase Cloud Messaging

// Import Firebase scripts pour FCM
importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging-compat.js');

// Configuration Firebase
const firebaseConfig = {
  apiKey: "AIzaSyCdJSoFjbBqFxtxxrlRV2zc7ow_Um7dC5U",
  authDomain: "dailygrowth-pwa.firebaseapp.com",
  projectId: "dailygrowth-pwa",
  storageBucket: "dailygrowth-pwa.appspot.com",
  messagingSenderId: "443167745906",
  appId: "1:443167745906:web:c0e8f1c03571d440f3dfeb",
  measurementId: "G-BXJW80Y4EF"
};

// Initialiser Firebase et messaging
firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

// === SECTION CACHING PWA ===
const CACHE_NAME = 'dailygrowth-v3-' + Date.now();
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
  console.log('[SW] Installing unified service worker...');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(function(cache) {
        console.log('[SW] Caching files with cache name:', CACHE_NAME);
        return cache.addAll(urlsToCache);
      })
  );
  self.skipWaiting();
});

// Activation du service worker
self.addEventListener('activate', function(event) {
  console.log('[SW] Activating unified service worker and clearing old caches...');
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
  // Skip chrome-extension and other extension URLs
  if (event.request.url.startsWith('chrome-extension:') || 
      event.request.url.startsWith('moz-extension:') ||
      event.request.url.startsWith('safari-extension:')) {
    return;
  }

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

// === SECTION FIREBASE CLOUD MESSAGING ===

// Gérer les messages push en arrière-plan
messaging.onBackgroundMessage((payload) => {
  console.log('[SW] Message push reçu en arrière-plan: ', payload);

  const notificationTitle = payload.notification?.title || 'DailyGrowth';
  const notificationOptions = {
    body: payload.notification?.body || 'Nouveau défi disponible !',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: 'dailygrowth-notification',
    data: {
      url: payload.data?.url || '/',
      timestamp: Date.now(),
      type: payload.data?.type || 'general',
      ...payload.data
    },
    actions: [
      {
        action: 'open',
        title: 'Ouvrir'
      },
      {
        action: 'dismiss', 
        title: 'Ignorer'
      }
    ],
    requireInteraction: false,
    silent: false
  };

  // Mettre à jour le badge si fourni
  if (payload.data?.badge_count) {
    const count = parseInt(payload.data.badge_count);
    if ('setAppBadge' in self.navigator) {
      if (count > 0) {
        self.navigator.setAppBadge(count);
      } else {
        self.navigator.clearAppBadge();
      }
    }
  }

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// === SECTION GESTION DES CLICS ET MESSAGES ===

// Gérer les clics sur les notifications
self.addEventListener('notificationclick', (event) => {
  console.log('[SW] Notification cliquée: ', event.notification.tag);
  
  event.notification.close();

  if (event.action === 'dismiss') {
    return;
  }

  // Déterminer l'URL à ouvrir
  const urlToOpen = event.notification.data?.url || '/';
  const notificationType = event.notification.data?.type || 'general';

  // URLs spécifiques selon le type de notification
  let targetUrl = '/';
  switch (notificationType) {
    case 'challenge':
      targetUrl = '/#/challenges';
      break;
    case 'quote':
      targetUrl = '/#/quotes';
      break;
    case 'achievement':
      targetUrl = '/#/profile';
      break;
    case 'streak':
      targetUrl = '/#/profile';
      break;
    case 'reminder':
      targetUrl = '/#/challenges';
      break;
    case 'scheduled_daily':
      targetUrl = '/#/challenges';
      break;
    default:
      targetUrl = urlToOpen;
  }

  event.waitUntil(
    clients.matchAll({ 
      type: 'window',
      includeUncontrolled: true 
    }).then((clientList) => {
      // Rechercher si l'app est déjà ouverte
      for (let i = 0; i < clientList.length; i++) {
        const client = clientList[i];
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          client.focus();
          if (targetUrl !== '/') {
            client.navigate(targetUrl);
          }
          return;
        }
      }
      
      // Si l'app n'est pas ouverte, l'ouvrir
      if (clients.openWindow) {
        return clients.openWindow(self.location.origin + targetUrl);
      }
    })
  );
});

// Gérer les messages de l'application principale
self.addEventListener('message', function(event) {
  const data = event.data;
  
  if (data && data.type === 'SET_BADGE') {
    const count = data.count;
    
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
  
  // Effacer toutes les notifications
  else if (data && data.type === 'CLEAR_NOTIFICATIONS') {
    self.registration.getNotifications().then((notifications) => {
      notifications.forEach(notification => notification.close());
      console.log('[SW] Toutes les notifications effacées');
    });
  }
  
  // Stocker le token FCM
  else if (data && data.type === 'FCM_TOKEN') {
    const token = data.token;
    console.log('[SW] Token FCM reçu:', token);
  }
});

console.log('[SW] Service Worker unifié chargé et initialisé');