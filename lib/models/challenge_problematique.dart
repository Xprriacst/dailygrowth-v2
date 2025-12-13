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

  /// Liste complète des 39 problématiques alignées avec le Google Sheets
  static const List<ChallengeProblematique> allProblematiques = [
    // ═══════════════════════════════════════════════════════════════
    // MENTAL & ÉMOTIONNEL (7 problématiques)
    // ═══════════════════════════════════════════════════════════════
    ChallengeProblematique(
      id: 'gerer_emotions',
      title: 'Mieux gérer mes émotions',
      category: 'Mental & émotionnel',
      description: '🧠 Mieux gérer mes émotions',
      emoji: '🧠',
    ),
    ChallengeProblematique(
      id: 'rebondir_echec',
      title: 'Rebondir après un échec',
      category: 'Mental & émotionnel',
      description: '💪 Rebondir après un échec',
      emoji: '💪',
    ),
    ChallengeProblematique(
      id: 'lacher_prise',
      title: 'Apprendre le lâcher-prise',
      category: 'Mental & émotionnel',
      description: '🌊 Apprendre le lâcher-prise',
      emoji: '🌊',
    ),
    ChallengeProblematique(
      id: 'regles_respecter',
      title: 'Me fixer des règles et les respecter',
      category: 'Mental & émotionnel',
      description: '⚡ Me fixer des règles et les respecter',
      emoji: '⚡',
    ),
    ChallengeProblematique(
      id: 'moment_present',
      title: 'Vivre plus dans le moment présent (mindfulness)',
      category: 'Mental & émotionnel',
      description: '🧘 Vivre plus dans le moment présent (mindfulness)',
      emoji: '🧘',
    ),
    ChallengeProblematique(
      id: 'gerer_anxiete_stress',
      title: 'Gérer mon anxiété et mon stress',
      category: 'Mental & émotionnel',
      description: '😰 Gérer mon anxiété et mon stress',
      emoji: '😰',
    ),
    ChallengeProblematique(
      id: 'developper_patience',
      title: 'Développer ma patience',
      category: 'Mental & émotionnel',
      description: '🕰️ Développer ma patience',
      emoji: '🕰️',
    ),

    // ═══════════════════════════════════════════════════════════════
    // RELATIONS & COMMUNICATION (7 problématiques)
    // ═══════════════════════════════════════════════════════════════
    ChallengeProblematique(
      id: 'empathie_ecoute',
      title: 'Être plus empathique et développer mon écoute active',
      category: 'Relations & communication',
      description: '👂 Être plus empathique et développer mon écoute active',
      emoji: '👂',
    ),
    ChallengeProblematique(
      id: 'charisme_reseau',
      title: 'Devenir plus charismatique et développer mon réseau',
      category: 'Relations & communication',
      description: '🤝 Devenir plus charismatique et développer mon réseau',
      emoji: '🤝',
    ),
    ChallengeProblematique(
      id: 'affirmer_sans_blesser',
      title: 'M\'affirmer (oser dire les choses sans blesser)',
      category: 'Relations & communication',
      description: '💬 M\'affirmer (oser dire les choses sans blesser)',
      emoji: '💬',
    ),
    ChallengeProblematique(
      id: 'surmonter_timidite',
      title: 'Surmonter ma timidité et oser m\'exprimer',
      category: 'Relations & communication',
      description: '😶 Surmonter ma timidité et oser m\'exprimer',
      emoji: '😶',
    ),
    ChallengeProblematique(
      id: 'gerer_conflits_critiques',
      title: 'Mieux gérer les conflits et critiques',
      category: 'Relations & communication',
      description: '⚖️ Mieux gérer les conflits et critiques',
      emoji: '⚖️',
    ),
    ChallengeProblematique(
      id: 'relations_amoureuses',
      title: 'Développer des relations amoureuses saines',
      category: 'Relations & communication',
      description: '💕 Développer des relations amoureuses saines',
      emoji: '💕',
    ),
    ChallengeProblematique(
      id: 'relations_amicales',
      title: 'Améliorer mes relations amicales',
      category: 'Relations & communication',
      description: '🤝 Améliorer mes relations amicales',
      emoji: '🤝',
    ),

    // ═══════════════════════════════════════════════════════════════
    // ARGENT & CARRIÈRE (9 problématiques)
    // ═══════════════════════════════════════════════════════════════
    ChallengeProblematique(
      id: 'entreprendre_creativite',
      title: 'Entreprendre et développer ma créativité',
      category: 'Argent & carrière',
      description: '🚀 Entreprendre et développer ma créativité',
      emoji: '🚀',
    ),
    ChallengeProblematique(
      id: 'diversifier_revenus',
      title: 'Diversifier mes sources de revenus',
      category: 'Argent & carrière',
      description: '💰 Diversifier mes sources de revenus',
      emoji: '💰',
    ),
    ChallengeProblematique(
      id: 'risques_calcules_decisions',
      title: 'Prendre des risques calculés / mieux prendre des décisions',
      category: 'Argent & carrière',
      description: '🎯 Prendre des risques calculés / mieux prendre des décisions',
      emoji: '🎯',
    ),
    ChallengeProblematique(
      id: 'trouver_passion',
      title: 'Trouver ma passion',
      category: 'Argent & carrière',
      description: '✨ Trouver ma passion',
      emoji: '✨',
    ),
    ChallengeProblematique(
      id: 'vivre_passion',
      title: 'Vivre de ma passion',
      category: 'Argent & carrière',
      description: '🌟 Vivre de ma passion',
      emoji: '🌟',
    ),
    ChallengeProblematique(
      id: 'gerer_finances',
      title: 'Mieux gérer mon argent et mes finances personnelles',
      category: 'Argent & carrière',
      description: '📊 Mieux gérer mon argent et mes finances personnelles',
      emoji: '📊',
    ),
    ChallengeProblematique(
      id: 'equilibre_vie_pro_perso',
      title: 'Trouver un meilleur équilibre entre vie perso et pro',
      category: 'Argent & carrière',
      description: '🏡💼 Trouver un meilleur équilibre entre vie perso et pro',
      emoji: '🏡',
    ),
    ChallengeProblematique(
      id: 'resilience_travail',
      title: 'Développer ma résilience au travail',
      category: 'Argent & carrière',
      description: '🏋️ Développer ma résilience au travail',
      emoji: '🏋️',
    ),
    ChallengeProblematique(
      id: 'leadership',
      title: 'Développer mes compétences en leadership',
      category: 'Argent & carrière',
      description: '🦁 Développer mes compétences en leadership',
      emoji: '🦁',
    ),

    // ═══════════════════════════════════════════════════════════════
    // SANTÉ & HABITUDES DE VIE (5 problématiques)
    // ═══════════════════════════════════════════════════════════════
    ChallengeProblematique(
      id: 'sortir_dependance',
      title: 'Sortir de ma dépendance',
      category: 'Santé & habitudes de vie',
      description: '🚫 Sortir de ma dépendance',
      emoji: '🚫',
    ),
    ChallengeProblematique(
      id: 'ameliorer_cardio',
      title: 'Améliorer mon cardio',
      category: 'Santé & habitudes de vie',
      description: '❤️ Améliorer mon cardio',
      emoji: '❤️',
    ),
    ChallengeProblematique(
      id: 'perdre_poids',
      title: 'Perdre du poids',
      category: 'Santé & habitudes de vie',
      description: '⚖️ Perdre du poids',
      emoji: '⚖️',
    ),
    ChallengeProblematique(
      id: 'reduire_temps_ecran',
      title: 'Réduire mon temps d\'écran',
      category: 'Santé & habitudes de vie',
      description: '📵 Réduire mon temps d\'écran',
      emoji: '📵',
    ),
    ChallengeProblematique(
      id: 'ameliorer_sommeil',
      title: 'Améliorer la qualité de mon sommeil',
      category: 'Santé & habitudes de vie',
      description: '💤 Améliorer la qualité de mon sommeil',
      emoji: '💤',
    ),

    // ═══════════════════════════════════════════════════════════════
    // PRODUCTIVITÉ & CONCENTRATION (6 problématiques)
    // ═══════════════════════════════════════════════════════════════
    ChallengeProblematique(
      id: 'organiser_gerer_temps',
      title: 'Mieux m\'organiser / Gérer mon temps efficacement',
      category: 'Productivité & concentration',
      description: '📅 Mieux m\'organiser / Gérer mon temps efficacement',
      emoji: '📅',
    ),
    ChallengeProblematique(
      id: 'arreter_procrastiner_concentration',
      title: 'Arrêter de procrastiner / améliorer ma concentration',
      category: 'Productivité & concentration',
      description: '⏰ Arrêter de procrastiner / améliorer ma concentration',
      emoji: '⏰',
    ),
    ChallengeProblematique(
      id: 'ne_pas_abandonner',
      title: 'Ne pas abandonner trop vite',
      category: 'Productivité & concentration',
      description: '🔥 Ne pas abandonner trop vite',
      emoji: '🔥',
    ),
    ChallengeProblematique(
      id: 'definir_priorites',
      title: 'Définir mes priorités',
      category: 'Productivité & concentration',
      description: '🎯 Définir mes priorités',
      emoji: '🎯',
    ),
    ChallengeProblematique(
      id: 'planifier_vie',
      title: 'Planifier ma vie à court et moyen terme',
      category: 'Productivité & concentration',
      description: '🗺️ Planifier ma vie à court et moyen terme',
      emoji: '🗺️',
    ),
    ChallengeProblematique(
      id: 'routine_matinale_soiree',
      title: 'Développer une routine matinale/soirée efficace',
      category: 'Productivité & concentration',
      description: '🌅 Développer une routine matinale/soirée efficace',
      emoji: '🌅',
    ),

    // ═══════════════════════════════════════════════════════════════
    // CONFIANCE & IDENTITÉ (5 problématiques)
    // ═══════════════════════════════════════════════════════════════
    ChallengeProblematique(
      id: 'confiance_en_soi',
      title: 'Prendre confiance en moi (sans écraser les autres)',
      category: 'Confiance & identité',
      description: '💪 Prendre confiance en moi (sans écraser les autres)',
      emoji: '💪',
    ),
    ChallengeProblematique(
      id: 'apprendre_dire_non',
      title: 'Apprendre à dire non',
      category: 'Confiance & identité',
      description: '🛡️ Apprendre à dire non',
      emoji: '🛡️',
    ),
    ChallengeProblematique(
      id: 'arreter_comparaison',
      title: 'Arrêter de me comparer aux autres',
      category: 'Confiance & identité',
      description: '🔍 Arrêter de me comparer aux autres',
      emoji: '🔍',
    ),
    ChallengeProblematique(
      id: 'accepter_qui_je_suis',
      title: 'Accepter qui je suis',
      category: 'Confiance & identité',
      description: '🤗 Accepter qui je suis',
      emoji: '🤗',
    ),
    ChallengeProblematique(
      id: 'trouver_sens_vie',
      title: 'Trouver du sens dans ma vie',
      category: 'Confiance & identité',
      description: '🔎 Trouver du sens dans ma vie',
      emoji: '🔎',
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
