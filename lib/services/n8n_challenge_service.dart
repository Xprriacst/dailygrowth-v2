import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class N8nChallengeService {
  static final N8nChallengeService _instance = N8nChallengeService._internal();
  factory N8nChallengeService() => _instance;
  N8nChallengeService._internal();

  static const String webhookUrl = 'https://polaris-ia.app.n8n.cloud/webhook/e4b66ea3-6195-4b11-89fe-85d05d23cae9';

  Dio? _dio;

  Dio get _client {
    if (_dio == null) {
      _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      _dio!.interceptors.add(
        LogInterceptor(
          requestBody: kDebugMode,
          responseBody: kDebugMode,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
      
      debugPrint('✅ N8n Challenge Service initialized');
    }
    return _dio!;
  }

  /// Génère UN SEUL micro-défi via le workflow n8n
  Future<Map<String, dynamic>> generateSingleMicroChallenge({
    required String problematique,
    required int nombreDefisReleves,
    String? userId,
  }) async {
    try {
      debugPrint('🎯 Generating challenges for: $problematique (défis relevés: $nombreDefisReleves)');

      // Préparer les données au format attendu par le workflow
      final requestData = {
        'Je veux...': 'Je veux travailler sur: $problematique',
        'Combien de défi à tu relevé': nombreDefisReleves.toString(),
        if (userId != null) 'user_id': userId,
      };

      final response = await _client.post(
        webhookUrl,
        data: requestData,
        options: Options(
          contentType: 'application/json',
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

      // Validation de la structure pour UN SEUL défi
      if (!responseData.containsKey('defis') || 
          responseData['defis'] is! List ||
          (responseData['defis'] as List).length != 1) {
        throw N8nException(
          statusCode: 500,
          message: 'Structure de réponse invalide: doit contenir exactement 1 défi',
        );
      }

      final defis = responseData['defis'] as List;
      final defi = defis[0];
      
      // Validation du défi unique
      if (defi is! Map || 
          !defi.containsKey('nom') || 
          !defi.containsKey('mission') ||
          !defi.containsKey('pourquoi')) {
        throw N8nException(
          statusCode: 500,
          message: 'Défi incomplet: manque nom, mission ou pourquoi',
        );
      }

      debugPrint('✅ Generated single challenge successfully: ${defi['nom']}');
      return responseData;

    } on DioException catch (e) {
      debugPrint('❌ Dio error: ${e.message}');
      
      if (e.response?.statusCode == 429) {
        throw N8nException(
          statusCode: 429,
          message: 'Quota API dépassé. Veuillez réessayer plus tard.',
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

  /// Génère UN défi avec fallback en cas d'erreur
  Future<Map<String, dynamic>> generateSingleMicroChallengeWithFallback({
    required String problematique,
    required int nombreDefisReleves,
    String? userId,
  }) async {
    try {
      // Essayer d'abord le webhook n8n
      final result = await generateSingleMicroChallenge(
        problematique: problematique,
        nombreDefisReleves: nombreDefisReleves,
        userId: userId,
      );
      
      // Ajouter des métadonnées
      result['source'] = 'n8n_webhook';
      result['generated_at'] = DateTime.now().toIso8601String();
      result['user_id'] = userId;
      
      // Sauvegarder le micro-défi en base de données si userId fourni
      if (userId != null) {
        await _saveSingleMicroChallengeToDatabase(result, userId, problematique, nombreDefisReleves);
      }
      
      return result;
    } catch (e) {
      debugPrint('⚠️ N8n webhook failed, using local fallback: $e');
      
      // Fallback vers la génération locale
      final fallbackResult = _generateLocalFallbackSingleChallenge(
        problematique: problematique,
        nombreDefisReleves: nombreDefisReleves,
        userId: userId,
      );
      
      // Sauvegarder le micro-défi fallback en base de données si userId fourni
      if (userId != null) {
        await _saveSingleMicroChallengeToDatabase(fallbackResult, userId, problematique, nombreDefisReleves);
      }
      
      return fallbackResult;
    }
  }

  /// Sauvegarde UN SEUL micro-défi en base de données
  Future<void> _saveSingleMicroChallengeToDatabase(
    Map<String, dynamic> challengeData,
    String userId,
    String problematique,
    int nombreDefisReleves,
  ) async {
    try {
      final client = Supabase.instance.client;
      final defis = challengeData['defis'] as List;
      final defi = defis[0]; // Un seul défi
      
      final microChallenge = {
        'user_id': userId,
        'problematique': problematique,
        'numero': nombreDefisReleves + 1, // Numéro séquentiel basé sur les défis déjà relevés
        'nom': defi['nom'] ?? 'Défi sans nom',
        'mission': defi['mission'] ?? 'Mission non définie',
        'pourquoi': defi['pourquoi'],
        'bonus': defi['bonus'],
        'duree_estimee': defi['duree_estimee'] ?? '15',
        'niveau_detecte': challengeData['niveau_detecte'],
        'source': challengeData['source'] ?? 'n8n_workflow',
      };

      await client.from('user_micro_challenges').insert(microChallenge);
      
      debugPrint('✅ Saved single micro-challenge to database: ${defi['nom']}');
    } catch (e) {
      debugPrint('❌ Error saving micro-challenge to database: $e');
      // Ne pas faire échouer le processus principal si la sauvegarde échoue
    }
  }
  /// Génère UN SEUL défi de fallback local
  Map<String, dynamic> _generateLocalFallbackSingleChallenge({
    required String problematique,
    required int nombreDefisReleves,
    String? userId,
  }) {
    final niveau = nombreDefisReleves == 0 ? 'débutant' : 
                   nombreDefisReleves <= 5 ? 'intermédiaire' : 'avancé';

    // Sélectionner un défi adapté selon la problématique et le niveau
    Map<String, dynamic> defi;
    
    if (problematique.toLowerCase().contains('confiance')) {
      defi = _getConfidenceChallengeForLevel(niveau, nombreDefisReleves);
    } else if (problematique.toLowerCase().contains('émotion') || 
               problematique.toLowerCase().contains('gestion')) {
      defi = _getEmotionChallengeForLevel(niveau, nombreDefisReleves);
    } else if (problematique.toLowerCase().contains('réseau') || 
               problematique.toLowerCase().contains('charismatique')) {
      defi = _getNetworkingChallengeForLevel(niveau, nombreDefisReleves);
    } else {
      defi = _getGenericChallengeForLevel(niveau, nombreDefisReleves);
    }

    // Ajouter le numéro séquentiel
    defi['numero'] = nombreDefisReleves + 1;

    return {
      'problematique': problematique,
      'niveau_detecte': niveau,
      'defis': [defi], // Un seul défi dans un array
      'source': 'fallback_local',
    };
  }

  // Nouvelles méthodes pour générer un défi selon le niveau
  Map<String, dynamic> _getConfidenceChallengeForLevel(String niveau, int nombreDefisReleves) {
    final challenges = _getConfidenceChallenges();
    final index = nombreDefisReleves % challenges.length;
    
    var challenge = Map<String, dynamic>.from(challenges[index]);
    
    // Adapter la difficulté selon le niveau
    if (niveau == 'avancé') {
      challenge['mission'] = challenge['mission'].toString().replaceAll('3 situations', '5 situations');
      challenge['duree_estimee'] = (int.parse(challenge['duree_estimee']) * 1.5).round().toString();
    }
    
    return challenge;
  }

  Map<String, dynamic> _getEmotionChallengeForLevel(String niveau, int nombreDefisReleves) {
    final challenges = _getEmotionChallenges();
    final index = nombreDefisReleves % challenges.length;
    return Map<String, dynamic>.from(challenges[index]);
  }

  Map<String, dynamic> _getNetworkingChallengeForLevel(String niveau, int nombreDefisReleves) {
    final challenges = _getNetworkingChallenges();
    final index = nombreDefisReleves % challenges.length;
    return Map<String, dynamic>.from(challenges[index]);
  }

  Map<String, dynamic> _getGenericChallengeForLevel(String niveau, int nombreDefisReleves) {
    final challenges = _getGenericChallenges();
    final index = nombreDefisReleves % challenges.length;
    return Map<String, dynamic>.from(challenges[index]);
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
