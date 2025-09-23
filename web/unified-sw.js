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

// Gestion des notifications programmées et badges
let scheduledNotifications = new Map();
let periodicCheckInterval = null;

const INDEXED_DB_NAME = 'DailyGrowthDB';
const INDEXED_DB_STORE = 'notifications';

async function openIndexedDB() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(INDEXED_DB_NAME, 1);

    request.onerror = () => reject(request.error);
    request.onupgradeneeded = () => {
      const db = request.result;
      if (!db.objectStoreNames.contains(INDEXED_DB_STORE)) {
        db.createObjectStore(INDEXED_DB_STORE, { keyPath: 'id' });
      }
    };
    request.onsuccess = () => resolve(request.result);
  });
}

async function saveNotificationsToIndexedDB(data) {
  try {
    const db = await openIndexedDB();
    const transaction = db.transaction([INDEXED_DB_STORE], 'readwrite');
    const store = transaction.objectStore(INDEXED_DB_STORE);
    store.put({ id: 'scheduled', data });
    return new Promise((resolve, reject) => {
      transaction.oncomplete = () => resolve();
      transaction.onerror = () => reject(transaction.error);
    });
  } catch (error) {
    console.error('[SW] ❌ IndexedDB save error:', error);
  }
}

async function loadNotificationsFromIndexedDB() {
  try {
    const db = await openIndexedDB();
    const transaction = db.transaction([INDEXED_DB_STORE], 'readonly');
    const store = transaction.objectStore(INDEXED_DB_STORE);
    const request = store.get('scheduled');
    return new Promise((resolve, reject) => {
      request.onsuccess = () => resolve(request.result?.data || []);
      request.onerror = () => reject(request.error);
    });
  } catch (error) {
    console.error('[SW] ❌ IndexedDB load error:', error);
    return [];
  }
}

function startPeriodicCheck() {
  if (periodicCheckInterval) {
    return;
  }

  periodicCheckInterval = setInterval(() => {
    checkAndSendNotifications();
  }, 60000);
}

async function checkAndSendNotifications() {
  const now = new Date();
  const currentTime = `${now.getHours().toString().padStart(2, '0')}:${now
    .getMinutes()
    .toString()
    .padStart(2, '0')}`;
  const today = now.toDateString();

  scheduledNotifications.forEach((notification, userId) => {
    const { time, title, body, lastSent } = notification;
    const targetTime = time.substring(0, 5);

    if (currentTime === targetTime && lastSent !== today) {
      self.registration
        .showNotification(title, {
          body,
          icon: '/icons/Icon-192.png',
          badge: '/icons/Icon-192.png',
          tag: `daily-${userId}`,
          data: {
            type: 'scheduled_daily',
            userId,
            time,
          },
        })
        .catch((error) => {
          console.error('[SW] ❌ Failed to send scheduled notification:', error);
        });

      notification.lastSent = today;
      scheduledNotifications.set(userId, notification);
      saveNotificationsToIndexedDB(Array.from(scheduledNotifications.entries()));
    }
  });
}

async function restoreScheduledNotifications() {
  const stored = await loadNotificationsFromIndexedDB();
  scheduledNotifications = new Map(stored);

  if (scheduledNotifications.size > 0) {
    startPeriodicCheck();
  }
}

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

  if (!data || !data.type) {
    return;
  }

  switch (data.type) {
    case 'SET_BADGE': {
      const count = data.count || 0;
      if ('setAppBadge' in navigator) {
        if (count > 0) {
          navigator.setAppBadge(count);
        } else {
          navigator.clearAppBadge();
        }
      }
      break;
    }
    case 'CLEAR_NOTIFICATIONS': {
      self.registration.getNotifications().then((notifications) => {
        notifications.forEach((notification) => notification.close());
      });
      break;
    }
    case 'SCHEDULE_NOTIFICATION': {
      const { userId, time, title, body } = data;
      if (!userId || !time) {
        return;
      }
      scheduledNotifications.set(userId, {
        time,
        title,
        body,
        lastSent: null,
        createdAt: new Date().toISOString(),
      });
      saveNotificationsToIndexedDB(Array.from(scheduledNotifications.entries()));
      startPeriodicCheck();
      break;
    }
    case 'CANCEL_NOTIFICATION': {
      const { userId } = data;
      if (userId && scheduledNotifications.has(userId)) {
        scheduledNotifications.delete(userId);
        saveNotificationsToIndexedDB(Array.from(scheduledNotifications.entries()));
      }
      break;
    }
    case 'FCM_TOKEN': {
      const token = data.token;
      console.log('[SW] Token FCM reçu:', token);
      break;
    }
    default:
      break;
  }
});

restoreScheduledNotifications();

console.log('[SW] Service Worker unifié chargé et initialisé');
