class ChallengeProblematique {
  final String id;
  final String title;
  final String category;
  final String description;
  final String emoji;

  const ChallengeProblematique({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.emoji,
  });

  static const List<ChallengeProblematique> allProblematiques = [
    // Mental & émotionnel
    ChallengeProblematique(
      id: 'gerer_emotions',
      title: 'Mieux gérer mes émotions',
      category: 'Mental & émotionnel',
      description: 'mieux gerer mes emotions (jalousie, hyspersensibilité...)',
      emoji: '🧠',
    ),
    ChallengeProblematique(
      id: 'rebondir_echec',
      title: 'Rebondir après un échec',
      category: 'Mental & émotionnel',
      description: 'pouvoir rebondir après un échec',
      emoji: '💪',
    ),
    ChallengeProblematique(
      id: 'lacher_prise',
      title: 'Apprendre le lâcher-prise',
      category: 'Mental & émotionnel',
      description: 'apprendre à lacher-prise, arreter de vouloir tout maitriser',
      emoji: '🌊',
    ),
    ChallengeProblematique(
      id: 'regles_respecter',
      title: 'Me fixer des règles et les respecter',
      category: 'Mental & émotionnel',
      description: 'pouvoir me fixer des rêgles et les respecter',
      emoji: '⚡',
    ),

    // Relations & communication
    ChallengeProblematique(
      id: 'empathie_ecoute',
      title: 'Être plus empathique et développer mon écoute active',
      category: 'Relations & communication',
      description: 'etre plus empathique et développer mon écoute acitve',
      emoji: '👂',
    ),
    ChallengeProblematique(
      id: 'charisme_reseau',
      title: 'Devenir plus charismatique et développer mon réseau',
      category: 'Relations & communication',
      description: 'devenir plus charismatique et développer mon réseau',
      emoji: '🤝',
    ),
    ChallengeProblematique(
      id: 'affirmer_sans_blesser',
      title: 'M\'affirmer (oser dire les choses sans blesser)',
      category: 'Relations & communication',
      description: 'maffirmer (oser dire les choses sans blesser)',
      emoji: '💬',
    ),
    ChallengeProblematique(
      id: 'gerer_conflits',
      title: 'Mieux gérer les conflits',
      category: 'Relations & communication',
      description: 'Mieux gérer les conflits',
      emoji: '⚖️',
    ),

    // Argent & carrière
    ChallengeProblematique(
      id: 'entreprendre_creativite',
      title: 'Entreprendre et développer ma créativité',
      category: 'Argent & carrière',
      description: 'entreprendre et développer ma créativité',
      emoji: '🚀',
    ),
    ChallengeProblematique(
      id: 'diversifier_revenus',
      title: 'Diversifier mes sources de revenus',
      category: 'Argent & carrière',
      description: 'Diversifier mes sources de revenus',
      emoji: '💰',
    ),
    ChallengeProblematique(
      id: 'risques_calcules',
      title: 'Prendre des risques calculés',
      category: 'Argent & carrière',
      description: 'Prendre des risques calculés',
      emoji: '🎯',
    ),
    ChallengeProblematique(
      id: 'trouver_passion',
      title: 'Trouver ma passion',
      category: 'Argent & carrière',
      description: 'trouver ma passion',
      emoji: '✨',
    ),
    ChallengeProblematique(
      id: 'vivre_passion',
      title: 'Vivre de ma passion',
      category: 'Argent & carrière',
      description: 'vivre de ma passion',
      emoji: '🌟',
    ),

    // Santé & habitudes de vie
    ChallengeProblematique(
      id: 'sortir_dependance',
      title: 'Sortir de ma dépendance',
      category: 'Santé & habitudes de vie',
      description: 'Sortir de ma dépendance (alcool, tabac, drogue, réseaux sociaux, jeux d\'argent, jeux vidéo, pornographie…)',
      emoji: '🚫',
    ),
    ChallengeProblematique(
      id: 'ameliorer_cardio',
      title: 'Améliorer mon cardio',
      category: 'Santé & habitudes de vie',
      description: 'Améliorer mon cardio',
      emoji: '❤️',
    ),
    ChallengeProblematique(
      id: 'perdre_poids',
      title: 'Perdre du poids',
      category: 'Santé & habitudes de vie',
      description: 'Perdre du poids',
      emoji: '⚖️',
    ),

    // Productivité & concentration
    ChallengeProblematique(
      id: 'mieux_organiser',
      title: 'Mieux m\'organiser',
      category: 'Productivité & concentration',
      description: 'Mieux m\'organiser',
      emoji: '📅',
    ),
    ChallengeProblematique(
      id: 'arreter_procrastiner',
      title: 'Arrêter de procrastiner',
      category: 'Productivité & concentration',
      description: 'Areter de de procrastiner',
      emoji: '⏰',
    ),
    ChallengeProblematique(
      id: 'ne_pas_abandonner',
      title: 'Ne pas abandonner trop vite',
      category: 'Productivité & concentration',
      description: 'Apprendre à ne pas abandonner trop vite',
      emoji: '🔥',
    ),
    ChallengeProblematique(
      id: 'definir_priorites',
      title: 'Définir mes priorités',
      category: 'Productivité & concentration',
      description: 'Définir mes priorités',
      emoji: '🎯',
    ),
    ChallengeProblematique(
      id: 'planifier_vie',
      title: 'Planifier ma vie à court et moyen terme',
      category: 'Productivité & concentration',
      description: 'Réussir à planifier ma vie à court et moyen terme',
      emoji: '🗺️',
    ),

    // Confiance & identité
    ChallengeProblematique(
      id: 'confiance_en_soi',
      title: 'Prendre confiance en moi (sans écraser les autres)',
      category: 'Confiance & identité',
      description: 'Prendre en confiance en moi (sans ecraser les autres)',
      emoji: '💪',
    ),
    ChallengeProblematique(
      id: 'apprendre_dire_non',
      title: 'Apprendre à dire non',
      category: 'Confiance & identité',
      description: 'Apprendre à dire non',
      emoji: '🛡️',
    ),
    ChallengeProblematique(
      id: 'arreter_comparaison',
      title: 'Arrêter de me comparer aux autres',
      category: 'Confiance & identité',
      description: 'Arrete de me comparer avec les autres (réseaux sociaux, pression sociale)',
      emoji: '🔍',
    ),
    ChallengeProblematique(
      id: 'accepter_qui_je_suis',
      title: 'Accepter qui je suis',
      category: 'Confiance & identité',
      description: 'Accepter qui je suis (physique, personnalité, différences)',
      emoji: '🤗',
    ),
  ];

  static List<String> get allCategories {
    return allProblematiques
        .map((p) => p.category)
        .toSet()
        .toList();
  }

  static List<ChallengeProblematique> getByCategory(String category) {
    return allProblematiques
        .where((p) => p.category == category)
        .toList();
  }

  static ChallengeProblematique? getById(String id) {
    try {
      return allProblematiques.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}
