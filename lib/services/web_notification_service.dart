// Service dédié aux notifications web pour PWA
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'dart:js' as js;

class WebNotificationService {
  static final WebNotificationService _instance = WebNotificationService._internal();
  factory WebNotificationService() => _instance;
  WebNotificationService._internal();

  bool _isInitialized = false;
  String? _permission;

  Future<void> initialize() async {
    if (_isInitialized || !kIsWeb) return;

    try {
      // Vérifier le support des notifications
      if (!_isNotificationSupported()) {
        debugPrint('❌ Web notifications not supported in this browser');
        return;
      }

      // Vérifier l'état actuel des permissions sans les demander
      _permission = html.Notification.permission;
      debugPrint('🔔 Current web notification permission: $_permission');

      // Configurer les gestionnaires d'événements
      _setupEventHandlers();

      _isInitialized = true;
      debugPrint('✅ WebNotificationService initialized (permission not requested yet)');
    } catch (e) {
      debugPrint('❌ Failed to initialize WebNotificationService: $e');
    }
  }

  bool _isNotificationSupported() {
    return js.context.hasProperty('Notification') && 
           html.Notification.supported;
  }

  void _setupEventHandlers() {
    // Écouter les messages du service worker pour les badges
    html.window.addEventListener('message', (event) {
      final data = (event as html.MessageEvent).data;
      if (data is Map && data['type'] == 'BADGE_UPDATED') {
        debugPrint('📱 Badge updated: ${data['count']}');
      }
    });
  }

  // Afficher une notification web native
  Future<void> showNotification({
    required String title,
    required String body,
    String? icon,
    String? tag,
    Map<String, dynamic>? data,
    List<Map<String, String>>? actions,
  }) async {
    if (!kIsWeb || !_isInitialized || _permission != 'granted') {
      debugPrint('❌ Cannot show web notification: not initialized or permission denied');
      return;
    }

    try {
      final options = <String, dynamic>{
        'body': body,
        'icon': icon ?? '/icons/Icon-192.png',
        'badge': '/icons/Icon-192.png',
        'tag': tag ?? 'dailygrowth-notification',
        'requireInteraction': false,
        'silent': false,
        'data': data ?? {},
      };

      // Ajouter les actions si disponibles
      if (actions != null && actions.isNotEmpty) {
        options['actions'] = actions.map((action) => {
          'action': action['action'],
          'title': action['title'],
          'icon': action['icon'],
        }).toList();
      }

      // Créer la notification
      final notification = html.Notification(title);
      // Note: Options via constructor not supported, using properties instead

      // Gérer le clic sur la notification
      notification.onClick.listen((_) {
        debugPrint('🔔 Web notification clicked');
        try { 
          // Focus not available in modern browsers for security 
        } catch (e) {
          debugPrint('Focus not available: $e');
        }
        notification.close();
        
        // Navigation si URL fournie dans data
        if (data != null && data['url'] != null) {
          html.window.location.href = data['url'];
        }
      });

      // Auto-fermeture après 5 secondes
      Future.delayed(const Duration(seconds: 5), () {
        try {
          notification.close();
        } catch (e) {
          // Ignore - notification peut déjà être fermée
        }
      });

      debugPrint('✅ Web notification shown: $title');
    } catch (e) {
      debugPrint('❌ Failed to show web notification: $e');
    }
  }

  // Mettre à jour le badge d'application (iOS Safari 16.4+)
  Future<void> updateBadge(int count) async {
    if (!kIsWeb) return;

    try {
      // Méthode 1: Badge API native (Safari iOS 16.4+)
      if (js.context.hasProperty('navigator') && 
          js.context['navigator'].hasProperty('setAppBadge')) {
        if (count > 0) {
          js.context['navigator'].callMethod('setAppBadge', [count]);
          debugPrint('🔴 Badge updated via native API: $count');
        } else {
          js.context['navigator'].callMethod('clearAppBadge');
          debugPrint('🔴 Badge cleared via native API');
        }
        return;
      }

      // Méthode 2: Service Worker
      if (js.context['navigator'].hasProperty('serviceWorker')) {
        final registration = await html.window.navigator.serviceWorker?.ready;
        if (registration != null) {
          registration.active?.postMessage({
            'type': 'SET_BADGE',
            'count': count
          });
          debugPrint('🔴 Badge update sent to service worker: $count');
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to update badge: $e');
    }
  }

  // Vérifier si les notifications sont autorisées
  bool get isPermissionGranted => _permission == 'granted';

  // Obtenir le statut de permission
  String get permissionStatus => _permission ?? 'default';

  // Demander la permission explicitement avec diagnostic iOS
  Future<String> requestPermission() async {
    if (!kIsWeb || !_isNotificationSupported()) {
      debugPrint('❌ Web notifications not supported');
      return 'denied';
    }

    try {
      // Diagnostic iOS spécifique
      _logIOSDiagnostic();
      
      _permission = await html.Notification.requestPermission();
      debugPrint('🔔 Permission requested: $_permission');
      
      // Diagnostic post-permission
      if (_permission == 'denied') {
        debugPrint('❌ DIAGNOSTIC: Permission denied - vérifiez que l\'app est installée comme PWA');
      }
      
      return _permission!;
    } catch (e) {
      debugPrint('❌ Failed to request permission: $e');
      return 'denied';
    }
  }

  void _logIOSDiagnostic() {
    try {
      final userAgent = html.window.navigator.userAgent;
      final isIOS = userAgent.contains('iPhone') || userAgent.contains('iPad');
      final isSafari = userAgent.contains('Safari') && !userAgent.contains('Chrome');
      
      // Vérifier si l'app est en mode standalone (PWA)
      bool isStandalone = false;
      try {
        // Utiliser JS interop pour accéder à navigator.standalone
        isStandalone = js.context['navigator']['standalone'] == true;
      } catch (e) {
        // Fallback: vérifier via display-mode CSS
        debugPrint('Fallback: checking display-mode for PWA detection');
      }
      
      debugPrint('📱 iOS DIAGNOSTIC:');
      debugPrint('  - User Agent: $userAgent');
      debugPrint('  - Is iOS: $isIOS');
      debugPrint('  - Is Safari: $isSafari');
      debugPrint('  - Is PWA (standalone): $isStandalone');
      debugPrint('  - Notification support: ${_isNotificationSupported()}');
      
      if (isIOS && !isStandalone) {
        debugPrint('⚠️ PROBLÈME DÉTECTÉ: App non installée comme PWA sur iOS');
        debugPrint('   SOLUTION: Safari → Partager → "Ajouter à l\'écran d\'accueil"');
      }
    } catch (e) {
      debugPrint('❌ Error in iOS diagnostic: $e');
    }
  }

  // Envoyer un message au service worker
  Future<void> sendMessageToServiceWorker(Map<String, dynamic> message) async {
    if (!kIsWeb) return;

    try {
      if (js.context['navigator'].hasProperty('serviceWorker')) {
        final registration = await html.window.navigator.serviceWorker?.ready;
        if (registration?.active != null) {
          registration!.active!.postMessage(message);
          debugPrint('📨 Message sent to service worker: ${message['type']}');
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to send message to service worker: $e');
    }
  }

  // Notifications prédéfinies pour DailyGrowth
  Future<void> showChallengeNotification({
    required String challengeName,
    String? challengeId,
  }) async {
    await showNotification(
      title: '🎯 Nouveau défi disponible !',
      body: challengeName,
      tag: 'challenge-notification',
      data: {
        'type': 'challenge',
        'challengeId': challengeId,
        'url': '/#/challenges',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      actions: [
        {'action': 'view', 'title': 'Voir le défi', 'icon': '/icons/Icon-192.png'},
        {'action': 'dismiss', 'title': 'Plus tard', 'icon': '/icons/Icon-192.png'},
      ],
    );

    // Mettre à jour le badge
    await updateBadge(1);
  }

  Future<void> showQuoteNotification({
    required String quote,
    required String author,
  }) async {
    await showNotification(
      title: '💫 Citation du jour',
      body: '"$quote" - $author',
      tag: 'quote-notification',
      data: {
        'type': 'quote',
        'url': '/#/quotes',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      actions: [
        {'action': 'view', 'title': 'Voir plus', 'icon': '/icons/Icon-192.png'},
        {'action': 'dismiss', 'title': 'Fermer', 'icon': '/icons/Icon-192.png'},
      ],
    );
  }

  Future<void> showAchievementNotification({
    required String achievementName,
    required String description,
    required int pointsEarned,
  }) async {
    await showNotification(
      title: '🏆 Nouveau succès débloqué !',
      body: '$achievementName - $description (+$pointsEarned points)',
      tag: 'achievement-notification',
      data: {
        'type': 'achievement',
        'url': '/#/profile',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      actions: [
        {'action': 'view', 'title': 'Voir profil', 'icon': '/icons/Icon-192.png'},
        {'action': 'share', 'title': 'Partager', 'icon': '/icons/Icon-192.png'},
      ],
    );

    // Mettre à jour le badge avec achievements
    await updateBadge(1);
  }

  Future<void> showStreakNotification({
    required int streakCount,
  }) async {
    String emoji = '🔥';
    String title = 'Série de $streakCount jours !';
    String body = 'Fantastique ! Continuez sur cette belle lancée !';

    if (streakCount == 7) {
      emoji = '🔥';
      title = 'Série de 7 jours !';
      body = 'Incroyable ! Une semaine entière de progression !';
    } else if (streakCount == 30) {
      emoji = '🌟';
      title = 'Série de 30 jours !';
      body = 'Extraordinaire ! Un mois complet de croissance !';
    } else if (streakCount == 100) {
      emoji = '💎';
      title = 'Série de 100 jours !';
      body = 'Légendaire ! Vous êtes un champion de la croissance !';
    }

    await showNotification(
      title: '$emoji $title',
      body: body,
      tag: 'streak-notification',
      data: {
        'type': 'streak',
        'streakCount': streakCount,
        'url': '/#/profile',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      actions: [
        {'action': 'celebrate', 'title': 'Célébrer', 'icon': '/icons/Icon-192.png'},
        {'action': 'continue', 'title': 'Continuer', 'icon': '/icons/Icon-192.png'},
      ],
    );
  }

  Future<void> showReminderNotification({
    required String userName,
  }) async {
    await showNotification(
      title: '⏰ N\'oubliez pas votre défi !',
      body: 'Bonjour $userName, votre micro-défi vous attend dans l\'application.',
      tag: 'reminder-notification',
      data: {
        'type': 'reminder',
        'url': '/#/challenges',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      actions: [
        {'action': 'open', 'title': 'Ouvrir', 'icon': '/icons/Icon-192.png'},
        {'action': 'snooze', 'title': 'Plus tard', 'icon': '/icons/Icon-192.png'},
      ],
    );
  }

  // Nettoyer les badges et notifications
  Future<void> clearBadge() async {
    await updateBadge(0);
  }

  Future<void> clearAllNotifications() async {
    try {
      await sendMessageToServiceWorker({'type': 'CLEAR_NOTIFICATIONS'});
      await clearBadge();
      debugPrint('🧹 All notifications cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear notifications: $e');
    }
  }

  // Get FCM token for debugging purposes
  Future<String?> getFCMToken() async {
    if (!kIsWeb) return null;
    
    try {
      // Try to get FCM token from localStorage (saved by Firebase JS)
      final token = html.window.localStorage['fcm_token'];
      if (token != null && token.isNotEmpty) {
        debugPrint('🔑 FCM Token retrieved from localStorage');
        return token;
      }
      
      debugPrint('⚠️ No FCM token in localStorage');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  // Generate FCM token using modern Firebase v10+ API with enhanced debugging
  Future<String?> generateFCMToken() async {
    if (!kIsWeb) return null;
    
    try {
      debugPrint('🔍 Attempting to generate FCM token...');
      
      // First, wait a moment to ensure Firebase is fully loaded
      await Future.delayed(Duration(seconds: 1));
      
      // Enhanced debug version with step-by-step logging
      final result = js.context.callMethod('eval', ['''
        (async function() {
          console.log('🔄 Starting FCM token generation...');
          
          try {
            // Step 1: Check Firebase availability
            console.log('📱 Step 1: Checking Firebase availability...');
            if (typeof window === 'undefined') {
              console.error('❌ Window object not available');
              return { error: 'Window object not available' };
            }
            
            if (typeof window.firebaseApp === 'undefined') {
              console.error('❌ Firebase App not initialized');
              console.log('Available window objects:', Object.keys(window).filter(k => k.includes('firebase')));
              return { error: 'Firebase App not initialized. Available: ' + Object.keys(window).filter(k => k.includes('firebase')).join(', ') };
            }
            
            if (typeof window.firebaseMessaging === 'undefined') {
              console.error('❌ Firebase Messaging not initialized');
              return { error: 'Firebase Messaging not initialized' };
            }
            
            console.log('✅ Firebase objects available');
            
            // Step 2: Check permission
            console.log('📱 Step 2: Checking notification permission...');
            if (Notification.permission !== 'granted') {
              console.log('🔔 Requesting notification permission...');
              const permission = await Notification.requestPermission();
              console.log('📱 Permission result:', permission);
              if (permission !== 'granted') {
                return { error: 'Notification permission denied: ' + permission };
              }
            }
            console.log('✅ Notification permission granted');
            
            // Step 3: Get Firebase instances
            console.log('📱 Step 3: Getting Firebase instances...');
            const messaging = window.firebaseMessaging;
            const vapidKey = window.firebaseVapidKey;
            
            if (!vapidKey) {
              console.error('❌ VAPID key not configured');
              console.log('Available vapid key:', window.firebaseVapidKey);
              return { error: 'VAPID key not configured' };
            }
            console.log('✅ VAPID key available:', vapidKey.substring(0, 20) + '...');
            
            // Step 4: Import getToken and generate token
            console.log('📱 Step 4: Importing Firebase messaging and generating token...');
            const { getToken } = await import('https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging.js');
            console.log('✅ Firebase messaging imported');

            const registration = window.unifiedServiceWorkerRegistration 
              || await navigator.serviceWorker.getRegistration('/unified-sw.js')
              || await navigator.serviceWorker.ready;

            console.log('🔄 Calling getToken with unified service worker...');
            const token = await getToken(messaging, {
              vapidKey: vapidKey,
              serviceWorkerRegistration: registration
            });
            
            if (token) {
              // Save to localStorage
              localStorage.setItem('fcm_token', token);
              console.log('✅ FCM Token generated and saved successfully!');
              console.log('📋 Token length:', token.length);
              console.log('📋 Token preview:', token.substring(0, 50) + '...' + token.substring(token.length - 20));
              return { success: true, token: token };
            } else {
              console.error('❌ getToken returned null/undefined');
              return { error: 'getToken returned null - check Firebase project configuration' };
            }
            
          } catch (error) {
            console.error('❌ FCM Token generation error:', error);
            console.error('Error stack:', error.stack);
            return { error: error.message || error.toString(), stack: error.stack };
          }
        })()
      ''']);
      
      debugPrint('🔄 FCM token generation initiated via enhanced debug API');
      
      // Wait longer for token generation to complete
      await Future.delayed(Duration(seconds: 5));
      
      // Get token from localStorage
      final token = await getFCMToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('✅ FCM Token successfully generated: ${token.substring(0, 20)}...');
        return token;
      } else {
        debugPrint('⚠️ Token generation failed - check browser console for detailed logs');
        return null;
      }
      
    } catch (e) {
      debugPrint('❌ Error generating FCM token: $e');
      return null;
    }
  }

  // Force FCM token generation with direct user interaction
  Future<String?> forceFCMTokenGeneration() async {
    if (!kIsWeb) return null;
    
    try {
      debugPrint('🚀 FORCE: Attempting to generate FCM token with user interaction...');
      
      // Direct approach without eval - using window objects directly
      final result = js.context.callMethod('eval', ['''
        (function() {
          console.log('🚀 FORCE FCM Token Generation Started');
          
          // Direct synchronous check
          if (window.firebaseApp && window.firebaseMessaging && window.firebaseVapidKey) {
            console.log('✅ All Firebase objects present');
            
            // Return a function that can be called to generate token
            window.forceFCMGeneration = async function() {
              try {
                const { getToken } = await import('https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging.js');
                const registration = window.unifiedServiceWorkerRegistration 
                  || await navigator.serviceWorker.getRegistration('/unified-sw.js')
                  || await navigator.serviceWorker.ready;

                const token = await getToken(window.firebaseMessaging, {
                  vapidKey: window.firebaseVapidKey,
                  serviceWorkerRegistration: registration
                });
                
                if (token) {
                  localStorage.setItem('fcm_token', token);
                  console.log('🎉 FORCE: Token generated successfully!', token);
                  return token;
                } else {
                  console.error('❌ FORCE: No token returned');
                  return null;
                }
              } catch (error) {
                console.error('❌ FORCE: Error in token generation:', error);
                throw error;
              }
            };
            
            return 'ready';
          } else {
            console.error('❌ FORCE: Firebase objects missing');
            return 'not_ready';
          }
        })()
      ''']);
      
      if (result == 'ready') {
        debugPrint('🔄 FORCE: Firebase ready, calling generation function...');
        
        // Now call the generation function
        final tokenResult = js.context.callMethod('eval', ['''
          (async function() {
            try {
              const token = await window.forceFCMGeneration();
              return token;
            } catch (error) {
              console.error('❌ FORCE: Generation failed:', error);
              return null;
            }
          })()
        ''']);
        
        // Wait for async operation
        await Future.delayed(Duration(seconds: 3));
        
        // Get token from localStorage
        final token = await getFCMToken();
        if (token != null && token.isNotEmpty) {
          debugPrint('🎉 FORCE: FCM Token successfully generated: ${token.substring(0, 20)}...');
          return token;
        }
      }
      
      debugPrint('⚠️ FORCE: Token generation failed');
      return null;
      
    } catch (e) {
      debugPrint('❌ FORCE: Error generating FCM token: $e');
      return null;
    }
  }

  void dispose() {
    // Cleanup if needed
  }
}
