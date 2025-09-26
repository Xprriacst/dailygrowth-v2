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
    ChallengeProblematique(
      id: 'moment_present',
      title: 'Vivre plus dans le moment présent (mindfulness)',
      category: 'Mental & émotionnel',
      description: 'vivre plus dans le moment présent, développer la mindfulness',
      emoji: '🧘',
    ),
    ChallengeProblematique(
      id: 'gerer_anxiete_stress',
      title: 'Gérer mon anxiété et mon stress',
      category: 'Mental & émotionnel',
      description: 'gérer mon anxiété et mon stress au quotidien',
      emoji: '😌',
    ),
    ChallengeProblematique(
      id: 'developper_patience',
      title: 'Développer ma patience',
      category: 'Mental & émotionnel',
      description: 'développer ma patience dans toutes les situations',
      emoji: '⏳',
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
      id: 'surmonter_timidite',
      title: 'Surmonter ma timidité et oser m\'exprimer',
      category: 'Relations & communication',
      description: 'surmonter ma timidité et oser m\'exprimer en public',
      emoji: '🗣️',
    ),
    ChallengeProblematique(
      id: 'gerer_conflits_critiques',
      title: 'Mieux gérer les conflits et critiques',
      category: 'Relations & communication',
      description: 'mieux gérer les conflits et accepter les critiques constructives',
      emoji: '⚖️',
    ),
    ChallengeProblematique(
      id: 'relations_amoureuses',
      title: 'Développer des relations amoureuses saines',
      category: 'Relations & communication',
      description: 'développer des relations amoureuses saines et équilibrées',
      emoji: '💕',
    ),
    ChallengeProblematique(
      id: 'relations_amicales',
      title: 'Améliorer mes relations amicales',
      category: 'Relations & communication',
      description: 'améliorer mes relations amicales et créer des liens durables',
      emoji: '👥',
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
      id: 'risques_calcules_decisions',
      title: 'Prendre des risques calculés / mieux prendre des décisions',
      category: 'Argent & carrière',
      description: 'prendre des risques calculés et améliorer ma prise de décision',
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
    ChallengeProblematique(
      id: 'gerer_finances',
      title: 'Mieux gérer mon argent et mes finances personnelles',
      category: 'Argent & carrière',
      description: 'mieux gérer mon argent et mes finances personnelles',
      emoji: '💳',
    ),
    ChallengeProblematique(
      id: 'equilibre_vie_pro_perso',
      title: 'Trouver un meilleur équilibre entre vie perso et pro',
      category: 'Argent & carrière',
      description: 'trouver un meilleur équilibre entre vie personnelle et professionnelle',
      emoji: '⚖️',
    ),
    ChallengeProblematique(
      id: 'resilience_travail',
      title: 'Développer ma résilience au travail',
      category: 'Argent & carrière',
      description: 'développer ma résilience et ma capacité d\'adaptation au travail',
      emoji: '🛡️',
    ),
    ChallengeProblematique(
      id: 'leadership',
      title: 'Développer mes compétences en leadership',
      category: 'Argent & carrière',
      description: 'développer mes compétences en leadership et management',
      emoji: '👑',
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
    ChallengeProblematique(
      id: 'reduire_temps_ecran',
      title: 'Réduire mon temps d\'écran',
      category: 'Santé & habitudes de vie',
      description: 'réduire mon temps d\'écran et ma dépendance aux écrans',
      emoji: '📱',
    ),
    ChallengeProblematique(
      id: 'ameliorer_sommeil',
      title: 'Améliorer la qualité de mon sommeil',
      category: 'Santé & habitudes de vie',
      description: 'améliorer la qualité de mon sommeil et mes habitudes de coucher',
      emoji: '😴',
    ),

    // Productivité & concentration
    ChallengeProblematique(
      id: 'organiser_gerer_temps',
      title: 'Mieux m\'organiser / Gérer mon temps efficacement',
      category: 'Productivité & concentration',
      description: 'mieux m\'organiser et gérer mon temps efficacement',
      emoji: '📅',
    ),
    ChallengeProblematique(
      id: 'arreter_procrastiner_concentration',
      title: 'Arrêter de procrastiner / améliorer ma concentration',
      category: 'Productivité & concentration',
      description: 'arrêter de procrastiner et améliorer ma concentration',
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
    ChallengeProblematique(
      id: 'routine_matinale_soiree',
      title: 'Développer une routine matinale/soirée efficace',
      category: 'Productivité & concentration',
      description: 'développer une routine matinale et/ou soirée efficace',
      emoji: '🌅',
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
    ChallengeProblematique(
      id: 'trouver_sens_vie',
      title: 'Trouver du sens dans ma vie',
      category: 'Confiance & identité',
      description: 'trouver du sens et un but dans ma vie',
      emoji: '🌟',
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
