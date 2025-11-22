// Service dédié aux notifications push iOS avec Firebase Cloud Messaging
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import './user_service.dart';

// Note: This service only works on iOS native platform
// All methods include Platform.isIOS guards to prevent errors on other platforms

// Top-level function for background message handler (required by Firebase)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📨 Background notification received: ${message.notification?.title}');
  debugPrint('📨 Background notification data: ${message.data}');
  
  // Background notifications are automatically displayed by iOS
  // No need to show local notification here
}

class IOSPushNotificationService {
  static final IOSPushNotificationService _instance =
      IOSPushNotificationService._internal();
  factory IOSPushNotificationService() => _instance;
  IOSPushNotificationService._internal();

  FirebaseMessaging? _messaging;
  FlutterLocalNotificationsPlugin? _localNotifications;
  bool _isInitialized = false;
  String? _fcmToken;

  Future<void> initialize() async {
    // Only initialize on iOS native platform
    if (!Platform.isIOS || kIsWeb) {
      debugPrint(
          'IOSPushNotificationService: Not on iOS native platform, skipping initialization');
      return;
    }

    if (_isInitialized) return;

    try {
      _messaging = FirebaseMessaging.instance;

      // Request permissions
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('✅ iOS Push Notifications: Permissions granted');

        // Initialize local notifications for foreground display
        await _initializeLocalNotifications();

        // Get FCM token
        await _getAndSaveToken();

        // Setup handlers
        _setupForegroundHandler();
        _setupBackgroundHandler();
        _setupTokenRefreshHandler();

        _isInitialized = true;
        debugPrint('✅ IOSPushNotificationService initialized successfully');
      } else {
        debugPrint('❌ iOS Push Notifications: Permissions denied (status: ${settings.authorizationStatus})');
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize iOS Push: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    _localNotifications = FlutterLocalNotificationsPlugin();

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true);

    const InitializationSettings initializationSettings =
        InitializationSettings(iOS: initializationSettingsIOS);

    await _localNotifications!.initialize(initializationSettings);
  }

  Future<void> _getAndSaveToken() async {
    try {
      _fcmToken = await _messaging!.getToken();
      if (_fcmToken != null) {
        debugPrint('🔑 FCM Token iOS: ${_fcmToken!.substring(0, 20)}...');
        await _saveTokenToDatabase(_fcmToken!);
      } else {
        debugPrint('⚠️ FCM Token is null');
      }
    } catch (e) {
      debugPrint('❌ Failed to get FCM token: $e');
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    try {
      await UserService().updateFCMToken(token);
      debugPrint('✅ FCM Token saved to database');
    } catch (e) {
      debugPrint('❌ Failed to save FCM token to database: $e');
    }
  }

  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📨 Foreground notification: ${message.notification?.title}');
      debugPrint('📨 Foreground notification data: ${message.data}');

      // iOS doesn't automatically show notifications in foreground
      // So we display a local notification
      if (message.notification != null && _localNotifications != null) {
        _showLocalNotification(
          title: message.notification!.title ?? 'Notification',
          body: message.notification!.body ?? '',
          payload: message.data.toString(),
        );
      }
    });
  }

  void _setupBackgroundHandler() {
    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  void _setupTokenRefreshHandler() {
    _messaging!.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM Token refreshed: ${newToken.substring(0, 20)}...');
      _fcmToken = newToken;
      _saveTokenToDatabase(newToken);
    });
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (_localNotifications == null) return;

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
        iOS: iOSPlatformChannelSpecifics);

    await _localNotifications!.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Public method to get current FCM token
  Future<String?> getFCMToken() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _fcmToken;
  }

  // Public method to request permissions manually
  Future<bool> requestPermissions() async {
    if (!Platform.isIOS || kIsWeb) return false;

    try {
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await _getAndSaveToken();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Failed to request permissions: $e');
      return false;
    }
  }

  bool get isInitialized => _isInitialized;
  String? get fcmToken => _fcmToken;
}



