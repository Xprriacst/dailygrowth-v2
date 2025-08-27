import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class N8nChallengeService {
  static final N8nChallengeService _instance = N8nChallengeService._internal();
  factory N8nChallengeService() => _instance;
  N8nChallengeService._internal();

  late final Dio _dio;
  static const String webhookUrl = 'https://polaris-ia.app.n8n.cloud/webhook/ui-defis-final';

  void _initializeService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60), // Plus long pour l'IA
        sendTimeout: const Duration(seconds: 30),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('🚀 N8n Webhook Request: ${options.method} ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('✅ N8n Webhook Response: ${response.statusCode}');
          handler.next(response);
        },
        onError: (DioException error, handler) {
          debugPrint('❌ N8n Webhook Error: ${error.response?.statusCode} - ${error.message}');
          handler.next(error);
        },
      ),
    );

    debugPrint('✅ N8n Challenge Service initialized');
  }

  /// Génère des micro-défis via le workflow n8n
  Future<Map<String, dynamic>> generateMicroChallenges({
    required String problematique,
    required int nombreDefisReleves,
    String? userId,
  }) async {
    _initializeService();

    try {
      debugPrint('🎯 Generating challenges for: $problematique (défis relevés: $nombreDefisReleves)');

      // Préparer les données au format attendu par le workflow
      final requestData = {
        'Je veux...': 'Je veux travailler sur: $problematique',
        'Combien de défi à tu relevé': nombreDefisReleves.toString(),
        if (userId != null) 'user_id': userId,
      };

      final response = await _dio.post(
        webhookUrl,
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw N8nException(
          statusCode: response.statusCode ?? 500,
          message: 'Erreur HTTP: ${response.statusCode}',
        );
      }

      // Parser la réponse
      Map<String, dynamic> responseData;
      if (response.data is String) {
        try {
          responseData = jsonDecode(response.data);
        } catch (e) {
          debugPrint('❌ Erreur parsing JSON: $e');
          debugPrint('Raw response: ${response.data}');
          throw N8nException(
            statusCode: 500,
            message: 'Réponse invalide du workflow n8n',
          );
        }
      } else {
        responseData = response.data;
      }

      // Validation de la structure
      if (!responseData.containsKey('defis') || 
          responseData['defis'] is! List ||
          (responseData['defis'] as List).isEmpty) {
        throw N8nException(
          statusCode: 500,
          message: 'Structure de réponse invalide: défis manquants',
        );
      }

      final defis = responseData['defis'] as List;
      
      // Validation des défis
      for (int i = 0; i < defis.length; i++) {
        final defi = defis[i];
        if (defi is! Map || 
            !defi.containsKey('nom') || 
            !defi.containsKey('mission') ||
            !defi.containsKey('pourquoi')) {
          debugPrint('⚠️ Défi $i incomplet: $defi');
        }
      }

      debugPrint('✅ Generated ${defis.length} challenges successfully');
      return responseData;

    } on DioException catch (e) {
      debugPrint('❌ Dio error: ${e.message}');
      
      if (e.response?.statusCode == 429) {
        throw N8nException(
          statusCode: 429,
          message: 'Quota OpenAI dépassé. Veuillez réessayer plus tard.',
        );
      } else if (e.response?.statusCode == 404) {
        throw N8nException(
          statusCode: 404,
          message: 'Webhook n8n introuvable. Vérifiez l\'URL.',
        );
      } else {
        throw N8nException(
          statusCode: e.response?.statusCode ?? 500,
          message: 'Erreur réseau: ${e.message}',
        );
      }
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      throw N8nException(
        statusCode: 500,
        message: 'Erreur inattendue: $e',
      );
    }
  }

  /// Génère des défis avec fallback en cas d'erreur
  Future<Map<String, dynamic>> generateMicroChallengesWithFallback({
    required String problematique,
    required int nombreDefisReleves,
    String? userId,
  }) async {
    try {
      return await generateMicroChallenges(
        problematique: problematique,
        nombreDefisReleves: nombreDefisReleves,
        userId: userId,
      );
    } catch (e) {
      debugPrint('⚠️ Fallback to local challenges due to: $e');
      return _generateFallbackChallenges(problematique, nombreDefisReleves);
    }
  }

  /// Génère des défis de fallback locaux
  Map<String, dynamic> _generateFallbackChallenges(String problematique, int nombreDefisReleves) {
    final niveau = nombreDefisReleves == 0 ? 'débutant' : 
                   nombreDefisReleves <= 5 ? 'intermédiaire' : 'avancé';

    // Défis adaptés selon la problématique
    List<Map<String, dynamic>> defis = [];
    
    if (problematique.toLowerCase().contains('confiance')) {
      defis = _getConfidenceChallenges();
    } else if (problematique.toLowerCase().contains('émotion') || 
               problematique.toLowerCase().contains('gestion')) {
      defis = _getEmotionChallenges();
    } else if (problematique.toLowerCase().contains('réseau') || 
               problematique.toLowerCase().contains('charismatique')) {
      defis = _getNetworkingChallenges();
    } else {
      defis = _getGenericChallenges();
    }

    // Limiter à 15 défis et ajouter les numéros
    final defisFinaux = defis.take(15).toList().asMap().entries.map((entry) {
      final defi = Map<String, dynamic>.from(entry.value);
      defi['numero'] = entry.key + 1;
      return defi;
    }).toList();

    return {
      'problematique': problematique,
      'niveau_detecte': niveau,
      'defis': defisFinaux,
      'source': 'fallback_local',
    };
  }

  List<Map<String, dynamic>> _getConfidenceChallenges() {
    return [
      {
        'nom': 'Auto-observation quotidienne',
        'mission': 'Notez 3 situations où vous manquez de confiance cette semaine',
        'pourquoi': 'Identifier les patterns aide à mieux comprendre les déclencheurs',
        'bonus': null,
        'duree_estimee': '10'
      },
      {
        'nom': 'Inventaire des victoires',
        'mission': 'Listez 5 réussites personnelles des 2 dernières années',
        'pourquoi': 'Se rappeler ses succès renforce l\'estime de soi',
        'bonus': 'Demandez à un proche ses 3 qualités préférées chez vous',
        'duree_estimee': '15'
      },
      {
        'nom': 'Posture de pouvoir',
        'mission': 'Adoptez une posture droite et souriez pendant 2 minutes',
        'pourquoi': 'La posture influence directement l\'état d\'esprit et la confiance',
        'bonus': 'Faites cet exercice avant une situation stressante',
        'duree_estimee': '5'
      },
      // Ajoutez plus de défis confiance...
    ];
  }

  List<Map<String, dynamic>> _getEmotionChallenges() {
    return [
      {
        'nom': 'Journal des émotions',
        'mission': 'Notez 3 émotions ressenties aujourd\'hui et leurs déclencheurs',
        'pourquoi': 'Identifier les patterns émotionnels aide à mieux les gérer',
        'bonus': 'Notez aussi votre réaction physique',
        'duree_estimee': '10'
      },
      {
        'nom': 'Technique de respiration 4-7-8',
        'mission': 'Pratiquez 3 cycles de respiration 4-7-8 quand vous sentez du stress',
        'pourquoi': 'Active le système nerveux parasympathique et calme l\'esprit',
        'bonus': 'Utilisez cette technique avant une situation stressante',
        'duree_estimee': '5'
      },
      // Ajoutez plus de défis émotions...
    ];
  }

  List<Map<String, dynamic>> _getNetworkingChallenges() {
    return [
      {
        'nom': 'Optimiser votre profil LinkedIn',
        'mission': 'Mettez à jour votre photo, résumé et expériences sur LinkedIn',
        'pourquoi': 'Un profil professionnel attire les bonnes opportunités',
        'bonus': 'Ajoutez 3 compétences clés',
        'duree_estimee': '20'
      },
      {
        'nom': 'Commenter 5 posts LinkedIn',
        'mission': 'Laissez des commentaires constructifs sur 5 publications de votre secteur',
        'pourquoi': 'Augmente votre visibilité et montre votre expertise',
        'bonus': 'Partagez un de ces posts avec votre opinion',
        'duree_estimee': '15'
      },
      // Ajoutez plus de défis networking...
    ];
  }

  List<Map<String, dynamic>> _getGenericChallenges() {
    return [
      {
        'nom': 'Action micro-progressive',
        'mission': 'Faites une petite action concrète vers votre objectif aujourd\'hui',
        'pourquoi': 'Les petits pas créent une dynamique positive',
        'bonus': 'Célébrez cette victoire',
        'duree_estimee': '15'
      },
      {
        'nom': 'Réflexion guidée',
        'mission': 'Prenez 10 minutes pour réfléchir à vos progrès récents',
        'pourquoi': 'La réflexion consciente accélère l\'apprentissage',
        'bonus': 'Notez 3 enseignements tirés',
        'duree_estimee': '10'
      },
      // Ajoutez plus de défis génériques...
    ];
  }
}

/// Exception personnalisée pour les erreurs n8n
class N8nException implements Exception {
  final int statusCode;
  final String message;

  N8nException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => 'N8nException($statusCode): $message';
}
