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

// Gestion des notifications programmées et badges
let scheduledNotifications = new Map();

// Fonction pour sauvegarder dans IndexedDB
async function saveToIndexedDB(data) {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open('DailyGrowthDB', 1);
    
    request.onerror = () => reject(request.error);
    request.onsuccess = () => {
      const db = request.result;
      const transaction = db.transaction(['notifications'], 'readwrite');
      const store = transaction.objectStore('notifications');
      store.put({ id: 'scheduled', data: data });
      transaction.oncomplete = () => resolve();
      transaction.onerror = () => reject(transaction.error);
    };
    
    request.onupgradeneeded = () => {
      const db = request.result;
      if (!db.objectStoreNames.contains('notifications')) {
        db.createObjectStore('notifications', { keyPath: 'id' });
      }
    };
  });
}

// Fonction pour lire depuis IndexedDB
async function loadFromIndexedDB() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open('DailyGrowthDB', 1);
    
    request.onerror = () => reject(request.error);
    request.onsuccess = () => {
      const db = request.result;
      const transaction = db.transaction(['notifications'], 'readonly');
      const store = transaction.objectStore('notifications');
      const getRequest = store.get('scheduled');
      
      getRequest.onsuccess = () => {
        resolve(getRequest.result?.data || null);
      };
      getRequest.onerror = () => reject(getRequest.error);
    };
    
    request.onupgradeneeded = () => {
      const db = request.result;
      if (!db.objectStoreNames.contains('notifications')) {
        db.createObjectStore('notifications', { keyPath: 'id' });
      }
    };
  });
}

self.addEventListener('message', async function(event) {
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
  
  // Programmer une notification quotidienne
  else if (data && data.type === 'SCHEDULE_NOTIFICATION') {
    const { userId, time, title, body } = data;
    console.log('[SW] Programming daily notification for', userId, 'at', time);
    
    // Stocker dans IndexedDB pour persistance
    const notificationData = {
      userId,
      time,
      title,
      body,
      lastSent: null
    };
    
    scheduledNotifications.set(userId, notificationData);
    
    // Sauvegarder dans IndexedDB
    try {
      const stored = Array.from(scheduledNotifications.entries());
      await saveToIndexedDB(stored);
      console.log('[SW] Notifications saved to IndexedDB');
    } catch (e) {
      console.log('[SW] Could not save to IndexedDB:', e);
    }
    
    // Démarrer le système de vérification périodique
    startPeriodicCheck();
  }
  
  // Supprimer une notification programmée
  else if (data && data.type === 'CANCEL_NOTIFICATION') {
    const { userId } = data;
    scheduledNotifications.delete(userId);
    console.log('[SW] Cancelled notification for', userId);
  }
});

// Système de vérification périodique (toutes les minutes)
let periodicCheckInterval = null;

function startPeriodicCheck() {
  if (periodicCheckInterval) return; // Déjà démarré
  
  console.log('[SW] Starting periodic notification check');
  
  periodicCheckInterval = setInterval(() => {
    checkAndSendNotifications();
  }, 60000); // Vérifier toutes les minutes
}

async function checkAndSendNotifications() {
  const now = new Date();
  const currentTime = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
  const today = now.toDateString();
  
  scheduledNotifications.forEach((notification, userId) => {
    const { time, title, body, lastSent } = notification;
    
    // Vérifier si c'est l'heure ET qu'on n'a pas déjà envoyé aujourd'hui
    if (currentTime === time.substring(0, 5) && lastSent !== today) {
      console.log('[SW] Sending scheduled notification for', userId, 'at', currentTime);
      
      // Envoyer la notification
      self.registration.showNotification(title, {
        body: body,
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
        tag: `daily-${userId}`,
        requireInteraction: false,
        data: {
          type: 'scheduled_daily',
          userId: userId,
          time: time
        }
      });
      
      // Marquer comme envoyé aujourd'hui
      notification.lastSent = today;
      scheduledNotifications.set(userId, notification);
      
      // Sauvegarder la mise à jour
      try {
        const stored = Array.from(scheduledNotifications.entries());
        await saveToIndexedDB(stored);
        console.log('[SW] Notifications updated in IndexedDB');
      } catch (e) {
        console.log('[SW] Could not update IndexedDB:', e);
      }
    }
  });
}

// Restaurer les notifications programmées au démarrage
async function restoreScheduledNotifications() {
  try {
    const stored = await loadFromIndexedDB();
    if (stored) {
      scheduledNotifications = new Map(stored);
      console.log('[SW] Restored', scheduledNotifications.size, 'scheduled notifications from IndexedDB');
      
      if (scheduledNotifications.size > 0) {
        startPeriodicCheck();
      }
    }
  } catch (e) {
    console.log('[SW] Could not restore scheduled notifications from IndexedDB:', e);
  }
}

// Restaurer au démarrage du service worker
restoreScheduledNotifications();

console.log('[SW] Service Worker principal chargé');