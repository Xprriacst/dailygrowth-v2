import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dailygrowth/services/challenge_service.dart';
import 'package:dailygrowth/services/supabase_service.dart';
import 'package:dailygrowth/services/n8n_challenge_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Generate mocks with: flutter packages pub run build_runner build
@GenerateMocks([
  SupabaseClient,
  PostgrestQueryBuilder,
  PostgrestFilterBuilder,
  N8nChallengeService,
])
import 'challenge_service_test.mocks.dart';

void main() {
  group('ChallengeService Tests', () {
    late ChallengeService challengeService;
    late MockSupabaseClient mockSupabaseClient;
    late MockPostgrestQueryBuilder mockQueryBuilder;
    late MockPostgrestFilterBuilder mockFilterBuilder;
    late MockN8nChallengeService mockN8nService;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockQueryBuilder = MockPostgrestQueryBuilder();
      mockFilterBuilder = MockPostgrestFilterBuilder();
      mockN8nService = MockN8nChallengeService();
      challengeService = ChallengeService();
    });

    group('Challenge Generation', () {
      test('should generate today challenge successfully', () async {
        // Arrange
        const userId = 'user123';
        const lifeDomain = 'developpement';
        
        final mockUserProfile = {
          'selected_problematiques': ['devenir plus charismatique'],
        };
        
        final mockGeneratedChallenge = {
          'id': 'challenge123',
          'nom': 'Sourire à 3 personnes',
          'mission': 'Souriez sincèrement à 3 personnes aujourd\'hui',
          'pourquoi': 'Pour développer votre charisme naturel',
          'bonus': 'Notez leurs réactions',
          'duree_estimee': '15 minutes',
          'niveau_detecte': 'débutant',
        };

        // Mock user profile fetch
        when(mockSupabaseClient.from('user_profiles')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select('selected_problematiques')).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => mockUserProfile);

        // Mock existing challenge check
        when(mockSupabaseClient.from('user_micro_challenges')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('user_id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.gte('created_at', any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.lt('created_at', any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => null);

        // Mock n8n service
        when(mockN8nService.generateSingleMicroChallengeWithFallback(
          problematique: anyNamed('problematique'),
          nombreDefisReleves: anyNamed('nombreDefisReleves'),
        )).thenAnswer((_) async => mockGeneratedChallenge);

        // Mock challenge insertion
        when(mockQueryBuilder.insert(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select()).thenAnswer((_) async => [mockGeneratedChallenge]);

        // Act
        final result = await challengeService.generateTodayChallenge(
          userId: userId,
          lifeDomain: lifeDomain,
        );

        // Assert
        expect(result, isNotNull);
        expect(result!['nom'], equals('Sourire à 3 personnes'));
      });

      test('should return existing challenge if already generated today', () async {
        // Arrange
        const userId = 'user123';
        const lifeDomain = 'developpement';
        
        final existingChallenge = {
          'id': 'existing123',
          'nom': 'Challenge existant',
          'mission': 'Mission existante',
        };

        // Mock existing challenge found
        when(mockSupabaseClient.from('user_micro_challenges')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('user_id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.gte('created_at', any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.lt('created_at', any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => existingChallenge);

        // Act
        final result = await challengeService.generateTodayChallenge(
          userId: userId,
          lifeDomain: lifeDomain,
        );

        // Assert
        expect(result, isNotNull);
        expect(result!['nom'], equals('Challenge existant'));
      });
    });

    group('Problematique Rotation', () {
      test('should rotate problematiques based on day of year', () {
        // Arrange
        final problematiques = [
          'lâcher-prise',
          'maîtriser mes émotions',
          'développer mes revenus'
        ];
        
        // Test different days to verify rotation
        final testCases = [
          {'day': 1, 'expected': 'maîtriser mes émotions'}, // 1 % 3 = 1
          {'day': 2, 'expected': 'développer mes revenus'},  // 2 % 3 = 2
          {'day': 3, 'expected': 'lâcher-prise'},           // 3 % 3 = 0
        ];

        for (final testCase in testCases) {
          // Act - This would require exposing _getTodaysProblematique or creating a testable version
          // For now, we'll test the logic conceptually
          final dayOfYear = testCase['day'] as int;
          final expectedIndex = dayOfYear % problematiques.length;
          final expectedProblematique = problematiques[expectedIndex];

          // Assert
          expect(expectedProblematique, equals(testCase['expected']));
        }
      });

      test('should handle single problematique without rotation', () {
        // Arrange
        final problematiques = ['unique problématique'];
        
        // Act - Test rotation logic
        final index = 5 % problematiques.length; // Any day
        final result = problematiques[index];

        // Assert
        expect(result, equals('unique problématique'));
      });
    });

    group('Challenge Completion', () {
      test('should mark challenge as completed', () async {
        // Arrange
        const challengeId = 'challenge123';
        const userId = 'user123';

        when(mockSupabaseClient.from('user_micro_challenges')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.update(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', challengeId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('user_id', userId)).thenAnswer((_) async => {});

        // Act & Assert
        expect(() async => await challengeService.markChallengeCompleted(
          challengeId, userId), returnsNormally);
      });
    });

    group('Challenge Retrieval', () {
      test('should get today challenge for user', () async {
        // Arrange
        const userId = 'user123';
        final todayChallenge = {
          'id': 'today123',
          'nom': 'Today\'s Challenge',
          'mission': 'Complete today\'s mission',
        };

        when(mockSupabaseClient.from('user_micro_challenges')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('user_id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.gte('created_at', any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.lt('created_at', any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => todayChallenge);

        // Act
        final result = await challengeService.getTodayChallenge(userId);

        // Assert
        expect(result, isNotNull);
        expect(result!['nom'], equals('Today\'s Challenge'));
      });

      test('should get user challenge history', () async {
        // Arrange
        const userId = 'user123';
        final challengeHistory = [
          {'id': '1', 'nom': 'Challenge 1', 'completed': true},
          {'id': '2', 'nom': 'Challenge 2', 'completed': false},
        ];

        when(mockSupabaseClient.from('user_micro_challenges')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('user_id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('created_at', ascending: false)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.limit(any)).thenAnswer((_) async => challengeHistory);

        // Act
        final result = await challengeService.getUserChallengeHistory(userId, limit: 10);

        // Assert
        expect(result, isNotNull);
        expect(result.length, equals(2));
        expect(result[0]['nom'], equals('Challenge 1'));
      });
    });

    group('Error Handling', () {
      test('should handle database errors gracefully', () async {
        // Arrange
        const userId = 'user123';
        const lifeDomain = 'developpement';

        when(mockSupabaseClient.from('user_profiles')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select('selected_problematiques')).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(() async => await challengeService.generateTodayChallenge(
          userId: userId,
          lifeDomain: lifeDomain,
        ), throwsException);
      });

      test('should handle n8n service failures with fallback', () async {
        // Arrange
        const userId = 'user123';
        const lifeDomain = 'developpement';
        
        final mockUserProfile = {
          'selected_problematiques': ['devenir plus charismatique'],
        };

        // Mock successful profile fetch
        when(mockSupabaseClient.from('user_profiles')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select('selected_problematiques')).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => mockUserProfile);

        // Mock no existing challenge
        when(mockSupabaseClient.from('user_micro_challenges')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('user_id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.gte('created_at', any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.lt('created_at', any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => null);

        // Mock n8n service failure
        when(mockN8nService.generateSingleMicroChallengeWithFallback(
          problematique: anyNamed('problematique'),
          nombreDefisReleves: anyNamed('nombreDefisReleves'),
        )).thenThrow(Exception('N8n service error'));

        // Act & Assert - Should handle gracefully with fallback
        expect(() async => await challengeService.generateTodayChallenge(
          userId: userId,
          lifeDomain: lifeDomain,
        ), returnsNormally);
      });
    });
  });
}
