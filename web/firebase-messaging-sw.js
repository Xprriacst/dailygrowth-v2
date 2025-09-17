// Firebase Cloud Messaging Service Worker pour DailyGrowth PWA
importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging-compat.js');

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

// Initialiser Firebase
firebase.initializeApp(firebaseConfig);

// Initialiser Firebase Cloud Messaging
const messaging = firebase.messaging();

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
self.addEventListener('message', (event) => {
  console.log('[SW] Message reçu: ', event.data);
  
  if (event.data && event.data.type) {
    switch (event.data.type) {
      case 'SET_BADGE':
        const count = event.data.count || 0;
        if ('setAppBadge' in self.navigator) {
          if (count > 0) {
            self.navigator.setAppBadge(count);
            console.log('[SW] Badge mis à jour:', count);
          } else {
            self.navigator.clearAppBadge();
            console.log('[SW] Badge effacé');
          }
        }
        break;
        
      case 'CLEAR_NOTIFICATIONS':
        self.registration.getNotifications().then((notifications) => {
          notifications.forEach(notification => notification.close());
          console.log('[SW] Toutes les notifications effacées');
        });
        break;
        
      case 'FCM_TOKEN':
        // Stocker le token FCM si nécessaire
        const token = event.data.token;
        console.log('[SW] Token FCM reçu:', token);
        break;
        
      default:
        console.log('[SW] Type de message non géré:', event.data.type);
    }
  }
});

// Gérer l'installation du service worker
self.addEventListener('install', (event) => {
  console.log('[SW] Service Worker installing');
  self.skipWaiting();
});

// Gérer l'activation du service worker
self.addEventListener('activate', (event) => {
  console.log('[SW] Service Worker activating');
  event.waitUntil(self.clients.claim());
});

console.log('[SW] Firebase Messaging Service Worker chargé');