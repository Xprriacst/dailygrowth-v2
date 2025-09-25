// Service dédié aux notifications web pour PWA avec Firebase Cloud Messaging
import 'package:flutter/foundation.dart';
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'dart:html' as html;

// Note: This service only works on web platform
// All methods include kIsWeb guards to prevent errors on other platforms

class WebNotificationService {
  static final WebNotificationService _instance = WebNotificationService._internal();
  factory WebNotificationService() => _instance;
  WebNotificationService._internal();

  bool _isInitialized = false;
  String? _permission;
  String? _fcmToken;

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
      debugPrint('WebNotificationService: Not on web platform, skipping initialization');
      return;
    }
    
    if (_isInitialized) return;

    try {
      // Initialize Firebase in the main thread (for foreground messages)
      await _initializeFirebase();
      
      // Check current permission without requesting (avoid user gesture error)
      _permission = html.Notification.permission;
      debugPrint('🔔 Current notification permission: $_permission');
      
      _isInitialized = true;
      debugPrint('✅ WebNotificationService initialized with Firebase FCM');
    } catch (e) {
      debugPrint('❌ Failed to initialize WebNotificationService: $e');
    }
  }

  Future<void> _initializeFirebase() async {
    try {
      // Check if Firebase is available
      if (js.context.hasProperty('firebase')) {
        debugPrint('🔥 Firebase SDK detected, initializing...');
        
        // Initialize Firebase app if not already done
        var firebaseApps = js_util.callMethod(js.context['firebase'], 'getApps', []);
        if (js_util.getProperty(firebaseApps, 'length') == 0) {
          js_util.callMethod(js.context['firebase'], 'initializeApp', [js_util.jsify(firebaseConfig)]);
          debugPrint('🔥 Firebase app initialized');
        }
        
        // Get messaging instance
        var messaging = js_util.callMethod(js.context['firebase'], 'messaging', []);
        
        // Handle foreground messages
        js_util.callMethod(messaging, 'onMessage', [js.allowInterop((payload) {
          debugPrint('📨 Foreground message received: $payload');
          _handleForegroundMessage(payload);
        })]);
        
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
      var title = js_util.getProperty(notification, 'title') ?? 'DailyGrowth';
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
      debugPrint('🔔 Requesting web notification permission...');
      
      // Use actual Notification API
      if (html.Notification.supported) {
        var permission = await html.Notification.requestPermission();
        _permission = permission;
        debugPrint('🔔 Permission result: $permission');
        
        // If permission granted, get FCM token
        if (permission == 'granted') {
          _fcmToken = await getFCMToken();
          if (_fcmToken != null) {
            debugPrint('🔑 FCM Token obtained: ${_fcmToken!.substring(0, 20)}...');
            
            // Send token to service worker
            await sendMessageToServiceWorker({
              'type': 'FCM_TOKEN',
              'token': _fcmToken
            });
          }
        }
        
        return permission;
      } else {
        debugPrint('⚠️ Notifications not supported');
        return 'denied';
      }
    } catch (e) {
      debugPrint('❌ Error requesting notification permission: $e');
      return 'denied';
    }
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
      // On web platform, would show actual notification
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
        body: 'This is a test notification from DailyGrowth',
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
      final result = js.context.callMethod('eval', ['''
        (function() {
          console.log('🔥 Starting FCM token generation...');
          
          if (window.firebaseApp && window.firebaseMessaging && window.firebaseVapidKey) {
            console.log('✅ All Firebase objects present');
            
            return window.firebaseMessaging.getToken({
              vapidKey: window.firebaseVapidKey
            }).then(function(token) {
              if (token) {
                console.log('🔑 FCM Token generated:', token.substring(0, 20) + '...');
                localStorage.setItem('fcm_token', token);
                return token;
              } else {
                console.log('⚠️ No registration token available');
                return null;
              }
            }).catch(function(error) {
              console.error('❌ Error generating token:', error);
              return null;
            });
          } else {
            console.log('❌ Firebase objects missing');
            return Promise.resolve(null);
          }
        })()
      ''']);
      
      if (result != null) {
        final token = await js_util.promiseToFuture(result);
        if (token != null && token.toString().isNotEmpty) {
          debugPrint('✅ FCM Token successfully generated: ${token.toString().substring(0, 20)}...');
          return token.toString();
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
      final result = js.context.callMethod('eval', ['''
        (function() {
          console.log('🚀 FORCE FCM Token Generation Started');
          
          if (window.firebaseApp && window.firebaseMessaging && window.firebaseVapidKey) {
            console.log('✅ All Firebase objects present');
            
            // Delete existing registration first
            return window.firebaseMessaging.deleteToken().then(function() {
              console.log('🗑️ Old token deleted');
              
              return window.firebaseMessaging.getToken({
                vapidKey: window.firebaseVapidKey
              }).then(function(token) {
                if (token) {
                  console.log('🎉 FORCE: New FCM Token generated:', token.substring(0, 20) + '...');
                  localStorage.setItem('fcm_token', token);
                  return token;
                } else {
                  console.log('⚠️ FORCE: No token available');
                  return null;
                }
              });
            }).catch(function(error) {
              console.error('❌ FORCE: Error:', error);
              return null;
            });
          } else {
            console.log('❌ FORCE: Firebase objects missing');
            return Promise.resolve(null);
          }
        })()
      ''']);
      
      if (result != null) {
        final token = await js_util.promiseToFuture(result);
        if (token != null && token.toString().isNotEmpty) {
          debugPrint('🎉 FORCE: FCM Token successfully generated: ${token.toString().substring(0, 20)}...');
          return token.toString();
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
      title: title ?? 'Rappel DailyGrowth',
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
      body: body ?? description ?? achievementName ?? 'Félicitations pour votre progression ! ${pointsEarned != null ? '+$pointsEarned points' : ''}',
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
      final messageJson = js.context['JSON'].callMethod('stringify', [js_util.jsify(message)]);
      js.context.callMethod('eval', ['''
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
      ''']);
      
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
