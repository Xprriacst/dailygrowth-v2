import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import './supabase_service.dart';
import './user_service.dart';
import './notification_service.dart';

class GamificationService {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  late final SupabaseClient _client;
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      _client = await SupabaseService().client;
      await _userService.initialize();
      await _notificationService.initialize();
      _isInitialized = true;
    }
  }

  // Award achievement to user
  Future<Map<String, dynamic>?> awardAchievement({
    required String userId,
    required String achievementType,
    required String achievementName,
    required String description,
    required String iconName,
    int pointsEarned = 0,
  }) async {
    try {
      // Check if achievement already exists
      final existingAchievement = await _client
          .from('user_achievements')
          .select()
          .eq('user_id', userId)
          .eq('achievement_type', achievementType)
          .eq('achievement_name', achievementName)
          .maybeSingle();

      if (existingAchievement != null) {
        return null; // Achievement already exists
      }

      // Create new achievement
      final achievement = await _userService.addAchievement(
        userId: userId,
        achievementType: achievementType,
        achievementName: achievementName,
        description: description,
        iconName: iconName,
        pointsEarned: pointsEarned,
      );

      // Send notification
      await _notificationService.sendAchievementNotification(
        userId: userId,
        achievementName: achievementName,
        description: description,
        pointsEarned: pointsEarned,
      );

      return achievement;
    } catch (error) {
      debugPrint('Error awarding achievement: $error');
      return null;
    }
  }

  // Check and award streak-based achievements
  Future<void> checkStreakAchievements(String userId) async {
    try {
      final userProfile = await _userService.getUserProfile(userId);
      if (userProfile == null) return;

      final streakCount = userProfile['streak_count'] as int? ?? 0;

      // Define streak achievements
      final streakMilestones = [
        {'days': 3, 'name': 'Premier Élan', 'description': '3 jours consécutifs', 'points': 50},
        {'days': 7, 'name': 'Semaine Parfaite', 'description': '7 jours consécutifs', 'points': 100},
        {'days': 14, 'name': 'Deux Semaines de Force', 'description': '14 jours consécutifs', 'points': 200},
        {'days': 30, 'name': 'Mois de Détermination', 'description': '30 jours consécutifs', 'points': 500},
        {'days': 60, 'name': 'Deux Mois de Constance', 'description': '60 jours consécutifs', 'points': 750},
        {'days': 100, 'name': 'Centurion', 'description': '100 jours consécutifs', 'points': 1000},
        {'days': 365, 'name': 'Année de Croissance', 'description': '365 jours consécutifs', 'points': 2000},
      ];

      for (final milestone in streakMilestones) {
        if (streakCount >= (milestone['days'] as int)) {
          await awardAchievement(
            userId: userId,
            achievementType: 'streak',
            achievementName: milestone['name'] as String,
            description: milestone['description'] as String,
            iconName: 'local_fire_department',
            pointsEarned: milestone['points'] as int,
          );
        }
      }

      // Send streak milestone notification
      if ([3, 7, 14, 30, 60, 100, 365].contains(streakCount)) {
        await _notificationService.sendStreakMilestoneNotification(
          userId: userId,
          streakCount: streakCount,
        );
      }
    } catch (error) {
      debugPrint('Error checking streak achievements: $error');
    }
  }

  // Check and award challenge completion achievements
  Future<void> checkChallengeAchievements(String userId) async {
    try {
      final completedChallengesResult = await _client
          .from('daily_challenges')
          .select()
          .eq('user_id', userId)
          .eq('status', 'completed')
          .count();

      final completedCount = completedChallengesResult.count ?? 0;

      // Define challenge achievements
      final challengeMilestones = [
        {'count': 1, 'name': 'Premier Pas', 'description': 'Premier défi complété', 'points': 25},
        {'count': 5, 'name': 'Débutant Motivé', 'description': '5 défis complétés', 'points': 75},
        {'count': 10, 'name': 'Explorateur', 'description': '10 défis complétés', 'points': 150},
        {'count': 25, 'name': 'Aventurier', 'description': '25 défis complétés', 'points': 300},
        {'count': 50, 'name': 'Expert', 'description': '50 défis complétés', 'points': 500},
        {'count': 100, 'name': 'Maître des Défis', 'description': '100 défis complétés', 'points': 1000},
        {'count': 250, 'name': 'Légende', 'description': '250 défis complétés', 'points': 2000},
      ];

      for (final milestone in challengeMilestones) {
        if (completedCount >= (milestone['count'] as int)) {
          await awardAchievement(
            userId: userId,
            achievementType: 'challenges',
            achievementName: milestone['name'] as String,
            description: milestone['description'] as String,
            iconName: 'emoji_events',
            pointsEarned: milestone['points'] as int,
          );
        }
      }
    } catch (error) {
      debugPrint('Error checking challenge achievements: $error');
    }
  }

  // Check and award domain-specific achievements
  Future<void> checkDomainAchievements(String userId) async {
    try {
      // Get challenges by domain
      final challengesResponse = await _client
          .from('daily_challenges')
          .select('life_domain')
          .eq('user_id', userId)
          .eq('status', 'completed');

      final challenges = List<Map<String, dynamic>>.from(challengesResponse);
      
      // Count challenges per domain
      final domainCounts = <String, int>{};
      for (final challenge in challenges) {
        final domain = challenge['life_domain'] as String;
        domainCounts[domain] = (domainCounts[domain] ?? 0) + 1;
      }

      // Domain-specific achievements
      final domainAchievements = {
        'sante': {'name': 'Gardien de la Santé', 'icon': 'favorite'},
        'relations': {'name': 'Maître des Relations', 'icon': 'people'},
        'carriere': {'name': 'Professionnel Accompli', 'icon': 'work'},
        'finances': {'name': 'Gestionnaire Avisé', 'icon': 'account_balance'},
        'developpement': {'name': 'Éternel Apprenant', 'icon': 'school'},
        'spiritualite': {'name': 'Âme Éclairée', 'icon': 'self_improvement'},
        'loisirs': {'name': 'Passionné Créatif', 'icon': 'palette'},
        'famille': {'name': 'Pilier Familial', 'icon': 'home'},
      };

      for (final entry in domainCounts.entries) {
        final domain = entry.key;
        final count = entry.value;
        final achievement = domainAchievements[domain];

        if (achievement != null && count >= 10) {
          await awardAchievement(
            userId: userId,
            achievementType: 'domain',
            achievementName: achievement['name'] as String,
            description: 'Expert du domaine ${_getDomainName(domain)}',
            iconName: achievement['icon'] as String,
            pointsEarned: 200,
          );
        }
      }
    } catch (error) {
      debugPrint('Error checking domain achievements: $error');
    }
  }

  // Check and award time-based achievements
  Future<void> checkTimeAchievements(String userId) async {
    try {
      final userProfile = await _userService.getUserProfile(userId);
      if (userProfile == null) return;

      final createdAt = DateTime.parse(userProfile['created_at']);
      final now = DateTime.now();
      final daysSinceJoining = now.difference(createdAt).inDays;

      // Time-based achievements
      final timeAchievements = [
        {'days': 7, 'name': 'Première Semaine', 'description': 'Une semaine dans l\'app', 'points': 50},
        {'days': 30, 'name': 'Premier Mois', 'description': 'Un mois de croissance', 'points': 100},
        {'days': 90, 'name': 'Trimestre Complet', 'description': 'Trois mois de fidélité', 'points': 300},
        {'days': 365, 'name': 'Anniversaire', 'description': 'Une année de développement', 'points': 1000},
      ];

      for (final achievement in timeAchievements) {
        if (daysSinceJoining >= (achievement['days'] as int)) {
          await awardAchievement(
            userId: userId,
            achievementType: 'time',
            achievementName: achievement['name'] as String,
            description: achievement['description'] as String,
            iconName: 'cake',
            pointsEarned: achievement['points'] as int,
          );
        }
      }
    } catch (error) {
      debugPrint('Error checking time achievements: $error');
    }
  }

  // Calculate user level based on total points
  Map<String, dynamic> calculateUserLevel(int totalPoints) {
    // Level thresholds
    final levels = [
      {'level': 1, 'name': 'Novice', 'minPoints': 0, 'maxPoints': 99, 'color': '#9E9E9E'},
      {'level': 2, 'name': 'Apprenti', 'minPoints': 100, 'maxPoints': 299, 'color': '#4CAF50'},
      {'level': 3, 'name': 'Pratiquant', 'minPoints': 300, 'maxPoints': 599, 'color': '#2196F3'},
      {'level': 4, 'name': 'Expert', 'minPoints': 600, 'maxPoints': 999, 'color': '#9C27B0'},
      {'level': 5, 'name': 'Maître', 'minPoints': 1000, 'maxPoints': 1999, 'color': '#FF9800'},
      {'level': 6, 'name': 'Grand Maître', 'minPoints': 2000, 'maxPoints': 3999, 'color': '#F44336'},
      {'level': 7, 'name': 'Légende', 'minPoints': 4000, 'maxPoints': 7999, 'color': '#E91E63'},
      {'level': 8, 'name': 'Mythique', 'minPoints': 8000, 'maxPoints': 15999, 'color': '#3F51B5'},
      {'level': 9, 'name': 'Transcendant', 'minPoints': 16000, 'maxPoints': 31999, 'color': '#673AB7'},
      {'level': 10, 'name': 'Illuminé', 'minPoints': 32000, 'maxPoints': 999999, 'color': '#FFD700'},
    ];

    for (final level in levels) {
      if (totalPoints >= (level['minPoints'] as int) && totalPoints <= (level['maxPoints'] as int)) {
        final nextLevel = levels.where((l) => (l['level'] as int) > (level['level'] as int)).firstOrNull;
        return {
          'current_level': level['level'],
          'level_name': level['name'],
          'level_color': level['color'],
          'current_points': totalPoints,
          'points_for_next_level': nextLevel != null ? nextLevel['minPoints'] as int : null,
          'progress_percentage': nextLevel != null 
              ? ((totalPoints - (level['minPoints'] as int)) / 
                 ((nextLevel['minPoints'] as int) - (level['minPoints'] as int)) * 100).clamp(0, 100)
              : 100.0,
        };
      }
    }

    return levels.first;
  }

  // Get user's badge collection
  Future<List<Map<String, dynamic>>> getUserBadges(String userId) async {
    try {
      final achievements = await _userService.getUserAchievements(userId);
      
      return achievements.map((achievement) => {
        'id': achievement['id'],
        'name': achievement['achievement_name'],
        'description': achievement['description'],
        'type': achievement['achievement_type'],
        'icon': achievement['icon_name'],
        'points': achievement['points_earned'],
        'unlocked_at': achievement['unlocked_at'],
        'rarity': _getBadgeRarity(achievement['achievement_type'], achievement['points_earned']),
      }).toList();
    } catch (error) {
      debugPrint('Error getting user badges: $error');
      return [];
    }
  }

  // Comprehensive achievement check (call after major user actions)
  Future<void> checkAllAchievements(String userId) async {
    await checkStreakAchievements(userId);
    await checkChallengeAchievements(userId);
    await checkDomainAchievements(userId);
    await checkTimeAchievements(userId);
  }

  // Helper methods
  String _getDomainName(String domain) {
    const names = {
      'sante': 'Santé',
      'relations': 'Relations',
      'carriere': 'Carrière',
      'finances': 'Finances',
      'developpement': 'Développement',
      'spiritualite': 'Spiritualité',
      'loisirs': 'Loisirs',
      'famille': 'Famille',
    };
    return names[domain] ?? 'Inconnu';
  }

  String _getBadgeRarity(String type, int points) {
    if (points >= 1000) return 'legendary';
    if (points >= 500) return 'epic';
    if (points >= 200) return 'rare';
    if (points >= 50) return 'uncommon';
    return 'common';
  }
}