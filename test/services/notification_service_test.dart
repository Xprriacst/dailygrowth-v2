import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dailygrowth/services/notification_service.dart';
import 'package:dailygrowth/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Generate mocks with: flutter packages pub run build_runner build
@GenerateMocks([
  FlutterLocalNotificationsPlugin,
  SupabaseClient,
  PostgrestQueryBuilder,
  PostgrestFilterBuilder,
])
import 'notification_service_test.mocks.dart';

void main() {
  group('NotificationService Tests', () {
    late NotificationService notificationService;
    late MockFlutterLocalNotificationsPlugin mockNotificationPlugin;
    late MockSupabaseClient mockSupabaseClient;
    late MockPostgrestQueryBuilder mockQueryBuilder;
    late MockPostgrestFilterBuilder mockFilterBuilder;

    setUp(() {
      mockNotificationPlugin = MockFlutterLocalNotificationsPlugin();
      mockSupabaseClient = MockSupabaseClient();
      mockQueryBuilder = MockPostgrestQueryBuilder();
      mockFilterBuilder = MockPostgrestFilterBuilder();
      notificationService = NotificationService();
    });

    group('Notification Scheduling', () {
      test('should schedule daily notification successfully', () async {
        // Arrange
        const userId = 'user123';
        const time = '09:00:00';
        const title = 'Daily Reminder';
        const body = 'Your daily challenge awaits!';

        when(mockNotificationPlugin.zonedSchedule(
          any,
          any,
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
          payload: anyNamed('payload'),
        )).thenAnswer((_) async => {});

        // Act & Assert
        expect(() async => await notificationService.scheduleDailyNotification(
          userId: userId,
          time: time,
          title: title,
          body: body,
        ), returnsNormally);
      });

      test('should send instant notification', () async {
        // Arrange
        const title = 'Test Notification';
        const body = 'Test message';
        const payload = 'test_payload';

        when(mockNotificationPlugin.show(
          any,
          any,
          any,
          any,
          payload: anyNamed('payload'),
        )).thenAnswer((_) async => {});

        // Act & Assert
        expect(() async => await notificationService.sendInstantNotification(
          title: title,
          body: body,
          payload: payload,
        ), returnsNormally);
      });
    });

    group('Notification Settings', () {
      test('should update notification settings successfully', () async {
        // Arrange
        const userId = 'user123';
        const notificationTime = '10:00:00';
        const notificationsEnabled = true;
        const reminderEnabled = false;

        // Mock Supabase update
        when(mockSupabaseClient.from('user_profiles')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.update(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenAnswer((_) async => {});

        // Mock notification cancellation and scheduling
        when(mockNotificationPlugin.cancel(any)).thenAnswer((_) async => {});
        when(mockNotificationPlugin.zonedSchedule(
          any, any, any, any, any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
          payload: anyNamed('payload'),
        )).thenAnswer((_) async => {});

        // Act & Assert
        expect(() async => await notificationService.updateNotificationSettings(
          userId: userId,
          notificationTime: notificationTime,
          notificationsEnabled: notificationsEnabled,
          reminderNotificationsEnabled: reminderEnabled,
        ), returnsNormally);
      });

      test('should get user notification settings', () async {
        // Arrange
        const userId = 'user123';
        final mockSettings = {
          'notification_time': '09:00:00',
          'notifications_enabled': true,
          'reminder_notifications_enabled': false,
        };

        when(mockSupabaseClient.from('user_profiles')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => mockSettings);

        // Act
        final settings = await notificationService.getUserNotificationSettings(userId);

        // Assert
        expect(settings, isNotNull);
        expect(settings!['notification_time'], equals('09:00:00'));
        expect(settings['notifications_enabled'], isTrue);
      });
    });

    group('Notification Cancellation', () {
      test('should cancel user notifications', () async {
        // Arrange
        const userId = 'user123';

        when(mockNotificationPlugin.cancel(any)).thenAnswer((_) async => {});

        // Act & Assert
        expect(() async => await notificationService.cancelUserNotifications(userId),
               returnsNormally);
      });
    });

    group('Debug Functions', () {
      test('should check scheduled notifications', () async {
        // Arrange
        final mockPendingNotifications = [
          PendingNotificationRequest(
            id: 1,
            title: 'Test Notification',
            body: 'Test Body',
            payload: 'test_payload',
          ),
        ];

        when(mockNotificationPlugin.pendingNotificationRequests())
            .thenAnswer((_) async => mockPendingNotifications);

        // Act & Assert
        expect(() async => await notificationService.debugScheduledNotifications(),
               returnsNormally);
      });

      test('should trigger test notification and return diagnostic message', () async {
        // Arrange
        when(mockNotificationPlugin.show(any, any, any, any, payload: anyNamed('payload')))
            .thenAnswer((_) async => {});

        // Act
        final result = await notificationService.triggerTestNotification();

        // Assert
        expect(result, isA<String>());
        expect(result.contains('Plateforme:'), isTrue);
      });
    });

    group('Achievement Notifications', () {
      test('should send achievement notification', () async {
        // Arrange
        const userId = 'user123';
        const achievementName = 'First Challenge';
        const description = 'Completed your first challenge!';
        const pointsEarned = 10;

        when(mockNotificationPlugin.show(any, any, any, any, payload: anyNamed('payload')))
            .thenAnswer((_) async => {});

        // Act & Assert
        expect(() async => await notificationService.sendAchievementNotification(
          userId: userId,
          achievementName: achievementName,
          description: description,
          pointsEarned: pointsEarned,
        ), returnsNormally);
      });

      test('should send streak milestone notification', () async {
        // Arrange
        const userId = 'user123';
        const streakCount = 7;

        when(mockNotificationPlugin.show(any, any, any, any, payload: anyNamed('payload')))
            .thenAnswer((_) async => {});

        // Act & Assert
        expect(() async => await notificationService.sendStreakMilestoneNotification(
          userId: userId,
          streakCount: streakCount,
        ), returnsNormally);
      });
    });
  });
}
