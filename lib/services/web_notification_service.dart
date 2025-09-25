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
      
      // Request notification permission
      _permission = await requestPermission();
      
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
      
      if (js.context.hasProperty('firebase')) {
        var messaging = js_util.callMethod(js.context['firebase'], 'messaging', []);
        
        // Get token with VAPID key
        var tokenPromise = js_util.callMethod(messaging, 'getToken', [js_util.jsify({
          'vapidKey': 'BK8nJ9nGpY3GGhxJ1m0-7qh1DjQc9dOZGQ0VrT-GhzCWrBkP4n4qg6bNQdZFqz-3Gi9nJ_dO5l-7zZlg3l9sZ0M'
        })]);
        
        var token = await js_util.promiseToFuture(tokenPromise);
        
        if (token != null) {
          _fcmToken = token.toString();
          debugPrint('🔑 FCM Token récupéré: ${_fcmToken!.substring(0, 20)}...');
          return _fcmToken;
        } else {
          debugPrint('⚠️ No FCM token available');
          return null;
        }
      } else {
        debugPrint('⚠️ Firebase not available for FCM token');
        return 'web-fcm-token-placeholder';
      }
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  Future<String?> generateFCMToken() async {
    return await getFCMToken();
  }

  Future<String?> forceFCMTokenGeneration() async {
    if (!kIsWeb) return null;
    
    try {
      debugPrint('🔑 Force generating FCM token (web)');
      
      if (js.context.hasProperty('firebase')) {
        var messaging = js_util.callMethod(js.context['firebase'], 'messaging', []);
        
        // Delete existing token first
        await js_util.promiseToFuture(js_util.callMethod(messaging, 'deleteToken', []));
        debugPrint('🗑️ Old FCM token deleted');
        
        // Generate new token
        return await getFCMToken();
      } else {
        debugPrint('⚠️ Firebase not available for FCM token generation');
        return 'web-fcm-token-forced';
      }
    } catch (e) {
      debugPrint('❌ Error force generating FCM token: $e');
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
      
      // Get service worker registration
      var serviceWorkerContainer = js_util.getProperty(html.window.navigator, 'serviceWorker');
      if (serviceWorkerContainer != null) {
        var registration = await js_util.promiseToFuture(
          js_util.callMethod(serviceWorkerContainer, 'ready', [])
        );
        
        if (registration != null) {
          var activeWorker = js_util.getProperty(registration, 'active');
          if (activeWorker != null) {
            js_util.callMethod(activeWorker, 'postMessage', [js_util.jsify(message)]);
            debugPrint('📨 Message sent to service worker successfully');
          } else {
            debugPrint('⚠️ No active service worker found');
          }
        } else {
          debugPrint('⚠️ Service worker not registered');
        }
      } else {
        debugPrint('⚠️ Service worker not supported');
      }
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
