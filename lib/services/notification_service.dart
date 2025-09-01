import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cron/cron.dart';
import 'package:timezone/timezone.dart' as tz;

import './supabase_service.dart';
import './challenge_service.dart';
import './quote_service.dart';
import './user_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;
  final Cron _cron = Cron();
  bool _isInitialized = false;

  // Services
  final ChallengeService _challengeService = ChallengeService();
  final QuoteService _quoteService = QuoteService();
  final UserService _userService = UserService();

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize for mobile platforms only
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
              requestAlertPermission: true,
              requestBadgePermission: true,
              requestSoundPermission: true);

      final InitializationSettings initializationSettings =
          InitializationSettings(
              android: initializationSettingsAndroid,
              iOS: initializationSettingsIOS);

      await _flutterLocalNotificationsPlugin!.initialize(initializationSettings,
          onDidReceiveNotificationResponse: _onNotificationTapped);

      // Request permissions
      await _requestPermissions();
    }

    // Initialize services
    await _challengeService.initialize();
    await _quoteService.initialize();
    await _userService.initialize();

    // Setup daily content generation
    _setupDailyContentGeneration();

    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) return;

    if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin!
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
    }

    if (Platform.isIOS) {
      await _flutterLocalNotificationsPlugin!
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    // Handle notification tap
    debugPrint('Notification tapped: ${notificationResponse.payload}');
  }

  // Schedule daily notifications for users
  Future<void> scheduleDailyNotification({
    required String userId,
    required String time, // Format: "09:00:00"
    required String title,
    required String body,
  }) async {
    if (kIsWeb || _flutterLocalNotificationsPlugin == null) return;

    try {
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails('daily_reminders', 'Daily Reminders',
              channelDescription: 'Daily growth reminders and challenges',
              importance: Importance.high,
              priority: Priority.high);

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics);

      await _flutterLocalNotificationsPlugin!.zonedSchedule(
          userId.hashCode, // Use user ID hash as notification ID
          title,
          body,
          _nextInstanceOfTime(hour, minute),
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: userId);
    } catch (e) {
      debugPrint('Failed to schedule daily notification: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // Send instant notification
  Future<void> sendInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb || _flutterLocalNotificationsPlugin == null) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'instant_notifications', 'Instant Notifications',
            channelDescription: 'Instant app notifications',
            importance: Importance.high,
            priority: Priority.high);

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin!.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platformChannelSpecifics,
        payload: payload);
  }

  // Setup automated daily content generation
  void _setupDailyContentGeneration() {
    // Generate content every day at 6 AM
    _cron.schedule(Schedule.parse('0 6 * * *'), () async {
      await _generateDailyContentForAllUsers();
    });

    // Send daily reminders at users' preferred times
    _cron.schedule(Schedule.parse('0 * * * *'), () async {
      await _sendDailyReminders();
    });
  }

  Future<void> _generateDailyContentForAllUsers() async {
    try {
      final client = await SupabaseService().client;

      // Get all active users
      final usersResponse = await client
          .from('user_profiles')
          .select('id, selected_life_domains')
          .eq('status', 'active');

      final users = List<Map<String, dynamic>>.from(usersResponse);

      for (final user in users) {
        final userId = user['id'] as String;
        final selectedDomains =
            user['selected_life_domains'] as List<dynamic>? ?? ['sante'];
        final primaryDomain =
            selectedDomains.isNotEmpty ? selectedDomains.first : 'sante';

        // Check if user already has content for today
        final today = DateTime.now().toIso8601String().split('T')[0];

        final existingChallenge =
            await _challengeService.getTodayChallenge(userId);
        final existingQuote = await _quoteService.getTodayQuote(userId);

        // Generate challenge if doesn't exist
        if (existingChallenge == null) {
          await _generateDailyChallengeForUser(userId, primaryDomain);
        }

        // Generate quote if doesn't exist
        if (existingQuote == null) {
          await _generateDailyQuoteForUser(userId, primaryDomain);
        }
      }
    } catch (e) {
      debugPrint('Failed to generate daily content: $e');
    }
  }

  Future<void> _generateDailyChallengeForUser(
      String userId, String lifeDomain) async {
    try {
      // Use challenge service fallback directly
      await _challengeService.createChallenge(
          userId: userId,
          title: 'Moment de réflexion',
          description:
              'Prenez 10 minutes pour réfléchir à vos objectifs et notez une action concrète à réaliser aujourd\'hui.',
          lifeDomain: lifeDomain);
      debugPrint('✅ Daily challenge generated for user $userId');
    } catch (e) {
      debugPrint('Failed to generate challenge for user $userId: $e');
    }
  }

  Future<void> _generateDailyQuoteForUser(
      String userId, String lifeDomain) async {
    try {
      // Use quote service fallback directly
      final generatedQuote = await _quoteService.generateTodaysQuote(
          userId: userId, lifeDomain: lifeDomain);

      // Quote is already saved by the service
      debugPrint('✅ Daily quote generated for user $userId');
    } catch (e) {
      debugPrint('Failed to generate quote for user $userId: $e');
    }
  }

  Future<void> _sendDailyReminders() async {
    try {
      final client = await SupabaseService().client;
      final currentHour = DateTime.now().hour;

      // Get users who should receive notifications at this hour
      final usersResponse = await client
          .from('user_profiles')
          .select('id, full_name, notification_time, notifications_enabled')
          .eq('status', 'active')
          .eq('notifications_enabled', true);

      final users = List<Map<String, dynamic>>.from(usersResponse);

      for (final user in users) {
        final notificationTime =
            user['notification_time'] as String? ?? '09:00:00';
        final notificationHour = int.parse(notificationTime.split(':')[0]);

        if (notificationHour == currentHour) {
          await sendInstantNotification(
              title: 'Votre défi quotidien vous attend !',
              body:
                  'Bonjour ${user['full_name']}, découvrez votre nouveau défi pour grandir aujourd\'hui.',
              payload: user['id']);
        }
      }
    } catch (e) {
      debugPrint('Failed to send daily reminders: $e');
    }
  }

  // Email notifications using Supabase Edge Functions or external service
  Future<void> sendEmailNotification({
    required String recipientEmail,
    required String subject,
    required String htmlContent,
    String? textContent,
  }) async {
    try {
      // In a production app, you would use Supabase Edge Functions
      // or a service like Resend, SendGrid, etc.
      // For now, we'll use a simple HTTP request to a hypothetical endpoint

      final client = await SupabaseService().client;

      // Call Supabase Edge Function for email sending
      await client.functions.invoke('send-email', body: {
        'to': recipientEmail,
        'subject': subject,
        'html': htmlContent,
        'text': textContent ?? '',
      });
    } catch (e) {
      debugPrint('Failed to send email notification: $e');
      // Fallback to local notification if email fails
      await sendInstantNotification(
          title: subject,
          body: textContent ?? 'Vous avez une nouvelle notification.');
    }
  }

  // Send achievement notification
  Future<void> sendAchievementNotification({
    required String userId,
    required String achievementName,
    required String description,
    required int pointsEarned,
  }) async {
    await sendInstantNotification(
        title: '🏆 Nouveau succès débloqué !',
        body: '$achievementName - $description (+$pointsEarned points)',
        payload: 'achievement:$userId');
  }

  // Send streak milestone notification
  Future<void> sendStreakMilestoneNotification({
    required String userId,
    required int streakCount,
  }) async {
    String title = '';
    String body = '';

    if (streakCount == 7) {
      title = '🔥 Série de 7 jours !';
      body =
          'Incroyable ! Vous avez maintenu votre série pendant une semaine entière !';
    } else if (streakCount == 30) {
      title = '🌟 Série de 30 jours !';
      body = 'Extraordinaire ! Un mois complet de croissance personnelle !';
    } else if (streakCount == 100) {
      title = '💎 Série de 100 jours !';
      body = 'Légendaire ! Vous êtes un véritable champion de la croissance !';
    } else if (streakCount % 10 == 0) {
      title = '🚀 Série de $streakCount jours !';
      body = 'Fantastique ! Continuez sur cette belle lancée !';
    }

    if (title.isNotEmpty) {
      await sendInstantNotification(
          title: title, body: body, payload: 'streak:$userId');
    }
  }

  // Cancel all notifications for a user
  Future<void> cancelUserNotifications(String userId) async {
    if (kIsWeb || _flutterLocalNotificationsPlugin == null) return;

    await _flutterLocalNotificationsPlugin!.cancel(userId.hashCode);
  }

  // Helper methods
  String _getLifeDomainName(String domain) {
    const translations = {
      'sante': 'santé et bien-être',
      'relations': 'relations et amour',
      'carriere': 'carrière et travail',
      'finances': 'finances et argent',
      'developpement': 'développement personnel',
      'spiritualite': 'spiritualité et sens',
      'loisirs': 'loisirs et passions',
      'famille': 'famille et proches',
    };
    return translations[domain] ?? 'développement personnel';
  }

  Map<String, Map<String, String>> _getFallbackQuotes() {
    return {
      'sante': {
        'quote':
            'Prendre soin de son corps, c\'est prendre soin de son esprit.',
        'author': 'Proverbe ancien'
      },
      'relations': {
        'quote':
            'Les relations authentiques sont le véritable trésor de la vie.',
        'author': 'Maya Angelou'
      },
      'carriere': {
        'quote':
            'Le succès, c\'est d\'aller d\'échec en échec sans perdre son enthousiasme.',
        'author': 'Winston Churchill'
      },
      'finances': {
        'quote':
            'Ce n\'est pas combien d\'argent vous gagnez, mais combien vous gardez.',
        'author': 'Robert Kiyosaki'
      },
      'developpement': {
        'quote': 'La croissance commence là où finit votre zone de confort.',
        'author': 'Robin Sharma'
      },
      'spiritualite': {
        'quote':
            'La paix vient de l\'intérieur. Ne la cherchez pas à l\'extérieur.',
        'author': 'Bouddha'
      },
      'loisirs': {
        'quote': 'Le jeu est la forme la plus élevée de la recherche.',
        'author': 'Albert Einstein'
      },
      'famille': {
        'quote': 'La famille est le premier lieu où nous apprenons à aimer.',
        'author': 'Anonyme'
      },
    };
  }

  void dispose() {
    _cron.close();
  }
}
