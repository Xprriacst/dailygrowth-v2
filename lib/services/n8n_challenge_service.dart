import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class N8nChallengeService {
  static final N8nChallengeService _instance = N8nChallengeService._internal();
  factory N8nChallengeService() => _instance;
  N8nChallengeService._internal();

  Map<String, List<Map<String, dynamic>>>? _staticChallenges;
  bool _isLoaded = false;

  /// Charge les défis statiques depuis le fichier JSON
  Future<void> _loadStaticChallenges() async {
    if (_isLoaded) return;
    
    try {
      final String jsonString = await rootBundle.loadString('assets/data/challenges.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      _staticChallenges = {};
      jsonData.forEach((key, value) {
        _staticChallenges![key] = List<Map<String, dynamic>>.from(
          (value as List).map((item) => Map<String, dynamic>.from(item))
        );
      });
      
      _isLoaded = true;
      debugPrint('✅ [StaticChallenges] Loaded ${_staticChallenges!.length} problématiques');
    } catch (e) {
      debugPrint('❌ [StaticChallenges] Error loading challenges: $e');
      _staticChallenges = {};
    }
  }

  /// Trouve la meilleure correspondance de problématique
  String? _findMatchingProblematique(String userProblematique) {
    if (_staticChallenges == null) return null;
    
    final normalizedInput = _normalizeString(userProblematique);
    
    // Recherche exacte d'abord
    for (final key in _staticChallenges!.keys) {
      if (_normalizeString(key) == normalizedInput) {
        return key;
      }
    }
    
    // Recherche par mots-clés
    for (final key in _staticChallenges!.keys) {
      final normalizedKey = _normalizeString(key);
      if (normalizedKey.contains(normalizedInput) || normalizedInput.contains(normalizedKey)) {
        return key;
      }
    }
    
    // Recherche par mots communs
    final inputWords = normalizedInput.split(' ').where((w) => w.length > 3).toSet();
    String? bestMatch;
    int bestScore = 0;
    
    for (final key in _staticChallenges!.keys) {
      final keyWords = _normalizeString(key).split(' ').where((w) => w.length > 3).toSet();
      final commonWords = inputWords.intersection(keyWords).length;
      if (commonWords > bestScore) {
        bestScore = commonWords;
        bestMatch = key;
      }
    }
    
    return bestMatch;
  }

  String _normalizeString(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[🧠💪🌊⚡👂🤝💬😶⚖️🚀💰🎯✨🌟🚫❤️📅⏰🔥🗺️🛡️🔍🤗📵🧘🌅📊🏡💼🔎😰🕰️💕🏋️💤🦁]'), '')
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Génère UN SEUL micro-défi depuis les défis statiques
  Future<Map<String, dynamic>> generateSingleMicroChallenge({
    required String problematique,
    required int nombreDefisReleves,
    String? userId,
  }) async {
    debugPrint('🎯 [StaticChallenges] Generating challenge for: $problematique (défis relevés: $nombreDefisReleves)');
    
    // Charger les défis si pas encore fait
    await _loadStaticChallenges();
    
    // Trouver la problématique correspondante
    final matchedProblematique = _findMatchingProblematique(problematique);
    
    if (matchedProblematique == null || _staticChallenges![matchedProblematique] == null) {
      debugPrint('⚠️ [StaticChallenges] No matching problematique found for: $problematique');
      debugPrint('📋 [StaticChallenges] Available: ${_staticChallenges?.keys.toList()}');
      throw N8nException(
        statusCode: 404,
        message: 'Aucune problématique correspondante trouvée',
      );
    }
    
    debugPrint('✅ [StaticChallenges] Matched problematique: $matchedProblematique');
    
    final challenges = _staticChallenges![matchedProblematique]!;
    final totalChallenges = challenges.length; // Généralement 30
    
    // Vérifier si l'utilisateur a complété tous les défis de cette problématique
    if (nombreDefisReleves >= totalChallenges) {
      debugPrint('🎉 [StaticChallenges] User completed all $totalChallenges challenges for: $matchedProblematique');
      
      // Retourner un message de félicitations
      final completionDefi = {
        'nom': '🎉 Félicitations !',
        'mission': 'Bravo ! Tu as relevé les $totalChallenges défis de "$matchedProblematique" ! C\'est une vraie réussite. Tu peux maintenant choisir une nouvelle problématique pour continuer ta progression.',
        'pourquoi': 'Tu as fait preuve de persévérance et d\'engagement. Chaque défi t\'a permis de grandir et de te rapprocher de tes objectifs.',
        'bonus': null,
        'duree_estimee': '0',
        'numero': totalChallenges,
        'difficulte': 3,
        'is_completed': true, // Flag pour indiquer que la problématique est terminée
      };
      
      return {
        'problematique': matchedProblematique,
        'niveau_detecte': 'expert',
        'defis': [completionDefi],
        'source': 'static_challenges',
        'problematique_completed': true, // Flag pour l'UI
      };
    }
    
    // Calculer le numéro du défi (1 à 30)
    final challengeNumero = nombreDefisReleves + 1;
    
    // Trouver le défi correspondant
    Map<String, dynamic>? selectedChallenge;
    for (final challenge in challenges) {
      if (challenge['numero'] == challengeNumero) {
        selectedChallenge = Map<String, dynamic>.from(challenge);
        break;
      }
    }
    
    if (selectedChallenge == null) {
      // Fallback au premier défi si pas trouvé
      selectedChallenge = Map<String, dynamic>.from(challenges[0]);
    }
    
    // Déterminer le niveau
    final niveau = nombreDefisReleves == 0 ? 'débutant' : 
                   nombreDefisReleves <= 10 ? 'intermédiaire' : 'avancé';
    
    // Construire le défi au format attendu
    final defi = {
      'nom': 'Défi #$challengeNumero',
      'mission': selectedChallenge['mission'],
      'pourquoi': 'Ce défi fait partie de ton parcours "$matchedProblematique" et t\'aide à progresser étape par étape.',
      'bonus': null,
      'duree_estimee': '15',
      'numero': challengeNumero,
      'difficulte': selectedChallenge['difficulte'],
    };
    
    debugPrint('✅ [StaticChallenges] Generated challenge #$challengeNumero/$totalChallenges: ${defi['mission']?.toString().substring(0, 50)}...');
    
    return {
      'problematique': matchedProblematique,
      'niveau_detecte': niveau,
      'defis': [defi],
      'source': 'static_challenges',
      'progress': '$challengeNumero/$totalChallenges', // Info de progression
    };
  }

  /// Génère UN défi (plus de fallback nécessaire car on utilise les défis statiques)
  Future<Map<String, dynamic>> generateSingleMicroChallengeWithFallback({
    required String problematique,
    required int nombreDefisReleves,
    String? userId,
  }) async {
    try {
      // Utiliser directement les défis statiques
      final result = await generateSingleMicroChallenge(
        problematique: problematique,
        nombreDefisReleves: nombreDefisReleves,
        userId: userId,
      );
      
      // Ajouter des métadonnées
      result['generated_at'] = DateTime.now().toIso8601String();
      result['user_id'] = userId;
      
      // Sauvegarder le micro-défi en base de données si userId fourni
      if (userId != null) {
        await _saveSingleMicroChallengeToDatabase(result, userId, problematique, nombreDefisReleves);
      }
      
      return result;
    } catch (e) {
      debugPrint('⚠️ [StaticChallenges] Static challenges failed, using hardcoded fallback: $e');
      
      // Fallback vers la génération locale hardcodée
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
