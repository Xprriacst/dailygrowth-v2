import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';
import './openai_service.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  late final SupabaseClient _client;
  final OpenAIService _openAIService = OpenAIService();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      _client = await SupabaseService().client;
      _isInitialized = true;
    }
  }

  // Check if user is admin
  Future<bool> isUserAdmin(String userId) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select('is_admin')
          .eq('id', userId)
          .single();
      return response['is_admin'] as bool? ?? false;
    } catch (error) {
      throw Exception('Erreur lors de la vérification du rôle admin: $error');
    }
  }

  // Get pending challenges for validation
  Future<List<Map<String, dynamic>>> getPendingChallenges() async {
    try {
      final response = await _client
          .from('daily_challenges')
          .select('id, title, description, life_domain, created_at, user_id')
          .eq('validation_status', 'pending')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Erreur lors de la récupération des défis: $error');
    }
  }

  // Get pending quotes for validation
  Future<List<Map<String, dynamic>>> getPendingQuotes() async {
    try {
      final response = await _client
          .from('daily_quotes')
          .select('id, quote_text, author, life_domain, created_at, user_id')
          .eq('validation_status', 'pending')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Erreur lors de la récupération des citations: $error');
    }
  }

  // Validate content (approve or reject)
  Future<void> validateContent(
    String contentType,
    String contentId,
    String status, {
    String? feedback,
  }) async {
    try {
      final result = await _client.rpc('validate_content', params: {
        'p_content_type': contentType,
        'p_content_id': contentId,
        'p_status': status,
        'p_feedback': feedback,
      });

      if (result == false) {
        throw Exception('Permission refusée ou contenu non trouvé');
      }
    } catch (error) {
      throw Exception('Erreur lors de la validation du contenu: $error');
    }
  }

  // Get admin statistics
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      // Get pending content counts
      final pendingChallengesResult = await _client
          .from('daily_challenges')
          .select()
          .eq('validation_status', 'pending')
          .count();

      final pendingQuotesResult = await _client
          .from('daily_quotes')
          .select()
          .eq('validation_status', 'pending')
          .count();

      // Get approved content counts
      final approvedChallengesResult = await _client
          .from('daily_challenges')
          .select()
          .eq('validation_status', 'approved')
          .count();

      final approvedQuotesResult = await _client
          .from('daily_quotes')
          .select()
          .eq('validation_status', 'approved')
          .count();

      // Get rejected content counts
      final rejectedChallengesResult = await _client
          .from('daily_challenges')
          .select()
          .eq('validation_status', 'rejected')
          .count();

      final rejectedQuotesResult = await _client
          .from('daily_quotes')
          .select()
          .eq('validation_status', 'rejected')
          .count();

      // Get total content counts
      final totalChallengesResult =
          await _client.from('daily_challenges').select().count();

      final totalQuotesResult =
          await _client.from('daily_quotes').select().count();

      // Get active users count
      final activeUsersResult = await _client
          .from('user_profiles')
          .select()
          .eq('status', 'active')
          .count();

      return {
        'pending_challenges': pendingChallengesResult.count ?? 0,
        'pending_quotes': pendingQuotesResult.count ?? 0,
        'approved_challenges': approvedChallengesResult.count ?? 0,
        'approved_quotes': approvedQuotesResult.count ?? 0,
        'rejected_challenges': rejectedChallengesResult.count ?? 0,
        'rejected_quotes': rejectedQuotesResult.count ?? 0,
        'total_challenges': totalChallengesResult.count ?? 0,
        'total_quotes': totalQuotesResult.count ?? 0,
        'active_users': activeUsersResult.count ?? 0,
      };
    } catch (error) {
      throw Exception(
          'Erreur lors de la récupération des statistiques: $error');
    }
  }

  // Get validation history
  Future<List<Map<String, dynamic>>> getValidationHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('admin_content_validations')
          .select('''
            id,
            content_type,
            status,
            feedback,
            validated_at,
            admin_id:user_profiles!admin_content_validations_admin_id_fkey(full_name)
          ''')
          .order('validated_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception(
          'Erreur lors de la récupération de l\'historique: $error');
    }
  }

  // Get content details by ID and type
  Future<Map<String, dynamic>?> getContentDetails(
      String contentType, String contentId) async {
    try {
      final tableName =
          contentType == 'challenge' ? 'daily_challenges' : 'daily_quotes';
      final response =
          await _client.from(tableName).select().eq('id', contentId).single();
      return response;
    } catch (error) {
      throw Exception('Erreur lors de la récupération du contenu: $error');
    }
  }

  // Batch approve/reject multiple items
  Future<void> batchValidateContent(
    List<Map<String, String>> items,
    String status, {
    String? feedback,
  }) async {
    try {
      for (final item in items) {
        await validateContent(
          item['type']!,
          item['id']!,
          status,
          feedback: feedback,
        );
      }
    } catch (error) {
      throw Exception('Erreur lors de la validation en lot: $error');
    }
  }

  // Enhanced method to get AI-generated content insights
  Future<Map<String, dynamic>> getAIContentInsights() async {
    try {
      // Get counts of AI vs manual content
      final aiGeneratedChallenges = await _client
          .from('daily_challenges')
          .select()
          .eq('is_ai_generated', true)
          .count();

      final manualChallenges = await _client
          .from('daily_challenges')
          .select()
          .eq('is_ai_generated', false)
          .count();

      final aiGeneratedQuotes = await _client
          .from('daily_quotes')
          .select()
          .eq('is_ai_generated', true)
          .count();

      final manualQuotes = await _client
          .from('daily_quotes')
          .select()
          .eq('is_ai_generated', false)
          .count();

      // Get completion rates for AI vs manual content
      final aiChallengeCompletions = await _client
          .from('daily_challenges')
          .select()
          .eq('is_ai_generated', true)
          .eq('status', 'completed')
          .count();

      final manualChallengeCompletions = await _client
          .from('daily_challenges')
          .select()
          .eq('is_ai_generated', false)
          .eq('status', 'completed')
          .count();

      return {
        'ai_generated_challenges': aiGeneratedChallenges.count ?? 0,
        'manual_challenges': manualChallenges.count ?? 0,
        'ai_generated_quotes': aiGeneratedQuotes.count ?? 0,
        'manual_quotes': manualQuotes.count ?? 0,
        'ai_challenge_completions': aiChallengeCompletions.count ?? 0,
        'manual_challenge_completions': manualChallengeCompletions.count ?? 0,
        'ai_completion_rate': (aiGeneratedChallenges.count ?? 0) > 0
            ? (aiChallengeCompletions.count ?? 0) /
                (aiGeneratedChallenges.count ?? 0) *
                100
            : 0.0,
        'manual_completion_rate': (manualChallenges.count ?? 0) > 0
            ? (manualChallengeCompletions.count ?? 0) /
                (manualChallenges.count ?? 0) *
                100
            : 0.0,
      };
    } catch (error) {
      throw Exception('Erreur lors de la récupération des insights AI: $error');
    }
  }

  // Enhance content with AI suggestions
  Future<Map<String, String>> generateContentSuggestions({
    required String contentType,
    required String lifeDomain,
  }) async {
    try {
      if (!_openAIService.isApiKeyConfigured) {
        return {
          'suggestion':
              'Configuration de l\'API OpenAI requise pour les suggestions AI',
          'improvement': 'Veuillez configurer votre clé API OpenAI'
        };
      }

      if (contentType == 'challenge') {
        final challenge = await _openAIService.generateDailyChallenge(
          lifeDomain: lifeDomain,
          difficulty: 'medium',
        );

        return {
          'suggestion': challenge['title'] ?? '',
          'improvement': challenge['description'] ?? '',
        };
      } else if (contentType == 'quote') {
        final quote = await _openAIService.generateInspirationalQuote(
          lifeDomain: lifeDomain,
        );

        return {
          'suggestion': quote['quote'] ?? '',
          'improvement': 'Auteur: ${quote['author'] ?? 'Anonyme'}',
        };
      }

      return {
        'suggestion': 'Type de contenu non supporté',
        'improvement': 'Utilisez "challenge" ou "quote"'
      };
    } catch (e) {
      return {
        'suggestion': 'Erreur lors de la génération de suggestions',
        'improvement': 'Veuillez réessayer plus tard'
      };
    }
  }
}
