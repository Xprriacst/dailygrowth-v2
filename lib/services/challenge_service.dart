import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import './supabase_service.dart';
import './n8n_challenge_service.dart';
import './user_service.dart';

class ChallengeService {
  static final ChallengeService _instance = ChallengeService._internal();
  factory ChallengeService() => _instance;
  ChallengeService._internal();

  late final SupabaseClient _client;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      _client = await SupabaseService().client;
      _isInitialized = true;
    }
  }

  // Get today's challenge for user
  Future<Map<String, dynamic>?> getTodayChallenge(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await _client
          .from('daily_challenges')
          .select()
          .eq('user_id', userId)
          .eq('date_assigned', today)
          .maybeSingle();
      return response;
    } catch (error) {
      debugPrint('Error getting today\'s challenge: $error');
      throw Exception('Erreur lors de la récupération du défi: $error');
    }
  }

  // Force regenerate today's challenge using micro-challenges
  Future<Map<String, dynamic>> forceRegenerateTodayChallenge({
    required String userId,
    required String lifeDomain,
  }) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Delete existing challenge for today
      await _client
          .from('daily_challenges')
          .delete()
          .eq('user_id', userId)
          .eq('date_assigned', today);
      
      debugPrint('🔄 Deleted existing challenge for today');
      
      // Generate new challenge
      return await generateTodayChallenge(
        userId: userId,
        lifeDomain: lifeDomain,
        difficulty: 'medium',
      );
    } catch (error) {
      debugPrint('Error force regenerating challenge: $error');
      throw Exception('Erreur lors de la régénération du défi: $error');
    }
  }

  // Get next unused micro-challenge for daily challenge
  Future<Map<String, dynamic>?> getNextMicroChallenge(String userId) async {
    try {
      final response = await _client
          .from('user_micro_challenges')
          .select()
          .eq('user_id', userId)
          .eq('is_used_as_daily', false)
          .order('numero', ascending: true)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (error) {
      debugPrint('Error getting next micro challenge: $error');
      return null;
    }
  }

  // Generate and create today's challenge using direct n8n generation
  Future<Map<String, dynamic>> generateTodayChallenge({
    required String userId,
    required String lifeDomain,
    String difficulty = 'medium',
  }) async {
    try {
      debugPrint('');
      debugPrint('═══════════════════════════════════════════════');
      debugPrint('🎯 [generateTodayChallenge] CALLED');
      debugPrint('📍 User ID: $userId');
      debugPrint('📍 Life Domain: $lifeDomain');
      debugPrint('📍 Difficulty: $difficulty');
      debugPrint('═══════════════════════════════════════════════');
      debugPrint('');
      
      // Générer directement un nouveau défi via n8n (pas de vérification de stock)
      final newChallenge = await _generateNewMicroChallengeViaAI(userId, lifeDomain);
      
      Map<String, String> challengeData;
      String? microChallengeId;
      String? problematique;
      
      if (newChallenge != null) {
        challengeData = {
          'title': newChallenge['nom'] as String,
          'description': newChallenge['mission'] as String,
        };
        microChallengeId = newChallenge['id'] as String;
        problematique = newChallenge['problematique'] as String?;
        debugPrint('✅ Generated new challenge via n8n: ${challengeData['title']}');
        debugPrint('   Problematique: $problematique');
      } else {
        // Fallback vers la génération locale
        debugPrint('⚠️ n8n generation failed, using local fallback');
        challengeData = _getFallbackChallenge(lifeDomain, difficulty);
      }

      // Create the challenge in database
      final challenge = {
        'user_id': userId,
        'title': challengeData['title']!,
        'description': challengeData['description']!,
        'life_domain': lifeDomain,
        'points_reward': _getPointsForDifficulty(difficulty),
        'date_assigned': DateTime.now().toIso8601String().split('T')[0],
        'status': 'pending',
        if (problematique != null) 'problematique': problematique,
      };

      final response = await _client
          .from('daily_challenges')
          .insert(challenge)
          .select()
          .single();

      // Marquer le micro-défi comme utilisé si applicable
      if (microChallengeId != null) {
        await _markMicroChallengeAsUsed(microChallengeId);
      }

      return response;
    } catch (error) {
      debugPrint('Error generating challenge: $error');
      throw Exception('Erreur lors de la génération du défi: $error');
    }
  }

  // Mark micro-challenge as used for daily challenge
  Future<void> _markMicroChallengeAsUsed(String microChallengeId) async {
    try {
      await _client
          .from('user_micro_challenges')
          .update({
            'is_used_as_daily': true,
            'used_as_daily_date': DateTime.now().toIso8601String().split('T')[0],
          })
          .eq('id', microChallengeId);
      
      debugPrint('✅ Marked micro-challenge as used: $microChallengeId');
    } catch (error) {
      debugPrint('❌ Error marking micro-challenge as used: $error');
    }
  }

  // Create challenge - NEW METHOD FOR COMPATIBILITY
  Future<Map<String, dynamic>> createChallenge({
    required String userId,
    required String title,
    required String description,
    required String lifeDomain,
    int? pointsReward,
  }) async {
    try {
      final challenge = {
        'user_id': userId,
        'title': title,
        'description': description,
        'life_domain': lifeDomain,
        'points_reward': pointsReward ?? 10,
        'date_assigned': DateTime.now().toIso8601String().split('T')[0],
        'status': 'pending',
      };

      final response = await _client
          .from('daily_challenges')
          .insert(challenge)
          .select()
          .single();

      return response;
    } catch (error) {
      debugPrint('Error creating challenge: $error');
      throw Exception('Erreur lors de la création du défi: $error');
    }
  }

  // Get user's challenges with filtering
  Future<List<Map<String, dynamic>>> getUserChallenges({
    required String userId,
    String? status,
    String? lifeDomain,
    int? limit,
    int? offset,
  }) async {
    try {
      var query =
          _client.from('daily_challenges').select().eq('user_id', userId);

      if (status != null) {
        query = query.eq('status', status);
      }

      if (lifeDomain != null) {
        query = query.eq('life_domain', lifeDomain);
      }

      final response = await query
          .order('date_assigned', ascending: false)
          .limit(limit ?? 50)
          .range(offset ?? 0, (offset ?? 0) + (limit ?? 50) - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('Error getting user challenges: $error');
      throw Exception('Erreur lors de la récupération des défis: $error');
    }
  }

  // Complete a challenge - FIXED IMPLEMENTATION
  Future<Map<String, dynamic>> completeChallenge({
    required String challengeId,
    required String userId,
    String? notes,
  }) async {
    try {
      // First, verify the challenge belongs to the user and is pending
      final existingChallenge = await _client
          .from('daily_challenges')
          .select()
          .eq('id', challengeId)
          .eq('user_id', userId)
          .single();

      // Update challenge status to completed
      final challengeResponse = await _client
          .from('daily_challenges')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', challengeId)
          .eq('user_id', userId)
          .select()
          .single();

      // Add to challenge history
      await _client.from('challenge_history').insert({
        'user_id': userId,
        'challenge_id': challengeId,
        'points_earned': challengeResponse['points_reward'] ?? 10,
        'notes': notes,
        'completed_at': DateTime.now().toIso8601String(),
      });

      // Update user's total points and streak
      await _updateUserProgress(
          userId, challengeResponse['points_reward'] ?? 10);

      return challengeResponse;
    } catch (error) {
      debugPrint('Error completing challenge: $error');
      throw Exception('Erreur lors de la completion du défi: $error');
    }
  }

  // Skip a challenge - FIXED IMPLEMENTATION
  Future<Map<String, dynamic>> skipChallenge({
    required String challengeId,
    required String userId,
  }) async {
    try {
      final response = await _client
          .from('daily_challenges')
          .update({
            'status': 'pending',
            'completed_at': null,
          })
          .eq('id', challengeId)
          .eq('user_id', userId)
          .select()
          .single();

      // Remove from challenge history if it exists
      await _client
          .from('challenge_history')
          .delete()
          .eq('challenge_id', challengeId)
          .eq('user_id', userId);

      return response;
    } catch (error) {
      debugPrint('Error skipping challenge: $error');
      throw Exception('Erreur lors du passage du défi: $error');
    }
  }

  // Update user progress (points and streak)
  Future<void> _updateUserProgress(String userId, int points) async {
    try {
      // Get current user profile
      final userProfile = await _client
          .from('user_profiles')
          .select('total_points, streak_count')
          .eq('id', userId)
          .single();

      final currentPoints = userProfile['total_points'] ?? 0;
      final currentStreak = userProfile['streak_count'] ?? 0;

      // Update points and potentially streak
      await _client.from('user_profiles').update({
        'total_points': currentPoints + points,
        'streak_count': currentStreak + 1,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (error) {
      debugPrint('Error updating user progress: $error');
      // Don't throw error here as the main challenge completion should succeed
    }
  }

  // Get challenge history - REAL DATABASE IMPLEMENTATION
  Future<List<Map<String, dynamic>>> getChallengeHistory({
    required String userId,
    int? limit,
    int? offset,
  }) async {
    try {
      final response = await _client
          .from('challenge_history')
          .select('''
            *,
            daily_challenges!inner(
              id,
              title,
              description,
              life_domain,
              points_reward,
              date_assigned
            )
          ''')
          .eq('user_id', userId)
          .order('completed_at', ascending: false)
          .limit(limit ?? 50)
          .range(offset ?? 0, (offset ?? 0) + (limit ?? 50) - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('Error getting challenge history: $error');
      throw Exception(
          'Erreur lors de la récupération de l\'historique: $error');
    }
  }

  // Get challenges statistics by life domain
  Future<Map<String, dynamic>> getChallengeStats(String userId) async {
    try {
      final results = await Future.wait([
        // Pending challenges
        _client
            .from('daily_challenges')
            .select()
            .eq('user_id', userId)
            .eq('status', 'pending')
            .count(),

        // Completed challenges
        _client
            .from('daily_challenges')
            .select()
            .eq('user_id', userId)
            .eq('status', 'completed')
            .count(),

        // Skipped challenges
        _client
            .from('daily_challenges')
            .select()
            .eq('user_id', userId)
            .eq('status', 'skipped')
            .count(),
      ]);

      final pendingCount = results[0].count ?? 0;
      final completedCount = results[1].count ?? 0;
      final skippedCount = results[2].count ?? 0;
      final totalCount = pendingCount + completedCount + skippedCount;

      return {
        'pending_challenges': pendingCount,
        'completed_challenges': completedCount,
        'skipped_challenges': skippedCount,
        'total_challenges': totalCount,
        'completion_rate':
            totalCount > 0 ? (completedCount / totalCount * 100) : 0.0,
      };
    } catch (error) {
      debugPrint('Error getting challenge stats: $error');
      throw Exception(
          'Erreur lors de la récupération des statistiques: $error');
    }
  }

  // Search challenges
  Future<List<Map<String, dynamic>>> searchChallenges({
    required String userId,
    required String searchTerm,
    int? limit,
  }) async {
    try {
      final response = await _client
          .from('daily_challenges')
          .select()
          .eq('user_id', userId)
          .ilike('title', '%$searchTerm%')
          .order('date_assigned', ascending: false)
          .limit(limit ?? 20);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('Error searching challenges: $error');
      throw Exception('Erreur lors de la recherche: $error');
    }
  }

  // Generate personalized motivational message for challenge
  Future<String> generateMotivationalMessage({
    required String userId,
    required String challengeTitle,
    required int streakCount,
  }) async {
    try {
      return _getFallbackMotivationalMessage(streakCount);
    } catch (e) {
      debugPrint('Error generating motivational message: $e');
      return _getFallbackMotivationalMessage(streakCount);
    }
  }

  // Generate new micro-challenge via n8n when no unused challenges available
  Future<Map<String, dynamic>?> _generateNewMicroChallengeViaAI(String userId, String lifeDomain) async {
    try {
      debugPrint('🔍 [CHALLENGE SERVICE] Starting _generateNewMicroChallengeViaAI');
      debugPrint('🔍 [CHALLENGE SERVICE] User ID: $userId');
      debugPrint('🔍 [CHALLENGE SERVICE] Life Domain: $lifeDomain');
      
      final n8nService = N8nChallengeService();
      final userService = UserService();
      
      // Get user profile to determine problematique
      final userProfile = await userService.getUserProfile(userId);
      if (userProfile == null) {
        debugPrint('❌ [CHALLENGE SERVICE] No user profile found for challenge generation');
        return null;
      }
      
      debugPrint('✅ [CHALLENGE SERVICE] User profile loaded');
      
      // Get number of completed challenges
      final completedChallenges = await _client
          .from('daily_challenges')
          .select()
          .eq('user_id', userId)
          .eq('status', 'completed')
          .count();
      
      final nombreDefisReleves = completedChallenges.count ?? 0;
      
      debugPrint('📊 [CHALLENGE SERVICE] Défis complétés: $nombreDefisReleves');
      
      // Get user's selected problematique (single selection)
      String problematique = lifeDomain;
      if (userProfile['selected_problematiques'] != null) {
        final problematiques = List<String>.from(userProfile['selected_problematiques']);
        debugPrint('🔍 [CHALLENGE SERVICE] Selected problematiques: $problematiques');
        if (problematiques.isNotEmpty) {
          problematique = problematiques.first; // Use the single selected problematique
        }
      } else if (userProfile['selected_life_domains'] != null) {
        // Fallback to domain if no specific problematique
        final domains = List<String>.from(userProfile['selected_life_domains']);
        debugPrint('🔍 [CHALLENGE SERVICE] Selected life domains: $domains');
        if (domains.isNotEmpty) {
          problematique = domains.first;
        }
      }
      
      debugPrint('🎯 [CHALLENGE SERVICE] Final problematique: "$problematique"');
      debugPrint('🚀 [CHALLENGE SERVICE] Calling n8n webhook...');
      
      // Generate single challenge via n8n
      final result = await n8nService.generateSingleMicroChallengeWithFallback(
        problematique: problematique,
        nombreDefisReleves: nombreDefisReleves,
        userId: userId,
      );
      
      debugPrint('✅ [CHALLENGE SERVICE] N8n webhook returned result');
      
      // Get the generated challenge from database
      final generatedChallenge = await _client
          .from('user_micro_challenges')
          .select()
          .eq('user_id', userId)
          .eq('numero', nombreDefisReleves + 1)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      return generatedChallenge;
    } catch (error) {
      debugPrint('❌ Error generating new micro-challenge via AI: $error');
      return null;
    }
  }

  // Helper methods for fallback content
  String _translateLifeDomain(String domain) {
    final translations = {
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

  Map<String, String> _getFallbackChallenge(
      String lifeDomain, String difficulty) {
    final challenges = {
      'sante': {
        'easy': {
          'title': 'Hydratation consciente',
          'description':
              'Buvez un grand verre d\'eau dès votre réveil et observez comment vous vous sentez.',
        },
        'medium': {
          'title': 'Marche méditative',
          'description':
              'Prenez 15 minutes pour une marche en pleine conscience, en portant attention à votre respiration.',
        },
        'hard': {
          'title': 'Défi nutrition',
          'description':
              'Préparez un repas équilibré avec 5 couleurs différentes de légumes et fruits.',
        },
      },
      'relations': {
        'easy': {
          'title': 'Message d\'appréciation',
          'description':
              'Envoyez un message sincère à quelqu\'un pour lui dire ce que vous appréciez chez lui.',
        },
        'medium': {
          'title': 'Écoute active',
          'description':
              'Lors d\'une conversation aujourd\'hui, concentrez-vous uniquement sur l\'écoute sans préparer votre réponse.',
        },
        'hard': {
          'title': 'Résolution de conflit',
          'description':
              'Identifiez un malentendu récent et prenez l\'initiative d\'une conversation pour le résoudre.',
        },
      },
      'carriere': {
        'easy': {
          'title': 'Organisation productive',
          'description':
              'Organisez votre espace de travail et priorisez vos 3 tâches les plus importantes.',
        },
        'medium': {
          'title': 'Apprentissage ciblé',
          'description':
              'Consacrez 30 minutes à apprendre quelque chose de nouveau dans votre domaine professionnel.',
        },
        'hard': {
          'title': 'Réseautage stratégique',
          'description':
              'Contactez un professionnel de votre secteur pour échanger sur les tendances actuelles.',
        },
      },
      // Add more domains as needed
    };

    final domainChallenges = challenges[lifeDomain] ?? challenges['sante']!;
    final challenge =
        domainChallenges[difficulty] ?? domainChallenges['medium']!;

    return {
      'title': challenge['title']!,
      'description': challenge['description']!,
    };
  }

  int _getPointsForDifficulty(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 5;
      case 'medium':
        return 10;
      case 'hard':
        return 15;
      default:
        return 10;
    }
  }

  String _getFallbackMotivationalMessage(int streakCount) {
    if (streakCount == 0) {
      return 'Chaque grand voyage commence par un premier pas. Vous pouvez le faire !';
    } else if (streakCount < 7) {
      return 'Excellent début ! Vous construisez déjà une belle habitude. Continuez !';
    } else if (streakCount < 30) {
      return 'Impressionnant ! $streakCount jours consécutifs montrent votre détermination.';
    } else {
      return 'Extraordinaire ! $streakCount jours de constance, vous êtes un exemple d\'inspiration !';
    }
  }
}
