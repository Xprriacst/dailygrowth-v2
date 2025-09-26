// Service Worker unifié DailyGrowth - Firebase Push + Cache + Fallback Local
importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging-compat.js');

// Configuration
const CACHE_VERSION = 'v4.0.0';
const CACHE_NAME = 'dailygrowth-unified-' + CACHE_VERSION;

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

// URLs à mettre en cache
const urlsToCache = [
  '/',
  '/main.dart.js',
  '/flutter.js',
  '/manifest.json',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
  '/favicon.png',
  '/assets/images/pwa_tutorial/etape_1_installer.png',
  '/assets/images/pwa_tutorial/etape_2_partager.png',
  '/assets/images/pwa_tutorial/etape_3_ajouter.png',
  '/assets/images/no-image.jpg'
];

// Variables globales
let scheduledNotifications = new Map();
let periodicCheckInterval = null;
let messaging = null;
let firebaseInitialized = false;

// =============================================================================
// FIREBASE INITIALIZATION
// =============================================================================
try {
  firebase.initializeApp(firebaseConfig);
  messaging = firebase.messaging();
  firebaseInitialized = true;
  console.log('[SW] ✅ Firebase initialized successfully');
} catch (error) {
  console.error('[SW] ❌ Firebase initialization failed:', error);
  firebaseInitialized = false;
}

// =============================================================================
// FIREBASE PUSH NOTIFICATIONS
// =============================================================================
if (firebaseInitialized && messaging) {
  messaging.onBackgroundMessage((payload) => {
    console.log('[SW] 🔔 Firebase push message received:', payload);

    const notificationTitle = payload.notification?.title || 'DailyGrowth';
    const notificationOptions = {
      body: payload.notification?.body || 'Nouveau défi disponible !',
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      tag: 'dailygrowth-push',
      data: {
        url: payload.data?.url || '/',
        timestamp: Date.now(),
        type: payload.data?.type || 'push',
        source: 'firebase',
        ...payload.data
      },
      actions: [
        { action: 'open', title: 'Ouvrir' },
        { action: 'dismiss', title: 'Ignorer' }
      ],
      requireInteraction: false,
      silent: false,
      renotify: true
    };

    // Update badge from push data
    if (payload.data?.badge_count) {
      const count = parseInt(payload.data.badge_count);
      updateAppBadge(count);
    }

    return self.registration.showNotification(notificationTitle, notificationOptions);
  });
}

// =============================================================================
// CACHE MANAGEMENT
// =============================================================================
self.addEventListener('install', function(event) {
  console.log('[SW] Installing unified version...');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(function(cache) {
        console.log('[SW] Caching files with cache name:', CACHE_NAME);
        return cache.addAll(urlsToCache);
      })
  );
  self.skipWaiting();
});

self.addEventListener('activate', function(event) {
  console.log('[SW] Activating unified version and clearing old caches...');
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

self.addEventListener('fetch', function(event) {
  // Skip extensions and non-GET requests
  if (event.request.url.startsWith('chrome-extension:') ||
      event.request.url.startsWith('moz-extension:') ||
      event.request.url.startsWith('safari-extension:') ||
      event.request.method !== 'GET') {
    return;
  }

  // Handle images with fallback
  if (event.request.url.includes('/assets/images/')) {
    event.respondWith(
      fetch(event.request)
        .then(function(response) {
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
          return caches.match(event.request).then(function(cachedResponse) {
            return cachedResponse || caches.match('/assets/images/no-image.jpg');
          });
        })
    );
    return;
  }

  // Network first strategy for other resources
  event.respondWith(
    fetch(event.request)
      .then(function(response) {
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
        return caches.match(event.request);
      })
  );
});

// =============================================================================
// INDEXEDDB OPERATIONS
// =============================================================================
async function saveToIndexedDB(data) {
  console.log('[SW] 💾 Saving to IndexedDB:', data?.length || 0, 'items');
  
  return new Promise((resolve, reject) => {
    const request = indexedDB.open('DailyGrowthDB', 1);
    
    request.onerror = () => {
      console.error('[SW] ❌ IndexedDB open error:', request.error);
      reject(request.error);
    };
    
    request.onsuccess = () => {
      const db = request.result;
      const transaction = db.transaction(['notifications'], 'readwrite');
      const store = transaction.objectStore('notifications');
      
      store.put({ id: 'scheduled', data: data });
      
      transaction.oncomplete = () => {
        console.log('[SW] ✅ IndexedDB save completed');
        resolve();
      };
      transaction.onerror = () => {
        console.error('[SW] ❌ IndexedDB save error:', transaction.error);
        reject(transaction.error);
      };
    };
    
    request.onupgradeneeded = () => {
      console.log('[SW] 🔧 Creating IndexedDB notifications store');
      const db = request.result;
      if (!db.objectStoreNames.contains('notifications')) {
        db.createObjectStore('notifications', { keyPath: 'id' });
      }
    };
  });
}

async function loadFromIndexedDB() {
  console.log('[SW] 📥 Loading from IndexedDB');
  
  return new Promise((resolve, reject) => {
    const request = indexedDB.open('DailyGrowthDB', 1);
    
    request.onerror = () => reject(request.error);
    
    request.onsuccess = () => {
      const db = request.result;
      const transaction = db.transaction(['notifications'], 'readonly');
      const store = transaction.objectStore('notifications');
      const getRequest = store.get('scheduled');
      
      getRequest.onsuccess = () => {
        const result = getRequest.result?.data || null;
        console.log('[SW] 📥 Loaded from IndexedDB:', result?.length || 0, 'items');
        resolve(result);
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

// =============================================================================
// BADGE MANAGEMENT
// =============================================================================
function updateAppBadge(count) {
  if ('setAppBadge' in navigator) {
    if (count > 0) {
      navigator.setAppBadge(count);
      console.log('[SW] 🔖 Badge updated:', count);
    } else {
      navigator.clearAppBadge();
      console.log('[SW] 🔖 Badge cleared');
    }
  } else {
    console.log('[SW] ⚠️ Badge API not supported');
  }
}

// =============================================================================
// MESSAGE HANDLING
// =============================================================================
self.addEventListener('message', async function(event) {
  let data = event.data;
  
  // Handle Dart-to-JS encapsulation (data might be wrapped in {o: actualData})
  if (data && data.o && typeof data.o === 'object') {
    data = data.o;
  }
  
  console.log('[SW] 📨 Message received:', data?.type || 'unknown', data);
  
  switch (data?.type) {
    case 'SET_BADGE':
      updateAppBadge(data.count || 0);
      break;
      
    case 'CLEAR_NOTIFICATIONS':
      try {
        const notifications = await self.registration.getNotifications();
        notifications.forEach(notification => notification.close());
        console.log('[SW] 🧹 All notifications cleared');
      } catch (e) {
        console.error('[SW] ❌ Error clearing notifications:', e);
      }
      break;
      
    case 'FCM_TOKEN':
      console.log('[SW] 🔑 FCM Token received:', data.token?.substring(0, 20) + '...');
      break;
      
    case 'SCHEDULE_NOTIFICATION':
      await handleScheduleNotification(data);
      break;
      
    case 'CANCEL_NOTIFICATION':
      handleCancelNotification(data);
      break;
      
    default:
      console.log('[SW] ⚠️ Unhandled message type:', data?.type);
  }
});

// =============================================================================
// LOCAL NOTIFICATION FALLBACK (for when push fails)
// =============================================================================
async function handleScheduleNotification(data) {
  const { userId, time, title, body } = data;
  console.log('[SW] 📅 Scheduling fallback notification:', {
    userId, time, title: title?.substring(0, 30) + '...'
  });
  
  const notificationData = {
    userId, time, title, body,
    lastSent: null,
    createdAt: new Date().toISOString(),
    source: 'local_fallback'
  };
  
  scheduledNotifications.set(userId, notificationData);
  console.log('[SW] 📝 Fallback notification scheduled. Total:', scheduledNotifications.size);
  
  // Save to IndexedDB
  try {
    const stored = Array.from(scheduledNotifications.entries());
    await saveToIndexedDB(stored);
    console.log('[SW] ✅ Fallback notifications saved to IndexedDB');
  } catch (e) {
    console.error('[SW] ❌ Error saving fallback notifications:', e);
  }
  
  // Start periodic check for fallback even if Firebase is available.
  // Firebase push will still take priority, but this guarantees a local reminder
  // if no remote push is sent at the scheduled time.
  if (!firebaseInitialized) {
    console.log('[SW] 🔄 Firebase not available, starting local fallback system');
  } else {
    console.log('[SW] ✅ Firebase available, push notifications preferred over local fallback');
  }

  startPeriodicCheck();
}

function handleCancelNotification(data) {
  const { userId } = data;
  scheduledNotifications.delete(userId);
  console.log('[SW] ❌ Cancelled fallback notification for:', userId);
}

// =============================================================================
// PERIODIC CHECK (FALLBACK ONLY)
// =============================================================================
function startPeriodicCheck() {
  if (periodicCheckInterval) {
    console.log('[SW] ⏰ Periodic check already running');
    return;
  }
  
  console.log('[SW] 🚀 Starting periodic fallback check (every 60s)');
  
  periodicCheckInterval = setInterval(() => {
    console.log('[SW] 🔍 Running fallback check at', new Date().toLocaleTimeString());
    checkAndSendFallbackNotifications();
  }, 60000); // Every minute for fallback
}

async function checkAndSendFallbackNotifications() {
  const now = new Date();
  const currentTime = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
  const today = now.toDateString();
  
  console.log('[SW] 🔍 Checking fallback notifications at', currentTime);
  console.log('[SW] 📋 Total fallback notifications:', scheduledNotifications.size);
  
  if (scheduledNotifications.size === 0) return;
  
  scheduledNotifications.forEach((notification, userId) => {
    const { time, title, body, lastSent } = notification;
    const targetTime = time.substring(0, 5);
    
    console.log('[SW] 🔍 Checking fallback for user', userId, ':', {
      targetTime, currentTime,
      timeMatch: currentTime === targetTime,
      alreadySentToday: lastSent === today
    });
    
    const shouldSend = currentTime === targetTime && lastSent !== today;
    
    if (shouldSend) {
      console.log('[SW] 🚀 Sending FALLBACK notification for', userId);
      
      if ('Notification' in self && Notification.permission === 'granted') {
        self.registration.showNotification(title, {
          body: body,
          icon: '/icons/Icon-192.png',
          badge: '/icons/Icon-192.png',
          tag: `daily-fallback-${userId}`,
          data: {
            type: 'scheduled_fallback',
            userId: userId,
            time: time,
            source: 'local'
          },
          requireInteraction: false,
          renotify: true,
          silent: false
        }).then(() => {
          console.log('[SW] ✅ Fallback notification sent for', userId);
        }).catch(error => {
          console.error('[SW] ❌ Fallback notification failed for', userId, ':', error);
        });
        
        // Mark as sent
        notification.lastSent = today;
        scheduledNotifications.set(userId, notification);
        
        // Save update
        (async () => {
          try {
            const stored = Array.from(scheduledNotifications.entries());
            await saveToIndexedDB(stored);
          } catch (e) {
            console.error('[SW] ❌ Error updating fallback in IndexedDB:', e);
          }
        })();
      } else {
        console.error('[SW] ❌ Notification permission not granted for fallback');
      }
    }
  });
}

// =============================================================================
// NOTIFICATION CLICK HANDLING
// =============================================================================
self.addEventListener('notificationclick', (event) => {
  console.log('[SW] 🔔 Notification clicked:', event.notification.tag, event.notification.data);
  
  event.notification.close();

  if (event.action === 'dismiss') {
    return;
  }

  // Determine URL based on notification data
  let targetUrl = '/';
  const notificationData = event.notification.data || {};
  const notificationType = notificationData.type || 'general';

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
    case 'scheduled_daily':
    case 'scheduled_fallback':
      targetUrl = '/#/challenges';
      break;
    default:
      targetUrl = notificationData.url || '/';
  }

  event.waitUntil(
    clients.matchAll({ 
      type: 'window',
      includeUncontrolled: true 
    }).then((clientList) => {
      // Look for existing app window
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          client.focus();
          if (targetUrl !== '/') {
            client.navigate(targetUrl);
          }
          return;
        }
      }
      
      // Open new window if none found
      if (clients.openWindow) {
        return clients.openWindow(self.location.origin + targetUrl);
      }
    })
  );
});

// =============================================================================
// STARTUP - RESTORE FALLBACK NOTIFICATIONS
// =============================================================================
async function restoreScheduledNotifications() {
  console.log('[SW] 🔄 Restoring fallback notifications...');
  
  try {
    const stored = await loadFromIndexedDB();
    
    if (stored) {
      scheduledNotifications = new Map(stored);
      console.log('[SW] ✅ Restored', scheduledNotifications.size, 'fallback notifications');
      
      // Only start periodic check if Firebase is not available
      if (!firebaseInitialized && scheduledNotifications.size > 0) {
        console.log('[SW] 🚀 Starting fallback system (Firebase not available)');
        startPeriodicCheck();
      } else if (firebaseInitialized) {
        console.log('[SW] ✅ Firebase available - push notifications will be used instead of fallback');
      }
    } else {
      console.log('[SW] 📭 No fallback notifications to restore');
    }
  } catch (e) {
    console.error('[SW] ❌ Error restoring fallback notifications:', e);
  }
}

// Initialize on startup
restoreScheduledNotifications();

console.log('[SW] ✅ Unified Service Worker loaded - Firebase Push + Cache + Local Fallback');
