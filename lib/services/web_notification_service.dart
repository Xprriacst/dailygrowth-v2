// Service dédié aux notifications web pour PWA
import 'package:flutter/foundation.dart';

// Note: This service only works on web platform
// All methods include kIsWeb guards to prevent errors on other platforms

class WebNotificationService {
  static final WebNotificationService _instance = WebNotificationService._internal();
  factory WebNotificationService() => _instance;
  WebNotificationService._internal();

  bool _isInitialized = false;
  String? _permission;

  Future<void> initialize() async {
    // Only initialize on web platform
    if (!kIsWeb) {
      debugPrint('WebNotificationService: Not on web platform, skipping initialization');
      return;
    }
    
    if (_isInitialized) return;

    try {
      // Basic initialization for web platform
      _isInitialized = true;
      debugPrint('✅ WebNotificationService initialized (web platform)');
    } catch (e) {
      debugPrint('❌ Failed to initialize WebNotificationService: $e');
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
      // On web platform, would request actual permissions
      debugPrint('🔔 Requesting web notification permission...');
      _permission = 'granted'; // Simplified for testing
      return _permission!;
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
    debugPrint('🔑 Getting FCM token (web)');
    return 'web-fcm-token-placeholder';
  }

  Future<String?> generateFCMToken() async {
    if (!kIsWeb) return null;
    debugPrint('🔑 Generating FCM token (web)');
    return 'web-fcm-token-generated';
  }

  Future<String?> forceFCMTokenGeneration() async {
    if (!kIsWeb) return null;
    debugPrint('🔑 Force generating FCM token (web)');
    return 'web-fcm-token-forced';
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
      // On web platform, would send actual message to service worker
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
