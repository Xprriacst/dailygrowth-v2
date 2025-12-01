// Service dédié aux notifications web pour PWA avec Firebase Cloud Messaging
import 'package:flutter/foundation.dart';
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'dart:html' as html;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

// Note: This service only works on web platform
// All methods include kIsWeb guards to prevent errors on other platforms

class WebNotificationService {
  static final WebNotificationService _instance =
      WebNotificationService._internal();
  factory WebNotificationService() => _instance;
  WebNotificationService._internal();

  bool _isInitialized = false;
  String? _permission;
  String? _fcmToken;
  final SupabaseService _supabaseService = SupabaseService();

  // Firebase configuration (matching service worker)
  static const firebaseConfig = {
    'apiKey': "AIzaSyCdJSoFjbBqFxtxxrlRV2zc7ow_Um7dC5U",
    'authDomain': "dailygrowth-pwa.firebaseapp.com",
    'projectId': "dailygrowth-pwa",
    'storageBucket': "dailygrowth-pwa.appspot.com",
    'messagingSenderId': "443167745906",
    'appId': "1:443167745906:web:c0e8f1c03571d440f3dfeb",
    'measurementId': "G-BXJW80Y4EF"
  };

  Future<void> initialize() async {
    // Only initialize on web platform
    if (!kIsWeb) {
      debugPrint(
          'WebNotificationService: Not on web platform, skipping initialization');
      return;
    }

    if (_isInitialized) return;

    try {
      // Detect iOS
      final isIOS = html.window.navigator.userAgent.contains(RegExp(r'iPhone|iPad|iPod'));
      final isPWA = html.window.matchMedia('(display-mode: standalone)').matches;
      
      debugPrint('🔍 Platform detection: iOS=$isIOS, PWA=$isPWA');
      
      if (isIOS && !isPWA) {
        debugPrint('⚠️ iOS detected but NOT running as PWA!');
        debugPrint('💡 Notifications require: Safari → Share → Add to Home Screen');
      }

      // Initialize Firebase in the main thread (for foreground messages)
      await _initializeFirebase();

      // Check current permission without requesting (avoid user gesture error)
      if (_isNotificationSupported()) {
        _permission = html.Notification.permission;
        debugPrint('🔔 Current notification permission: $_permission');
        
        if (_permission == 'denied' && isIOS) {
          debugPrint('❌ iOS: Permissions denied. Check Settings → ChallengeMe → Notifications');
        }
      } else {
        _permission = 'denied';
        debugPrint('⚠️ Notifications not supported on this browser');
      }

      // Wait for service worker to be ready
      if (html.window.navigator.serviceWorker != null) {
        try {
          final registration = await html.window.navigator.serviceWorker!.ready;
          debugPrint('✅ Service Worker ready and active');
        } catch (e) {
          debugPrint('⚠️ Service Worker not ready: $e');
        }
      }

      _isInitialized = true;
      debugPrint('✅ WebNotificationService initialized with Firebase FCM');
    } catch (e) {
      debugPrint('❌ Failed to initialize WebNotificationService: $e');
    }
  }

  Future<Map<String, dynamic>> _ensureWebPushSubscription({bool forceResubscribe = false}) async {
    if (!kIsWeb) {
      throw Exception('Web Push non disponible sur cette plateforme');
    }

    if (html.window.navigator.serviceWorker == null) {
      throw Exception('Service Worker indisponible – impossible d\'activer les notifications');
    }

    final script = '''
      (async function() {
        try {
          const forceResubscribe = ${forceResubscribe ? 'true' : 'false'};

          if (!('serviceWorker' in navigator)) {
            return { error: 'service-worker-unavailable' };
          }

          const registration = await navigator.serviceWorker.ready;
          if (!registration.pushManager) {
            return { error: 'push-manager-unavailable' };
          }

          // Priorité: Web Push VAPID pour iOS, sinon Firebase VAPID
          const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
          let vapidKey = null;
          
          if (isIOS) {
            // iOS PWA utilise Web Push standard, pas FCM
            vapidKey = window.WEB_PUSH_VAPID_PUBLIC_KEY || (window.ENV && window.ENV.WEB_PUSH_VAPID_PUBLIC_KEY);
            console.log('📱 iOS détecté - utilisation de la clé Web Push VAPID');
          }
          
          // Fallback sur Firebase VAPID pour autres plateformes
          if (!vapidKey) {
            vapidKey = window.firebaseVapidKey || (window.ENV && window.ENV.FIREBASE_VAPID_KEY);
          }
          
          if (!vapidKey) {
            return { error: 'missing-vapid-key' };
          }
          
          console.log('🔑 Utilisation VAPID:', vapidKey.substring(0, 20) + '...');

          function urlBase64ToUint8Array(base64String) {
            const padding = '='.repeat((4 - base64String.length % 4) % 4);
            const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
            const rawData = window.atob(base64);
            const outputArray = new Uint8Array(rawData.length);
            for (let i = 0; i < rawData.length; ++i) {
              outputArray[i] = rawData.charCodeAt(i);
            }
            return outputArray;
          }

          if (forceResubscribe) {
            const existing = await registration.pushManager.getSubscription();
            if (existing) {
              try {
                await existing.unsubscribe();
              } catch (unsubscribeError) {
                console.warn('⚠️ Unable to unsubscribe previous push registration', unsubscribeError);
              }
            }
          }

          let subscription = await registration.pushManager.getSubscription();
          if (!subscription) {
            subscription = await registration.pushManager.subscribe({
              userVisibleOnly: true,
              applicationServerKey: urlBase64ToUint8Array(vapidKey)
            });
          }

          const json = subscription.toJSON();
          return {
            endpoint: subscription.endpoint,
            keys: json && json.keys ? json.keys : null,
            expirationTime: subscription.expirationTime || null
          };
        } catch (error) {
          return { error: error?.message || 'web-push-subscription-failed' };
        }
      })()
    ''';

    final jsResult = js.context.callMethod('eval', [script]);
    dynamic resolved;
    try {
      resolved = await js_util.promiseToFuture(jsResult);
    } catch (e) {
      debugPrint('❌ Promise rejected: $e');
      resolved = jsResult;
    }

    // Essayer de convertir le résultat JavaScript en Map Dart
    Map<String, dynamic> result;
    try {
      final dartified = js_util.dartify(resolved);
      if (dartified is Map) {
        result = Map<String, dynamic>.from(dartified);
      } else {
        // Fallback: extraire les propriétés manuellement
        debugPrint('⚠️ dartify returned ${dartified.runtimeType}, trying manual extraction');
        final error = js_util.getProperty(resolved, 'error');
        final endpoint = js_util.getProperty(resolved, 'endpoint');
        final keys = js_util.getProperty(resolved, 'keys');
        
        if (error != null) {
          throw Exception('Web Push indisponible: $error');
        }
        
        if (endpoint == null) {
          throw Exception('Réponse invalide: endpoint manquant');
        }
        
        result = {
          'endpoint': endpoint.toString(),
          'keys': keys != null ? js_util.dartify(keys) : null,
        };
      }
    } catch (e) {
      debugPrint('❌ Failed to parse JS result: $e, resolved type: ${resolved.runtimeType}');
      throw Exception('Réponse invalide lors de la création de l\'abonnement Web Push: $e');
    }

    if (result.containsKey('error') && result['error'] != null) {
      throw Exception('Web Push indisponible: ${result['error']}');
    }

    return result;
  }

  String _detectWebPlatformLabel() {
    if (!kIsWeb) return 'unknown';

    final userAgent = html.window.navigator.userAgent.toLowerCase();
    final isStandalone = () {
      try {
        return js_util.hasProperty(html.window.navigator, 'standalone') &&
            js_util.getProperty(html.window.navigator, 'standalone') == true;
      } catch (_) {
        return false;
      }
    }();

    if (userAgent.contains('iphone') || userAgent.contains('ipad') || userAgent.contains('ipod')) {
      return isStandalone ? 'ios-pwa' : 'ios-browser';
    }

    if (userAgent.contains('android')) {
      return isStandalone ? 'android-pwa' : 'android-browser';
    }

    if (userAgent.contains('macintosh')) {
      return 'macos-browser';
    }

    if (userAgent.contains('windows')) {
      return 'windows-browser';
    }

    return 'web';
  }

  Future<void> syncSubscriptionWithServer({bool forceResubscribe = false}) async {
    if (!kIsWeb) return;

    final subscription = await _ensureWebPushSubscription(forceResubscribe: forceResubscribe);
    final endpoint = subscription['endpoint'] as String?;
    final keys = subscription['keys'];

    if (endpoint == null || keys == null) {
      throw Exception('Impossible de récupérer un abonnement Web Push valide');
    }

    final client = await _supabaseService.client;
    final currentUser = client.auth.currentUser;

    if (currentUser == null) {
      throw Exception('Utilisateur non connecté');
    }

    final payload = {
      'user_id': currentUser.id,
      'endpoint': endpoint,
      'keys': keys,
      'platform': _detectWebPlatformLabel(),
    };

    try {
      await client
          .from('web_push_subscriptions')
          .upsert(payload, onConflict: 'endpoint')
          .select()
          .maybeSingle();
      debugPrint('✅ Abonnement Web Push synchronisé pour ${currentUser.id}');
    } catch (e) {
      throw Exception('Impossible d\'enregistrer l\'abonnement Web Push: $e');
    }
  }

  Future<bool> shouldShowPermissionDialog() async {
    if (!kIsWeb) return false;
    return _permission == 'default' && _isNotificationSupported();
  }

  Future<void> _initializeFirebase() async {
    try {
      // Check if Firebase is available
      if (js.context.hasProperty('firebase')) {
        debugPrint('🔥 Firebase SDK detected, initializing...');

        // Initialize Firebase app if not already done
        var firebaseApps =
            js_util.callMethod(js.context['firebase'], 'getApps', []);
        if (js_util.getProperty(firebaseApps, 'length') == 0) {
          js_util.callMethod(js.context['firebase'], 'initializeApp',
              [js_util.jsify(firebaseConfig)]);
          debugPrint('🔥 Firebase app initialized');
        }

        // Get messaging instance
        var messaging =
            js_util.callMethod(js.context['firebase'], 'messaging', []);

        // Handle foreground messages
        js_util.callMethod(messaging, 'onMessage', [
          js.allowInterop((payload) {
            debugPrint('📨 Foreground message received: $payload');
            _handleForegroundMessage(payload);
          })
        ]);

        debugPrint('🔥 Firebase messaging setup complete');
      } else {
        debugPrint('⚠️ Firebase SDK not available, fallback mode will be used');
      }
    } catch (e) {
      debugPrint('❌ Firebase initialization error: $e');
    }
  }

  void _handleForegroundMessage(dynamic payload) {
    try {
      debugPrint('📱 Handling foreground Firebase message...');

      // Extract notification data
      var notification = js_util.getProperty(payload, 'notification');
      var title = js_util.getProperty(notification, 'title') ?? 'ChallengeMe';
      var body = js_util.getProperty(notification, 'body') ?? 'Nouveau message';

      // Show notification using web notification API
      showNotification(title: title, body: body);

      // Update badge if provided
      var data = js_util.getProperty(payload, 'data');
      if (data != null) {
        var badgeCount = js_util.getProperty(data, 'badge_count');
        if (badgeCount != null) {
          updateBadge(int.tryParse(badgeCount.toString()) ?? 0);
        }
      }
    } catch (e) {
      debugPrint('❌ Error handling foreground message: $e');
    }
  }

  bool _isNotificationSupported() {
    if (!kIsWeb) return false;
    // Simplified check - would use actual web APIs on web platform
    return kIsWeb;
  }

  Future<String> requestPermission() async {
    if (!kIsWeb) {
      debugPrint('WebNotificationService: Not on web platform');
      return 'denied';
    }

    try {
      debugPrint('🔔 Requesting notification permission...');

      // Detect iOS
      final isIOS = html.window.navigator.userAgent.contains(RegExp(r'iPhone|iPad|iPod'));
      debugPrint('🧭 User agent: ${html.window.navigator.userAgent}');
      debugPrint('🧭 Detected iOS via userAgent: $isIOS');

      // Check standalone mode (PWA)
      bool isStandaloneFlag = false;
      try {
        isStandaloneFlag = js_util.hasProperty(html.window.navigator, 'standalone') &&
            js_util.getProperty(html.window.navigator, 'standalone') == true;
      } catch (_) {
        isStandaloneFlag = false;
      }
      final isStandaloneMediaQuery = html.window.matchMedia('(display-mode: standalone)').matches;
      final isPWA = isStandaloneFlag || isStandaloneMediaQuery;
      debugPrint('🏠 navigator.standalone: $isStandaloneFlag');
      debugPrint('🏠 display-mode standalone: $isStandaloneMediaQuery');
      debugPrint('🏠 Detected PWA mode: $isPWA');

      if (!html.Notification.supported) {
        debugPrint('⚠️ Notifications not supported on this platform');
        _permission = 'denied';
        return 'denied';
      }

      // Check current permission first
      final currentPermission = html.Notification.permission;
      debugPrint('🔍 Current permission before request: $currentPermission');

      if (currentPermission == 'granted') {
        _permission = 'granted';
        debugPrint('✅ Permission already granted, skipping request');

        // Try to get FCM token
        try {
          _fcmToken = await _ensureFcmToken();
          if (_fcmToken != null && _fcmToken!.isNotEmpty) {
            debugPrint('🔑 FCM Token: ${_fcmToken!.substring(0, 20)}...');
          }
        } catch (e) {
          debugPrint('⚠️ Could not get FCM token: $e');
        }

        return 'granted';
      }

      if (currentPermission == 'denied') {
        _permission = 'denied';
        debugPrint('❌ Permission previously denied by user');
        return 'denied';
      }

      // Request permission - iOS Safari requires special handling
      String? permission;

      try {
        debugPrint('🔔 Requesting notification permission...');

        // Use JS interop for iOS compatibility
        final result = js.context.callMethod('eval', ['''
          (async function() {
            try {
              console.log('🔔 Requesting notification permission...');

              if (!('Notification' in window)) {
                console.log('❌ Notification API not available');
                return 'denied';
              }

              if (typeof Notification.requestPermission !== 'function') {
                console.log('❌ requestPermission not available');
                return Notification.permission || 'denied';
              }

              // Try modern promise-based API
              try {
                const result = await Notification.requestPermission();
                console.log('🔔 Permission result:', result);
                return result;
              } catch (e) {
                console.log('⚠️ Modern API failed:', e);

                // Fallback to callback-based API for older browsers/iOS
                return new Promise((resolve) => {
                  try {
                    Notification.requestPermission(function(result) {
                      console.log('🔔 Permission result (callback):', result);
                      resolve(result);
                    });
                  } catch (callbackError) {
                    console.log('❌ Callback API also failed:', callbackError);
                    resolve('denied');
                  }
                });
              }
            } catch (error) {
              console.error('❌ Permission request error:', error);
              return 'denied';
            }
          })()
        ''']);

        if (result != null) {
          try {
            final resolvedResult = await js_util.promiseToFuture(result);
            permission = resolvedResult?.toString() ?? 'denied';
          } catch (e) {
            debugPrint('⚠️ Could not resolve promise: $e');
            permission = result.toString();
          }
        } else {
          permission = 'denied';
        }

        debugPrint('🔔 Permission result: $permission');
        _permission = permission;

        // If granted, setup push notifications
        if (permission == 'granted') {
          // Detect iOS to use Web Push instead of FCM
          final isIOSDevice = html.window.navigator.userAgent.contains(RegExp(r'iPhone|iPad|iPod'));
          
          if (isIOSDevice) {
            // iOS PWA: Use standard Web Push with VAPID
            debugPrint('📱 iOS PWA: Synchronisation Web Push...');
            try {
              await syncSubscriptionWithServer();
              debugPrint('✅ Web Push subscription synchronized for iOS');
            } catch (e) {
              debugPrint('❌ Error syncing Web Push subscription: $e');
            }
          } else {
            // Other platforms: Try FCM first, fallback to Web Push
            try {
              _fcmToken = await _ensureFcmToken();
              if (_fcmToken != null && _fcmToken!.isNotEmpty) {
                debugPrint('🔑 FCM Token obtained: ${_fcmToken!.substring(0, 20)}...');
                await sendMessageToServiceWorker({'type': 'FCM_TOKEN', 'token': _fcmToken});
              } else {
                debugPrint('⚠️ FCM token not available, trying Web Push fallback...');
                await syncSubscriptionWithServer();
                debugPrint('✅ Web Push subscription synchronized as fallback');
              }
            } catch (e) {
              debugPrint('⚠️ FCM failed, trying Web Push: $e');
              try {
                await syncSubscriptionWithServer();
                debugPrint('✅ Web Push subscription synchronized as fallback');
              } catch (webPushError) {
                debugPrint('❌ Both FCM and Web Push failed: $webPushError');
              }
            }
          }
        }

        return permission ?? 'denied';
      } catch (e) {
        debugPrint('❌ requestPermission invocation failed: $e');
        _permission = 'denied';
        return 'denied';
      }
    } catch (e) {
      debugPrint('❌ Error in requestPermission: $e');
      _permission = 'denied';
      return 'denied';
    }
  }

  Future<String?> _ensureFcmToken() async {
    if (!kIsWeb) return null;

    if (_fcmToken != null && _fcmToken!.isNotEmpty) {
      return _fcmToken;
    }

    try {
      final existingToken = await getFCMToken();
      if (existingToken != null && existingToken.isNotEmpty) {
        _fcmToken = existingToken;
        return _fcmToken;
      }
    } catch (e) {
      debugPrint('⚠️ Error retrieving existing FCM token: $e');
    }

    try {
      final generatedToken = await generateFCMToken();
      if (generatedToken != null && generatedToken.isNotEmpty) {
        _fcmToken = generatedToken;
      }
    } catch (e) {
      debugPrint('❌ Error generating FCM token: $e');
    }

    return _fcmToken;
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? icon,
    String? tag,
    Map<String, dynamic>? data,
    List<Map<String, String>>? actions,
  }) async {
    if (!kIsWeb) {
      debugPrint('WebNotificationService: Not on web platform');
      return;
    }

    try {
      debugPrint('📱 Showing web notification: $title - $body');
      
      // Utiliser le service worker pour afficher la notification
      if (html.window.navigator.serviceWorker != null) {
        final registration = await html.window.navigator.serviceWorker!.ready;
        final controller = registration.active;
        
        if (controller != null) {
          final message = js_util.jsify({
            'type': 'SHOW_NOTIFICATION',
            'title': title,
            'body': body,
            'icon': icon ?? '/icons/Icon-192.png',
            'tag': tag ?? 'challengeme-notification',
            'data': data ?? {},
          });
          controller.postMessage(message);
          debugPrint('✅ Notification envoyée au service worker');
        } else {
          // Fallback: utiliser l'API Notification directement
          if (html.Notification.permission == 'granted') {
            html.Notification(title, body: body, icon: icon ?? '/icons/Icon-192.png', tag: tag);
            debugPrint('✅ Notification affichée via API directe');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error showing notification: $e');
    }
  }

  Future<void> updateBadge(int count) async {
    if (!kIsWeb) {
      debugPrint('WebNotificationService: Not on web platform');
      return;
    }

    try {
      debugPrint('📱 Updating badge count: $count');
      // On web platform, would update actual badge
    } catch (e) {
      debugPrint('❌ Error updating badge: $e');
    }
  }

  Future<void> clearBadge() async {
    if (!kIsWeb) {
      debugPrint('WebNotificationService: Not on web platform');
      return;
    }

    try {
      debugPrint('📱 Clearing badge');
      // On web platform, would clear actual badge
    } catch (e) {
      debugPrint('❌ Error clearing badge: $e');
    }
  }

  bool isPWAInstalled() {
    if (!kIsWeb) return false;

    try {
      // On web platform, would check actual PWA status
      return false; // Simplified for testing
    } catch (e) {
      debugPrint('❌ Error checking PWA status: $e');
      return false;
    }
  }

  Future<void> triggerTestNotification() async {
    if (!kIsWeb) {
      debugPrint('WebNotificationService: Not on web platform');
      return;
    }

    try {
      debugPrint('🧪 Triggering test notification...');
      await showNotification(
        title: 'Test Notification',
        body: 'This is a test notification from ChallengeMe',
        icon: '/icons/icon-192.png',
      );
    } catch (e) {
      debugPrint('❌ Error triggering test notification: $e');
    }
  }

  // Additional methods required by NotificationService
  String get permissionStatus => _permission ?? 'default';

  Future<String?> getFCMToken() async {
    if (!kIsWeb) return null;

    try {
      debugPrint('🔑 Getting FCM token (web)');

      // Try to get FCM token from localStorage (saved by Firebase JS)
      final token = html.window.localStorage['fcm_token'];
      if (token != null && token.isNotEmpty) {
        debugPrint('🔑 FCM Token récupéré: ${token.substring(0, 20)}...');
        return token;
      }

      debugPrint('⚠️ No FCM token in localStorage');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  Future<String?> generateFCMToken() async {
    if (!kIsWeb) return null;

    try {
      debugPrint('🔍 Attempting to generate FCM token...');

      // Use JavaScript eval for token generation (working approach from development)
      final result = js.context.callMethod('eval', [
        '''
        (async function() {
          console.log("🔥 Starting FCM token generation...");

          try {
            if (window.firebaseApp && window.firebaseMessaging && window.firebaseVapidKey) {
              console.log("✅ All Firebase objects present");

              var registration = window.unifiedServiceWorkerRegistration;
              if (!registration && navigator.serviceWorker) {
                try {
                  registration = await navigator.serviceWorker.getRegistration("/sw.js");
                } catch (error) {
                  console.warn("⚠️ Error retrieving /sw.js registration", error);
                }

                if (!registration) {
                  try {
                    registration = await navigator.serviceWorker.ready;
                  } catch (readyError) {
                    console.warn("⚠️ Error waiting for service worker ready", readyError);
                  }
                }
              }

              if (!registration) {
                console.warn("⚠️ No service worker registration available for FCM token generation");
                return null;
              }

              const { getToken } = await import('https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging.js');

              const token = await getToken(window.firebaseMessaging, {
                vapidKey: window.firebaseVapidKey,
                serviceWorkerRegistration: registration
              });

              if (token) {
                console.log("🔑 FCM Token generated: " + token.substring(0, 20) + "...");
                localStorage.setItem("fcm_token", token);
                return token;
              }

              console.log("⚠️ No registration token available");
              return null;
            }

            console.log("❌ Firebase objects missing");
            return null;
          } catch (error) {
            console.error("❌ Error generating token:", error);
            return null;
          }
        })()
      '''
      ]);

      if (result != null) {
        dynamic resolvedResult;
        try {
          resolvedResult = await js_util.promiseToFuture(result);
        } catch (_) {
          resolvedResult = result;
        }

        if (resolvedResult != null && resolvedResult.toString().isNotEmpty) {
          final tokenString = resolvedResult.toString();
          debugPrint(
              '✅ FCM Token successfully generated: ${tokenString.substring(0, 20)}...');
          return tokenString;
        }
      }

      debugPrint('⚠️ Token generation failed');
      return null;
    } catch (e) {
      debugPrint('❌ Error generating FCM token: $e');
      return null;
    }
  }

  Future<String?> forceFCMTokenGeneration() async {
    if (!kIsWeb) return null;

    try {
      debugPrint('🚀 FORCE: Attempting to generate FCM token...');

      // Clear existing token first
      html.window.localStorage.remove('fcm_token');

      // Generate new token with force flag
      final result = js.context.callMethod('eval', [
        '''
        (async function() {
          console.log("🚀 FORCE FCM Token Generation Started");

          try {
            if (!(window.firebaseApp && window.firebaseMessaging && window.firebaseVapidKey)) {
              console.log("❌ FORCE: Firebase objects missing");
              return null;
            }

            var registration = window.unifiedServiceWorkerRegistration;
            if (!registration && navigator.serviceWorker) {
              try {
                registration = await navigator.serviceWorker.getRegistration("/sw.js");
              } catch (error) {
                console.warn("⚠️ FORCE: Error retrieving /sw.js registration", error);
              }

              if (!registration) {
                try {
                  registration = await navigator.serviceWorker.ready;
                } catch (readyError) {
                  console.warn("⚠️ FORCE: Error waiting for service worker ready", readyError);
                }
              }
            }

            if (!registration) {
              console.warn("⚠️ FORCE: No service worker registration available");
              return null;
            }

            const { getToken, deleteToken } = await import('https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging.js');

            try {
              await deleteToken(window.firebaseMessaging, {
                serviceWorkerRegistration: registration
              });
              console.log("🗑️ FORCE: Existing token deleted");
            } catch (deleteError) {
              console.warn("⚠️ FORCE: Unable to delete existing token", deleteError);
            }

            const token = await getToken(window.firebaseMessaging, {
              vapidKey: window.firebaseVapidKey,
              serviceWorkerRegistration: registration
            });

            if (token) {
              localStorage.setItem("fcm_token", token);
              console.log("🎉 FORCE: New FCM Token generated: " + token.substring(0, 20) + "...");
              return token;
            }

            console.log("⚠️ FORCE: No token available");
            return null;
          } catch (error) {
            console.error("❌ FORCE: Error generating token:", error);
            return null;
          }
        })()
      '''
      ]);

      if (result != null) {
        dynamic resolvedResult;
        try {
          resolvedResult = await js_util.promiseToFuture(result);
        } catch (_) {
          resolvedResult = result;
        }

        if (resolvedResult != null && resolvedResult.toString().isNotEmpty) {
          final tokenString = resolvedResult.toString();
          debugPrint(
              '🎉 FORCE: FCM Token successfully generated: ${tokenString.substring(0, 20)}...');
          return tokenString;
        }
      }

      debugPrint('⚠️ FORCE: Token generation failed');
      return null;
    } catch (e) {
      debugPrint('❌ FORCE: Error generating FCM token: $e');
      return null;
    }
  }

  Future<void> showChallengeNotification({
    String? title,
    String? body,
    String? icon,
    Map<String, dynamic>? data,
    String? challengeName,
    String? challengeId,
  }) async {
    await showNotification(
      title: title ?? challengeName ?? 'Nouveau défi',
      body: body ?? 'Un nouveau défi vous attend !',
      icon: icon,
      data: data,
    );
  }

  Future<void> showReminderNotification({
    String? title,
    String? body,
    String? icon,
    Map<String, dynamic>? data,
    String? userName,
  }) async {
    await showNotification(
      title: title ?? 'Rappel ChallengeMe',
      body: body ?? 'N\'oubliez pas votre défi du jour ${userName ?? ''}!',
      icon: icon,
      data: data,
    );
  }

  Future<void> showAchievementNotification({
    String? title,
    String? body,
    String? icon,
    Map<String, dynamic>? data,
    String? achievementName,
    String? description,
    int? pointsEarned,
  }) async {
    await showNotification(
      title: title ?? 'Succès débloqué !',
      body: body ??
          description ??
          achievementName ??
          'Félicitations pour votre progression ! ${pointsEarned != null ? '+$pointsEarned points' : ''}',
      icon: icon,
      data: data,
    );
  }

  Future<void> showStreakNotification({
    String? title,
    String? body,
    String? icon,
    Map<String, dynamic>? data,
    int? streakCount,
  }) async {
    await showNotification(
      title: title ?? 'Série en cours !',
      body: body ?? 'Vous avez ${streakCount ?? 0} jours consécutifs !',
      icon: icon,
      data: data,
    );
  }

  Future<void> sendMessageToServiceWorker(Map<String, dynamic> message) async {
    if (!kIsWeb) {
      debugPrint('WebNotificationService: Not on web platform');
      return;
    }

    try {
      debugPrint('📨 Sending message to service worker: $message');

      // Simple approach using JavaScript eval (working method from development)
      final messageJson =
          js.context['JSON'].callMethod('stringify', [js_util.jsify(message)]);
      js.context.callMethod('eval', [
        '''
        (function() {
          var message = $messageJson;
          console.log('📨 About to send message:', message);
          
          if ('serviceWorker' in navigator) {
            navigator.serviceWorker.ready.then(function(registration) {
              if (registration.active) {
                registration.active.postMessage(message);
                console.log('📨 Message sent to service worker successfully');
              } else {
                console.log('⚠️ No active service worker found');
              }
            }).catch(function(error) {
              console.error('❌ Error sending message to service worker:', error);
            });
          } else {
            console.log('⚠️ Service worker not supported');
          }
        })()
      '''
      ]);
    } catch (e) {
      debugPrint('❌ Error sending message to service worker: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    if (!kIsWeb) {
      debugPrint('WebNotificationService: Not on web platform');
      return;
    }

    try {
      debugPrint('🧹 Clearing all notifications');
      // On web platform, would clear actual notifications
    } catch (e) {
      debugPrint('❌ Error clearing notifications: $e');
    }
  }
}
