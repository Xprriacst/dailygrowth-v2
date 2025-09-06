// Service Worker pour PWA DailyGrowth
import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-app.js';
import { getMessaging, onBackgroundMessage } from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging-sw.js';

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

// Configuration Firebase
const firebaseConfig = {
  apiKey: "AIzaSyCdJSoFjbBqFtxxrIRV2zc7ow_Um7dC5U",
  authDomain: "dailygrowth-pwa.firebaseapp.com",
  projectId: "dailygrowth-pwa",
  storageBucket: "dailygrowth-pwa.appspot.com",
  messagingSenderId: "443167745906",
  appId: "1:443167745906:web:c0e8f1c03571d440f3dfeb",
  measurementId: "G-BXJW80Y4EF"
};

// Initialisation Firebase
const app = initializeApp(firebaseConfig);
const messaging = getMessaging(app);

// Installation du service worker
self.addEventListener('install', function(event) {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(function(cache) {
        return cache.addAll(urlsToCache);
      })
  );
});

// Activation du service worker
self.addEventListener('activate', function(event) {
  event.waitUntil(
    caches.keys().then(function(cacheNames) {
      return Promise.all(
        cacheNames.map(function(cacheName) {
          if (cacheName !== CACHE_NAME) {
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
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

// Gestion des notifications push en arrière-plan
onBackgroundMessage(messaging, (payload) => {
  console.log('[SW] Message push reçu en arrière-plan: ', payload);
  
  const notificationTitle = payload.notification?.title || 'DailyGrowth';
  const notificationOptions = {
    body: payload.notification?.body || 'Nouveau défi disponible !',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: 'dailygrowth-notification',
    data: {
      url: payload.data?.url || '/',
      timestamp: Date.now()
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
    ]
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Gestion des clics sur les notifications
self.addEventListener('notificationclick', function(event) {
  console.log('[SW] Notification cliquée: ', event.notification.tag);
  
  event.notification.close();

  if (event.action === 'dismiss') {
    return;
  }

  // Ouvrir l'app ou naviguer vers URL spécifique
  const urlToOpen = event.notification.data?.url || '/';
  
  event.waitUntil(
    clients.matchAll({ 
      type: 'window',
      includeUncontrolled: true 
    }).then(function(clientList) {
      // Rechercher si l'app est déjà ouverte
      for (let i = 0; i < clientList.length; i++) {
        const client = clientList[i];
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          client.focus();
          if (urlToOpen !== '/') {
            client.navigate(urlToOpen);
          }
          return;
        }
      }
      
      // Si l'app n'est pas ouverte, l'ouvrir
      if (clients.openWindow) {
        return clients.openWindow(self.location.origin + urlToOpen);
      }
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
      } else {
        navigator.clearAppBadge();
      }
    }
  }
});
