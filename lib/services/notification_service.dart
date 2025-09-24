import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cron/cron.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

import './supabase_service.dart';
import './challenge_service.dart';
import './quote_service.dart';
import './user_service.dart';
import './web_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;
  final Cron _cron = Cron();
  bool _isInitialized = false;
  bool _timeZonesInitialized = false;

  Future<void> _ensureTimeZones() async {
    if (_timeZonesInitialized) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Paris'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    _timeZonesInitialized = true;
  }

  // Services
  final ChallengeService _challengeService = ChallengeService();
  final QuoteService _quoteService = QuoteService();
  final UserService _userService = UserService();
  final WebNotificationService _webNotificationService = WebNotificationService();

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize for mobile platforms
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await _ensureTimeZones();
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

    // Initialize web notifications for web platforms
    if (kIsWeb) {
      await _webNotificationService.initialize();
    }

    // Initialize services (defer Supabase-dependent services)
    try {
      await _challengeService.initialize();
      await _quoteService.initialize();
      await _userService.initialize();
    } catch (e) {
      print('⚠️ Warning: Some services failed to initialize: $e');
    }

    // Setup daily notifications (will work without Supabase for local notifications)
    _setupDailyNotifications();

    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {

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
    // For web, use service worker scheduling
    if (kIsWeb) {
      await _scheduleWebNotification(userId, time, title, body);
      return;
    }
    
    if (_flutterLocalNotificationsPlugin == null) return;

    try {
      await _ensureTimeZones();
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
    // Use web notifications for web platforms
    if (kIsWeb) {
      await _webNotificationService.showNotification(
        title: title,
        body: body,
        data: payload != null ? {'payload': payload} : null,
      );
      return;
    }
    
    if (_flutterLocalNotificationsPlugin == null) return;

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

  // Setup automated daily notifications (no content generation)
  void _setupDailyNotifications() {
    // Note: Daily notifications are now scheduled individually per user
    // when they update their settings, not via a global cron job
    debugPrint('📅 Daily notifications setup - individual scheduling per user');
    
    // Initialize existing user notifications if any
    _initializeExistingNotifications();
  }

  // Initialize notifications for current user if they have settings
  Future<void> _initializeExistingNotifications() async {
    try {
      final client = await SupabaseService().client;
      final user = client.auth.currentUser;
      
      if (user != null) {
        final settings = await getUserNotificationSettings(user.id);
        if (settings != null && settings['notifications_enabled'] == true) {
          final notificationTime = settings['notification_time'] as String? ?? '09:00:00';
          
          debugPrint('🔄 Reinitializing existing notifications for user ${user.id} at $notificationTime');
          
          // Reschedule the daily notification
          await scheduleDailyNotification(
            userId: user.id,
            time: notificationTime,
            title: '🎯 Votre défi quotidien vous attend !',
            body: 'Connectez-vous pour découvrir votre nouveau micro-défi personnalisé.',
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ Could not initialize existing notifications: $e');
    }
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
      // Use the new micro-challenge generation system
      final newChallenge = await _challengeService.generateTodayChallenge(
        userId: userId,
        lifeDomain: lifeDomain,
      );
      
      if (newChallenge != null) {
        debugPrint('✅ Daily micro-challenge generated for user $userId: ${newChallenge['nom']}');
        
        // Send notification about the new challenge
        await sendInstantNotification(
          title: '🎯 Nouveau micro-défi généré !',
          body: newChallenge['nom'] ?? 'Votre nouveau défi vous attend !',
          payload: 'new_challenge:$userId',
        );
      } else {
        debugPrint('⚠️ No new challenge generated for user $userId (may already exist for today)');
      }
    } catch (e) {
      debugPrint('Failed to generate micro-challenge for user $userId: $e');
      
      // Fallback to generic challenge creation
      await _challengeService.createChallenge(
          userId: userId,
          title: 'Moment de réflexion',
          description:
              'Prenez 10 minutes pour réfléchir à vos objectifs et notez une action concrète à réaliser aujourd\'hui.',
          lifeDomain: lifeDomain);
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

  // Note: _sendDailyReminders removed - now using native scheduled notifications
  // Each user gets their own scheduled notification when they update settings

  // Update user notification preferences
  Future<void> updateNotificationSettings({
    required String userId,
    required String notificationTime, // Format: "09:00:00"
    required bool notificationsEnabled,
    bool reminderNotificationsEnabled = false,
  }) async {
    try {
      final client = await SupabaseService().client;
      
      // Get FCM token if notifications are enabled and we're on web
      String? fcmToken;
      if (notificationsEnabled && kIsWeb) {
        try {
          final webNotificationService = WebNotificationService();
          fcmToken = await webNotificationService.getFCMToken();
          debugPrint('📱 FCM Token récupéré: ${fcmToken?.substring(0, 20)}...');
        } catch (e) {
          debugPrint('⚠️ Erreur récupération token FCM: $e');
        }
      }
      
      // Update profile with FCM token
      final updateData = {
        'notification_time': notificationTime,
        'notifications_enabled': notificationsEnabled,
        'reminder_notifications_enabled': reminderNotificationsEnabled,
      };
      
      if (fcmToken != null) {
        updateData['fcm_token'] = fcmToken;
      }
      
      await client
          .from('user_profiles')
          .update(updateData)
          .eq('id', userId);

      debugPrint('✅ Paramètres de notification mis à jour avec token FCM');

      // Cancel existing scheduled notifications
      await cancelUserNotifications(userId);
      
      // Schedule new daily notification if enabled
      if (notificationsEnabled) {
        await scheduleDailyNotification(
          userId: userId,
          time: notificationTime,
          title: '🎯 Votre défi quotidien vous attend !',
          body: 'Connectez-vous pour découvrir votre nouveau micro-défi personnalisé.',
        );
      }
      
      debugPrint('✅ Notification settings updated for user $userId');
    } catch (e) {
      debugPrint('❌ Failed to update notification settings: $e');
      throw e;
    }
  }

  // Get user notification settings
  Future<Map<String, dynamic>?> getUserNotificationSettings(String userId) async {
    try {
      final client = await SupabaseService().client;
      
      final response = await client
          .from('user_profiles')
          .select('notification_time, notifications_enabled, reminder_notifications_enabled')
          .eq('id', userId)
          .maybeSingle();
          
      return response;
    } catch (e) {
      debugPrint('❌ Failed to get notification settings: $e');
      return null;
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
    if (kIsWeb) {
      await _webNotificationService.showAchievementNotification(
        achievementName: achievementName,
        description: description,
        pointsEarned: pointsEarned,
      );
    } else {
      await sendInstantNotification(
          title: '🏆 Nouveau succès débloqué !',
          body: '$achievementName - $description (+$pointsEarned points)',
          payload: 'achievement:$userId');
    }
  }

  // Send streak milestone notification
  Future<void> sendStreakMilestoneNotification({
    required String userId,
    required int streakCount,
  }) async {
    if (kIsWeb) {
      await _webNotificationService.showStreakNotification(
        streakCount: streakCount,
      );
    } else {
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
  }

  // Generate and notify about new micro-challenge
  Future<void> generateAndNotifyNewMicroChallenge(String userId) async {
    try {
      debugPrint('🔄 Generating new micro-challenge for user: $userId');
      
      // Generate new micro-challenge using the challenge service
      final newChallenge = await _challengeService.generateTodayChallenge(
        userId: userId,
        lifeDomain: 'developpement',
      );
      
      if (newChallenge != null) {
        final challengeName = newChallenge['nom'] as String? ?? 'Nouveau défi';
        final challengeMission = newChallenge['mission'] as String? ?? '';
        
        debugPrint('✅ New micro-challenge generated: $challengeName');
        
        // Send notification about the new challenge
        if (kIsWeb) {
          await _webNotificationService.showChallengeNotification(
            challengeName: challengeName,
            challengeId: newChallenge['id']?.toString(),
          );
        } else {
          await sendInstantNotification(
            title: '🎯 Nouveau micro-défi disponible !',
            body: challengeName,
            payload: 'new_challenge:$userId',
          );
        }
        
        // Schedule reminder notification if enabled
        final settings = await getUserNotificationSettings(userId);
        if (settings != null && settings['reminder_notifications_enabled'] == true) {
          // Reminder functionality can be added here if needed
        }
        
      } else {
        debugPrint('⚠️ No new challenge generated for user $userId');
        
        // Send a motivational notification instead
        await sendInstantNotification(
          title: '💪 Continuez votre progression !',
          body: 'Votre défi d\'aujourd\'hui vous attend dans l\'application.',
          payload: 'reminder:$userId',
        );
      }
    } catch (e) {
      debugPrint('❌ Error generating micro-challenge for user $userId: $e');
      
      // Send error notification
      await sendInstantNotification(
        title: '🔄 Nouveau contenu en préparation',
        body: 'Votre défi personnalisé sera bientôt disponible !',
        payload: 'error:$userId',
      );
    }
  }

  // Schedule web notification using service worker for persistence
  Future<void> _scheduleWebNotification(String userId, String time, String title, String body) async {
    debugPrint('📅 Scheduling persistent web notification for $time');
    
    try {
      // Send to service worker for persistent scheduling
      await _webNotificationService.sendMessageToServiceWorker({
        'type': 'SCHEDULE_NOTIFICATION',
        'userId': userId,
        'time': time,
        'title': title,
        'body': body,
      });
      
      debugPrint('✅ Notification scheduled in service worker - will trigger daily at $time');
      debugPrint('ℹ️ No need to keep app open - service worker handles it');
      
    } catch (e) {
      debugPrint('❌ Failed to schedule web notification: $e');
    }
  }

  // Debug: Check scheduled notifications
  Future<void> debugScheduledNotifications() async {
    if (kIsWeb) {
      debugPrint('📱 Web: Scheduled notifications handled by service worker');
      return;
    }
    
    if (_flutterLocalNotificationsPlugin == null) {
      debugPrint('❌ Notification plugin not initialized');
      return;
    }

    try {
      final pendingNotifications = await _flutterLocalNotificationsPlugin!.pendingNotificationRequests();
      debugPrint('📅 Scheduled notifications count: ${pendingNotifications.length}');
      
      for (final notification in pendingNotifications) {
        debugPrint('📅 Notification ID: ${notification.id}, Title: ${notification.title}, Body: ${notification.body}');
      }
    } catch (e) {
      debugPrint('❌ Error checking scheduled notifications: $e');
    }
  }

  // Test notification for debugging avec diagnostic iOS dans l'UI
  Future<String> triggerTestNotification() async {
    String diagnosticMessage = '';
    
    if (kIsWeb) {
      diagnosticMessage += '🌐 Plateforme: Web\n';
      
      // Diagnostic iOS détaillé
      try {
        final userAgent = kIsWeb ? 'Web Platform' : 'Mobile Platform';
        // Simulation du diagnostic iOS pour l'interface
        if (kIsWeb) {
          diagnosticMessage += '📱 Diagnostic iOS:\n';
          diagnosticMessage += '• Plateforme: Web (Safari/Chrome)\n';
          diagnosticMessage += '• Support notifications: Oui\n';
        }
      } catch (e) {
        diagnosticMessage += '❌ Erreur diagnostic: $e\n';
      }
      
      // Check permission status first
      final permission = _webNotificationService.permissionStatus;
      diagnosticMessage += '🔔 Permissions: $permission\n';
      
      // First request permissions if needed
      if (permission != 'granted') {
        diagnosticMessage += '⚠️ Demande de permissions...\n';
        final newPermission = await _webNotificationService.requestPermission();
        diagnosticMessage += '🔔 Nouvelles permissions: $newPermission\n';
        
        if (newPermission != 'granted') {
          diagnosticMessage += '\n❌ PROBLÈME DÉTECTÉ:\n';
          diagnosticMessage += '• Permissions refusées\n';
          diagnosticMessage += '\n💡 SOLUTION iOS:\n';
          diagnosticMessage += '1. Safari → Partager\n';
          diagnosticMessage += '2. "Ajouter à l\'écran d\'accueil"\n';
          diagnosticMessage += '3. Ouvrir depuis l\'icône PWA\n';
          diagnosticMessage += '4. Réessayer le test\n';
          throw Exception(diagnosticMessage);
        }
      }

      diagnosticMessage += '\n🔧 DEBUG TOKEN FCM:\n';
      
      // Now that we have permissions, try to get/generate FCM token
      try {
        // First try to get existing token
        var fcmToken = await _webNotificationService.getFCMToken();
        
        if (fcmToken == null) {
          diagnosticMessage += '🔍 Permissions OK, génération du token FCM...\n';
          
          // Try to generate FCM token via JavaScript - now that we have permissions
          fcmToken = await _webNotificationService.generateFCMToken();
        }
        
        if (fcmToken != null && fcmToken.isNotEmpty) {
          diagnosticMessage += '🔑 Token FCM: ${fcmToken.substring(0, 20)}...${fcmToken.substring(fcmToken.length - 10)}\n';
          diagnosticMessage += '📋 Token complet disponible dans la console\n';
          debugPrint('🔑 FCM Token complet: $fcmToken');
          
          // Auto-save token to database
          try {
            await _userService.updateFCMToken(fcmToken);
            diagnosticMessage += '✅ Token sauvegardé en base de données\n';
          } catch (e) {
            diagnosticMessage += '⚠️ Erreur sauvegarde token: $e\n';
            debugPrint('❌ Erreur sauvegarde token: $e');
          }
        } else {
          diagnosticMessage += '⚠️ IMPOSSIBLE DE GÉNÉRER LE TOKEN FCM\n';
          diagnosticMessage += '💡 Vérifiez la console pour plus de détails\n';
          diagnosticMessage += '🔍 Debug: fcmToken = ${fcmToken.toString()}\n';
          
          // Try the FORCE method as fallback
          diagnosticMessage += '\n🔧 FORCE: Tentative de génération forcée...\n';
          try {
            final forceToken = await _webNotificationService.forceFCMTokenGeneration();
            if (forceToken != null && forceToken.isNotEmpty) {
              diagnosticMessage += '🎉 FORCE: Token généré avec succès!\n';
              diagnosticMessage += '🔑 Token FCM: ${forceToken.substring(0, 20)}...${forceToken.substring(forceToken.length - 10)}\n';
              
              // Auto-save forced token to database
              try {
                await _userService.updateFCMToken(forceToken);
                diagnosticMessage += '✅ FORCE: Token sauvegardé en base de données\n';
              } catch (e) {
                diagnosticMessage += '⚠️ FORCE: Erreur sauvegarde token: $e\n';
              }
            } else {
              diagnosticMessage += '❌ FORCE: Échec de la génération forcée\n';
              diagnosticMessage += '\n🔧 SOLUTION MANUELLE:\n';
              diagnosticMessage += '1. Ouvrez la console développeur (F12)\n';
              diagnosticMessage += '2. Cherchez les erreurs Firebase\n';
              diagnosticMessage += '3. Vérifiez si window.firebaseMessaging existe\n';
            }
          } catch (e) {
            diagnosticMessage += '❌ FORCE: Erreur génération forcée: $e\n';
          }
        }
      } catch (e) {
        diagnosticMessage += '❌ Erreur récupération token: $e\n';
        debugPrint('❌ Erreur FCM Token: $e');
      }
      
      diagnosticMessage += '\n✅ TESTS RÉALISÉS:\n';
      
      // Check scheduled notifications first
      await debugScheduledNotifications();
      
      // Test basic notification
      try {
        await _webNotificationService.showNotification(
          title: '🧪 Test DailyGrowth',
          body: 'Notification de test réussie !',
          data: {'test': true, 'timestamp': DateTime.now().millisecondsSinceEpoch},
        );
        diagnosticMessage += '• Notification immédiate: ✅\n';
      } catch (e) {
        diagnosticMessage += '• Notification immédiate: ❌ $e\n';
      }
      
      // Test challenge notification
      try {
        await Future.delayed(const Duration(seconds: 1));
        await _webNotificationService.showChallengeNotification(
          challengeName: 'Test: Sourire à 3 personnes',
        );
        diagnosticMessage += '• Notification défi: ✅\n';
      } catch (e) {
        diagnosticMessage += '• Notification défi: ❌ $e\n';
      }
      
      // Test de notification programmée
      try {
        final testTime = DateTime.now().add(const Duration(minutes: 1));
        final timeString = '${testTime.hour.toString().padLeft(2, '0')}:${testTime.minute.toString().padLeft(2, '0')}:00';
        
        await _scheduleWebNotification(
          'test_user',
          timeString,
          '⏰ Test Programmé',
          'Notification programmée pour ${testTime.hour}:${testTime.minute}'
        );
        diagnosticMessage += '• Notification programmée (${testTime.hour}:${testTime.minute}): ✅\n';
      } catch (e) {
        diagnosticMessage += '• Notification programmée: ❌ $e\n';
      }
      
      diagnosticMessage += '\n🎯 RÉSULTAT:\n';
      diagnosticMessage += 'Tests terminés avec succès !\n';
      diagnosticMessage += 'Attendez 1 minute pour la notification programmée.';
      
    } else {
      diagnosticMessage += '📱 Plateforme: Mobile\n';
      
      // Check scheduled notifications
      await debugScheduledNotifications();
      
      try {
        await sendInstantNotification(
          title: '🧪 Test DailyGrowth',
          body: 'Test mobile réussi !',
          payload: 'test_notification',
        );
        diagnosticMessage += '✅ Notification mobile envoyée\n';
        diagnosticMessage += 'Vérifiez les logs pour les notifications programmées';
      } catch (e) {
        diagnosticMessage += '❌ Erreur mobile: $e';
      }
    }
    
    return diagnosticMessage;
  }

  // Schedule optional reminder notification for later in the day
  Future<void> _scheduleOptionalReminder(String userId, String userName) async {
    // For web, use immediate reminder (no scheduling support)
    if (kIsWeb) {
      // Schedule a delayed reminder using Future.delayed
      Future.delayed(const Duration(hours: 6), () async {
        await _webNotificationService.showReminderNotification(
          userName: userName,
        );
      });
      return;
    }
    
    if (_flutterLocalNotificationsPlugin == null) return;
    
    try {
      await _ensureTimeZones();
      // Schedule reminder 6 hours later
      final reminderTime = DateTime.now().add(const Duration(hours: 6));
      
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
              'challenge_reminders', 'Challenge Reminders',
              channelDescription: 'Optional reminders about daily challenges',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority);

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics);

      await _flutterLocalNotificationsPlugin!.zonedSchedule(
          '${userId}_reminder'.hashCode,
          '⏰ N\'oubliez pas votre défi !',
          'Votre micro-défi personnalisé vous attend toujours dans l\'application.',
          tz.TZDateTime.from(reminderTime, tz.local),
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'reminder:$userId');
          
      debugPrint('📅 Optional reminder scheduled for $reminderTime for user $userName');
    } catch (e) {
      debugPrint('Failed to schedule optional reminder notification: $e');
    }
  }

  // Cancel all notifications for a user
  Future<void> cancelUserNotifications(String userId) async {
    // For web, clear notifications via service worker
    if (kIsWeb) {
      await _webNotificationService.sendMessageToServiceWorker({
        'type': 'CANCEL_NOTIFICATION',
        'userId': userId,
      });
      await _webNotificationService.clearAllNotifications();
      return;
    }
    
    if (_flutterLocalNotificationsPlugin == null) return;

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
