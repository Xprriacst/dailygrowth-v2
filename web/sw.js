// Service Worker pour PWA DailyGrowth - Safari Optimized
const CACHE_NAME = 'dailygrowth-safari-v3-' + Date.now();
const urlsToCache = [
  '/',
  '/main.dart.js',
  '/flutter.js',
  '/manifest.json',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
  '/favicon.png',
  // Cache des images PWA tutorial pour Safari
  '/assets/images/pwa_tutorial/etape_1_installer.png',
  '/assets/images/pwa_tutorial/etape_2_partager.png',
  '/assets/images/pwa_tutorial/etape_3_ajouter.png',
  '/assets/images/no-image.jpg'
];

// Installation du service worker
self.addEventListener('install', function(event) {
  console.log('[SW] Installing new version...');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(function(cache) {
        console.log('[SW] Caching files with new cache name:', CACHE_NAME);
        return cache.addAll(urlsToCache);
      })
  );
  // Force immediate activation
  self.skipWaiting();
});

// Activation du service worker
self.addEventListener('activate', function(event) {
  console.log('[SW] Activating new version and clearing old caches...');
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
  // Force immediate control of all clients
  self.clients.claim();
});

// Stratégie de cache : Network First avec fallback sur cache et support Safari
self.addEventListener('fetch', function(event) {
  // Skip chrome-extension and other extension URLs
  if (event.request.url.startsWith('chrome-extension:') ||
      event.request.url.startsWith('moz-extension:') ||
      event.request.url.startsWith('safari-extension:')) {
    return;
  }

  // Gestion spécifique des images locales pour Safari
  if (event.request.url.includes('/assets/images/')) {
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
          console.log('[SW] Asset not found, trying cache:', event.request.url);
          // En cas d'échec, utiliser le cache
          return caches.match(event.request).then(function(cachedResponse) {
            if (cachedResponse) {
              console.log('[SW] Serving from cache:', event.request.url);
              return cachedResponse;
            }
            // Fallback sur no-image.jpg pour Safari
            return caches.match('/assets/images/no-image.jpg');
          });
        })
    );
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

// Fonction pour sauvegarder dans IndexedDB
async function saveToIndexedDB(data) {
  console.log('[SW] 💾 saveToIndexedDB called with', data?.length || 0, 'items');
  
  return new Promise((resolve, reject) => {
    const request = indexedDB.open('DailyGrowthDB', 1);
    
    request.onerror = () => {
      console.error('[SW] ❌ IndexedDB open error:', request.error);
      reject(request.error);
    };
    
    request.onsuccess = () => {
      console.log('[SW] ✅ IndexedDB opened successfully for save');
      const db = request.result;
      const transaction = db.transaction(['notifications'], 'readwrite');
      const store = transaction.objectStore('notifications');
      
      console.log('[SW] 💾 Putting data in IndexedDB...');
      store.put({ id: 'scheduled', data: data });
      
      transaction.oncomplete = () => {
        console.log('[SW] ✅ IndexedDB save transaction completed');
        resolve();
      };
      transaction.onerror = () => {
        console.error('[SW] ❌ IndexedDB save transaction error:', transaction.error);
        reject(transaction.error);
      };
    };
    
    request.onupgradeneeded = () => {
      console.log('[SW] 🔧 IndexedDB upgrade needed, creating notifications store');
      const db = request.result;
      if (!db.objectStoreNames.contains('notifications')) {
        db.createObjectStore('notifications', { keyPath: 'id' });
        console.log('[SW] ✅ Notifications store created');
      }
    };
  });
}

// Fonction pour lire depuis IndexedDB
async function loadFromIndexedDB() {
  console.log('[SW] 📥 loadFromIndexedDB called');
  
  return new Promise((resolve, reject) => {
    const request = indexedDB.open('DailyGrowthDB', 1);
    
    request.onerror = () => {
      console.error('[SW] ❌ IndexedDB open error for load:', request.error);
      reject(request.error);
    };
    
    request.onsuccess = () => {
      console.log('[SW] ✅ IndexedDB opened successfully for load');
      const db = request.result;
      const transaction = db.transaction(['notifications'], 'readonly');
      const store = transaction.objectStore('notifications');
      const getRequest = store.get('scheduled');
      
      getRequest.onsuccess = () => {
        const result = getRequest.result?.data || null;
        console.log('[SW] 📥 IndexedDB load result:', result?.length || 0, 'items');
        resolve(result);
      };
      getRequest.onerror = () => {
        console.error('[SW] ❌ IndexedDB get request error:', getRequest.error);
        reject(getRequest.error);
      };
    };
    
    request.onupgradeneeded = () => {
      console.log('[SW] 🔧 IndexedDB upgrade needed during load, creating notifications store');
      const db = request.result;
      if (!db.objectStoreNames.contains('notifications')) {
        db.createObjectStore('notifications', { keyPath: 'id' });
        console.log('[SW] ✅ Notifications store created during load');
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
    console.log('[SW] 🔔 SCHEDULE_NOTIFICATION received:', {
      userId,
      time,
      title: title?.substring(0, 50) + '...',
      body: body?.substring(0, 50) + '...',
      timestamp: new Date().toISOString()
    });
    
    // Stocker dans IndexedDB pour persistance
    const notificationData = {
      userId,
      time,
      title,
      body,
      lastSent: null,
      createdAt: new Date().toISOString()
    };
    
    scheduledNotifications.set(userId, notificationData);
    console.log('[SW] 📝 Notification added to memory map. Total:', scheduledNotifications.size);
    
    // Sauvegarder dans IndexedDB
    try {
      const stored = Array.from(scheduledNotifications.entries());
      console.log('[SW] 💾 Attempting to save to IndexedDB:', stored.length, 'notifications');
      await saveToIndexedDB(stored);
      console.log('[SW] ✅ Notifications successfully saved to IndexedDB');
    } catch (e) {
      console.error('[SW] ❌ Could not save to IndexedDB:', e);
    }
    
    // Démarrer le système de vérification périodique
    console.log('[SW] 🕐 Starting periodic check system...');
    startPeriodicCheck();
    console.log('[SW] ✅ SCHEDULE_NOTIFICATION processing complete');
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
  if (periodicCheckInterval) {
    console.log('[SW] ⏰ Periodic check already running, skipping start');
    return;
  }
  
  console.log('[SW] 🚀 Starting periodic notification check (every 60s)');
  
  periodicCheckInterval = setInterval(() => {
    console.log('[SW] 🔍 Running periodic check at', new Date().toLocaleTimeString());
    checkAndSendNotifications();
  }, 60000); // Vérifier toutes les minutes
  
  console.log('[SW] ✅ Periodic check interval created successfully');
}

async function checkAndSendNotifications() {
  const now = new Date();
  const currentTime = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
  const today = now.toDateString();
  
  console.log('[SW] 🔍 Checking notifications at', currentTime, 'on', today);
  console.log('[SW] 📋 Total scheduled notifications:', scheduledNotifications.size);
  
  if (scheduledNotifications.size === 0) {
    console.log('[SW] ⚠️ No scheduled notifications found');
    return;
  }
  
  scheduledNotifications.forEach((notification, userId) => {
    const { time, title, body, lastSent, createdAt } = notification;
    const targetTime = time.substring(0, 5);
    
    console.log('[SW] 🔍 Checking notification for user', userId, ':', {
      targetTime,
      currentTime,
      timeMatch: currentTime === targetTime,
      lastSent,
      today,
      alreadySentToday: lastSent === today,
      createdAt
    });
    
    // Vérifier si c'est l'heure ET qu'on n'a pas déjà envoyé aujourd'hui
    if (currentTime === targetTime && lastSent !== today) {
      console.log('[SW] 🚀 SENDING scheduled notification for', userId, 'at', currentTime);
      
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
      }).then(() => {
        console.log('[SW] ✅ Notification sent successfully for', userId);
      }).catch((error) => {
        console.error('[SW] ❌ Failed to send notification for', userId, ':', error);
      });
      
      // Marquer comme envoyé aujourd'hui
      notification.lastSent = today;
      scheduledNotifications.set(userId, notification);
      console.log('[SW] 📝 Marked notification as sent for', userId, 'on', today);
      
      // Sauvegarder la mise à jour
      (async () => {
        try {
          const stored = Array.from(scheduledNotifications.entries());
          await saveToIndexedDB(stored);
          console.log('[SW] ✅ Notifications updated in IndexedDB');
        } catch (e) {
          console.error('[SW] ❌ Could not update IndexedDB:', e);
        }
      })();
    } else if (currentTime === targetTime && lastSent === today) {
      console.log('[SW] ⏭️ Skipping notification for', userId, '- already sent today');
    }
  });
  
  console.log('[SW] 🏁 Notification check complete');
}

// Restaurer les notifications programmées au démarrage
async function restoreScheduledNotifications() {
  console.log('[SW] 🔄 Starting restoration of scheduled notifications...');
  
  try {
    console.log('[SW] 📥 Loading notifications from IndexedDB...');
    const stored = await loadFromIndexedDB();
    
    if (stored) {
      scheduledNotifications = new Map(stored);
      console.log('[SW] ✅ Restored', scheduledNotifications.size, 'scheduled notifications from IndexedDB');
      
      // Afficher le détail des notifications restaurées
      scheduledNotifications.forEach((notification, userId) => {
        console.log('[SW] 📋 Restored notification:', {
          userId,
          time: notification.time,
          lastSent: notification.lastSent,
          createdAt: notification.createdAt
        });
      });
      
      if (scheduledNotifications.size > 0) {
        console.log('[SW] 🚀 Starting periodic check because we have notifications');
        startPeriodicCheck();
      } else {
        console.log('[SW] ⚠️ No notifications to schedule');
      }
    } else {
      console.log('[SW] 📭 No stored notifications found in IndexedDB');
    }
  } catch (e) {
    console.error('[SW] ❌ Could not restore scheduled notifications from IndexedDB:', e);
  }
  
  console.log('[SW] 🏁 Notification restoration complete');
}

// Restaurer au démarrage du service worker
restoreScheduledNotifications();

console.log('[SW] Service Worker principal chargé');