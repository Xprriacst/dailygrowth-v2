import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import './supabase_service.dart';
import './openai_service.dart';

class QuoteService {
  static final QuoteService _instance = QuoteService._internal();
  factory QuoteService() => _instance;
  QuoteService._internal();

  late final SupabaseClient _client;
  final _openAIService = OpenAIService();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      _client = await SupabaseService().client;
      _isInitialized = true;
    }
  }

  // Get today's quote for user
  Future<Map<String, dynamic>?> getTodaysQuote({
    required String userId,
    String? lifeDomain,
  }) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Try to get existing quote for today
      final existingQuote = await _client
          .from('daily_quotes')
          .select()
          .eq('user_id', userId)
          .eq('date_assigned', today)
          .maybeSingle();

      if (existingQuote != null) {
        return existingQuote;
      }

      // Generate new quote using OpenAI if none exists
      return await generateTodaysQuote(
          userId: userId, lifeDomain: lifeDomain ?? 'developpement');
    } catch (error) {
      throw Exception('Erreur lors de la récupération de la citation: $error');
    }
  }

  // Generate new quote using OpenAI
  Future<Map<String, dynamic>> generateTodaysQuote({
    required String userId,
    required String lifeDomain,
  }) async {
    try {
      Map<String, String> quoteData;

      // Try to generate with OpenAI first
      if (_openAIService.isApiKeyConfigured) {
        try {
          quoteData = await _openAIService.generateInspirationalQuote(
            lifeDomain: _translateLifeDomain(lifeDomain),
          );
        } catch (e) {
          debugPrint('OpenAI generation failed, using fallback: $e');
          quoteData = _getFallbackQuote(lifeDomain);
        }
      } else {
        quoteData = _getFallbackQuote(lifeDomain);
      }

      final today = DateTime.now().toIso8601String().split('T')[0];

      // Save to database
      try {
        final response = await _client
            .from('daily_quotes')
            .insert({
              'user_id': userId,
              'quote_text': quoteData['quote'],
              'quote_author': quoteData['author'],
              'life_domain': lifeDomain,
              'date': today,
              'is_ai_generated': _openAIService.isApiKeyConfigured,
            })
            .select()
            .single();

        return response;
      } catch (dbError) {
        // Return fallback quote without saving if DB fails
        return {
          'quote_text': quoteData['quote'],
          'quote_author': quoteData['author'],
          'life_domain': lifeDomain,
          'date': today,
          'is_ai_generated': _openAIService.isApiKeyConfigured,
        };
      }
    } catch (error) {
      // Final fallback if everything fails
      final today = DateTime.now().toIso8601String().split('T')[0];
      final fallbackQuote = _getFallbackQuote(lifeDomain);

      return {
        'quote_text': fallbackQuote['quote'],
        'quote_author': fallbackQuote['author'],
        'life_domain': lifeDomain,
        'date': today,
        'is_ai_generated': false,
      };
    }
  }

  // Get user's quote history
  Future<List<Map<String, dynamic>>> getQuoteHistory({
    required String userId,
    int limit = 30,
  }) async {
    try {
      final response = await _client
          .from('daily_quotes')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception(
          'Erreur lors de la récupération de l\'historique: $error');
    }
  }

  // Mark quote as favorite
  Future<Map<String, dynamic>> toggleQuoteFavorite({
    required String userId,
    required String quoteId,
  }) async {
    try {
      // Get current favorite status
      final currentQuote = await _client
          .from('daily_quotes')
          .select('is_favorite')
          .eq('id', quoteId)
          .eq('user_id', userId)
          .single();

      final newFavoriteStatus = !(currentQuote['is_favorite'] ?? false);

      // Update favorite status
      final response = await _client
          .from('daily_quotes')
          .update({'is_favorite': newFavoriteStatus})
          .eq('id', quoteId)
          .eq('user_id', userId)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Erreur lors de la mise à jour du favori: $error');
    }
  }

  // Get favorite quotes
  Future<List<Map<String, dynamic>>> getFavoriteQuotes({
    required String userId,
  }) async {
    try {
      final response = await _client
          .from('daily_quotes')
          .select()
          .eq('user_id', userId)
          .eq('is_favorite', true)
          .order('date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Erreur lors de la récupération des favoris: $error');
    }
  }

  // Get today's quote for user (compatibility method)
  Future<Map<String, dynamic>?> getTodayQuote(String userId) async {
    return await getTodaysQuote(userId: userId);
  }

  // Create quote (compatibility method)
  Future<Map<String, dynamic>> createQuote({
    required String userId,
    required String quoteText,
    required String author,
    required String lifeDomain,
  }) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await _client
          .from('daily_quotes')
          .insert({
            'user_id': userId,
            'quote_text': quoteText,
            'quote_author': author,
            'life_domain': lifeDomain,
            'date': today,
            'is_ai_generated': false,
          })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Erreur lors de la création de la citation: $error');
    }
  }

  // Helper methods
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

  Map<String, String> _getFallbackQuote(String lifeDomain) {
    final fallbackQuotes = {
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

    return fallbackQuotes[lifeDomain] ?? fallbackQuotes['developpement']!;
  }
}