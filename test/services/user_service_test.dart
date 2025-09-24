import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dailygrowth/services/user_service.dart';
import 'package:dailygrowth/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Generate mocks with: flutter packages pub run build_runner build
@GenerateMocks([
  SupabaseClient,
  PostgrestQueryBuilder,
  PostgrestFilterBuilder,
  GoTrueClient,
  User,
])
import 'user_service_test.mocks.dart';

void main() {
  group('UserService Tests', () {
    late UserService userService;
    late MockSupabaseClient mockSupabaseClient;
    late MockPostgrestQueryBuilder mockQueryBuilder;
    late MockPostgrestFilterBuilder mockFilterBuilder;
    late MockGoTrueClient mockGoTrueClient;
    late MockUser mockUser;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockQueryBuilder = MockPostgrestQueryBuilder();
      mockFilterBuilder = MockPostgrestFilterBuilder();
      mockGoTrueClient = MockGoTrueClient();
      mockUser = MockUser();
      userService = UserService();

      // Setup default mocks
      when(mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
      when(mockSupabaseClient.from('user_profiles')).thenReturn(mockQueryBuilder);
    });

    group('User Profile Management', () {
      test('should get user profile successfully', () async {
        // Arrange
        const userId = 'user123';
        final mockProfile = {
          'id': userId,
          'full_name': 'John Doe',
          'email': 'john@example.com',
          'selected_problematiques': ['devenir plus charismatique'],
          'notifications_enabled': true,
          'notification_time': '09:00:00',
        };

        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => mockProfile);

        // Act
        final result = await userService.getUserProfile(userId);

        // Assert
        expect(result, isNotNull);
        expect(result!['full_name'], equals('John Doe'));
        expect(result['selected_problematiques'], isA<List>());
      });

      test('should update user profile successfully', () async {
        // Arrange
        const userId = 'user123';
        final updateData = {
          'full_name': 'Jane Doe',
          'selected_problematiques': ['lâcher-prise', 'développer revenus'],
        };

        when(mockQueryBuilder.update(updateData)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenAnswer((_) async => {});

        // Act & Assert
        expect(() async => await userService.updateUserProfile(userId, updateData),
               returnsNormally);
      });

      test('should create user profile on first login', () async {
        // Arrange
        const userId = 'newuser123';
        const email = 'newuser@example.com';
        const fullName = 'New User';
        
        final profileData = {
          'id': userId,
          'email': email,
          'full_name': fullName,
          'selected_problematiques': <String>[],
          'notifications_enabled': true,
          'notification_time': '09:00:00',
          'reminder_notifications_enabled': false,
        };

        when(mockQueryBuilder.insert(profileData)).thenAnswer((_) async => {});

        // Act & Assert
        expect(() async => await userService.createUserProfile(
          userId: userId,
          email: email,
          fullName: fullName,
        ), returnsNormally);
      });
    });

    group('Problematiques Management', () {
      test('should update selected problematiques', () async {
        // Arrange
        const userId = 'user123';
        final selectedProblematiques = [
          'devenir plus charismatique',
          'développer mon réseau',
          'lâcher-prise'
        ];

        when(mockQueryBuilder.update({'selected_problematiques': selectedProblematiques}))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenAnswer((_) async => {});

        // Act & Assert
        expect(() async => await userService.updateSelectedProblematiques(
          userId, selectedProblematiques), returnsNormally);
      });

      test('should get selected problematiques', () async {
        // Arrange
        const userId = 'user123';
        final mockProfile = {
          'selected_problematiques': [
            'devenir plus charismatique',
            'développer mon réseau'
          ],
        };

        when(mockQueryBuilder.select('selected_problematiques')).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => mockProfile);

        // Act
        final result = await userService.getSelectedProblematiques(userId);

        // Assert
        expect(result, isNotNull);
        expect(result!.length, equals(2));
        expect(result[0], equals('devenir plus charismatique'));
      });

      test('should handle empty problematiques list', () async {
        // Arrange
        const userId = 'user123';
        final mockProfile = {
          'selected_problematiques': <String>[],
        };

        when(mockQueryBuilder.select('selected_problematiques')).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => mockProfile);

        // Act
        final result = await userService.getSelectedProblematiques(userId);

        // Assert
        expect(result, isNotNull);
        expect(result!.isEmpty, isTrue);
      });
    });

    group('FCM Token Management', () {
      test('should update FCM token successfully', () async {
        // Arrange
        const userId = 'user123';
        const fcmToken = 'fcm_token_123456789';

        when(mockGoTrueClient.currentUser).thenReturn(mockUser);
        when(mockUser.id).thenReturn(userId);
        when(mockQueryBuilder.update({'fcm_token': fcmToken})).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenAnswer((_) async => {});

        // Act & Assert
        expect(() async => await userService.updateFCMToken(fcmToken),
               returnsNormally);
      });

      test('should handle missing user when updating FCM token', () async {
        // Arrange
        const fcmToken = 'fcm_token_123456789';

        when(mockGoTrueClient.currentUser).thenReturn(null);

        // Act & Assert
        expect(() async => await userService.updateFCMToken(fcmToken),
               throwsException);
      });
    });

    group('User Statistics', () {
      test('should get user statistics', () async {
        // Arrange
        const userId = 'user123';
        final mockStats = {
          'total_challenges': 15,
          'completed_challenges': 12,
          'current_streak': 5,
          'total_points': 120,
        };

        // Mock challenges count
        when(mockSupabaseClient.from('user_micro_challenges')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select('id', const FetchOptions(count: CountOption.exact)))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('user_id', userId)).thenAnswer((_) async => mockStats);

        // Act
        final result = await userService.getUserStatistics(userId);

        // Assert
        expect(result, isNotNull);
        expect(result['total_challenges'], equals(15));
        expect(result['completed_challenges'], equals(12));
      });
    });

    group('Onboarding Status', () {
      test('should check if user has completed onboarding', () async {
        // Arrange
        const userId = 'user123';
        final mockProfile = {
          'selected_problematiques': ['devenir plus charismatique'],
          'onboarding_completed': true,
        };

        when(mockQueryBuilder.select('selected_problematiques, onboarding_completed'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => mockProfile);

        // Act
        final result = await userService.hasCompletedOnboarding(userId);

        // Assert
        expect(result, isTrue);
      });

      test('should return false for incomplete onboarding', () async {
        // Arrange
        const userId = 'user123';
        final mockProfile = {
          'selected_problematiques': <String>[],
          'onboarding_completed': false,
        };

        when(mockQueryBuilder.select('selected_problematiques, onboarding_completed'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => mockProfile);

        // Act
        final result = await userService.hasCompletedOnboarding(userId);

        // Assert
        expect(result, isFalse);
      });

      test('should mark onboarding as completed', () async {
        // Arrange
        const userId = 'user123';

        when(mockQueryBuilder.update({'onboarding_completed': true}))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenAnswer((_) async => {});

        // Act & Assert
        expect(() async => await userService.markOnboardingCompleted(userId),
               returnsNormally);
      });
    });

    group('Error Handling', () {
      test('should handle database connection errors', () async {
        // Arrange
        const userId = 'user123';

        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenThrow(Exception('Database connection error'));

        // Act & Assert
        expect(() async => await userService.getUserProfile(userId),
               throwsException);
      });

      test('should handle invalid user data gracefully', () async {
        // Arrange
        const userId = 'user123';
        final invalidData = {
          'invalid_field': 'invalid_value',
        };

        when(mockQueryBuilder.update(invalidData)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId))
            .thenThrow(Exception('Invalid column name'));

        // Act & Assert
        expect(() async => await userService.updateUserProfile(userId, invalidData),
               throwsException);
      });
    });
  });
}
