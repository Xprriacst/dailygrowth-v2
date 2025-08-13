import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import './supabase_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  late final SupabaseClient _client;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      _client = await SupabaseService().client;
      _isInitialized = true;
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      // Ensure service is initialized
      if (!_isInitialized) {
        await initialize();
      }
      
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (error) {
      throw Exception('Erreur lors de la récupération du profil: $error');
    }
  }

  // Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile != null) {
        final selectedDomains = profile['selected_life_domains'] as List?;
        return selectedDomains != null && selectedDomains.isNotEmpty;
      }
      return false;
    } catch (error) {
      debugPrint('Error checking onboarding status: $error');
      return false;
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    String? fullName,
    List<String>? selectedLifeDomains,
    String? notificationTime,
    bool? notificationsEnabled,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updates['full_name'] = fullName;
      if (selectedLifeDomains != null)
        updates['selected_life_domains'] = selectedLifeDomains;
      if (notificationTime != null)
        updates['notification_time'] = notificationTime;
      if (notificationsEnabled != null)
        updates['notifications_enabled'] = notificationsEnabled;

      final response = await _client
          .from('user_profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Erreur lors de la mise à jour du profil: $error');
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      // Get user profile with streak and points
      final profile = await _client
          .from('user_profiles')
          .select('streak_count, total_points')
          .eq('id', userId)
          .single();

      // Get challenges count
      final challengesResult = await _client
          .from('daily_challenges')
          .select()
          .eq('user_id', userId)
          .count();

      // Get completed challenges count
      final completedResult = await _client
          .from('daily_challenges')
          .select()
          .eq('user_id', userId)
          .eq('status', 'completed')
          .count();

      // Get achievements count
      final achievementsResult = await _client
          .from('user_achievements')
          .select()
          .eq('user_id', userId)
          .count();

      return {
        'streak_count': profile['streak_count'] ?? 0,
        'total_points': profile['total_points'] ?? 0,
        'total_challenges': challengesResult.count ?? 0,
        'completed_challenges': completedResult.count ?? 0,
        'achievements_count': achievementsResult.count ?? 0,
        'completion_rate': (challengesResult.count ?? 0) > 0
            ? ((completedResult.count ?? 0) /
                (challengesResult.count ?? 0) *
                100)
            : 0.0,
      };
    } catch (error) {
      throw Exception(
          'Erreur lors de la récupération des statistiques: $error');
    }
  }

  // Update user streak
  Future<void> updateStreak(String userId) async {
    try {
      await _client.rpc('update_user_streak', params: {'user_uuid': userId});
    } catch (error) {
      throw Exception('Erreur lors de la mise à jour de la série: $error');
    }
  }

  // Add points to user
  Future<void> addPoints(String userId, int points) async {
    try {
      await _client.rpc('add_user_points', params: {
        'user_uuid': userId,
        'points': points,
      });
    } catch (error) {
      throw Exception('Erreur lors de l\'ajout de points: $error');
    }
  }

  // Get user achievements
  Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async {
    try {
      final response = await _client
          .from('user_achievements')
          .select()
          .eq('user_id', userId)
          .order('unlocked_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Erreur lors de la récupération des succès: $error');
    }
  }

  // Add achievement
  Future<Map<String, dynamic>> addAchievement({
    required String userId,
    required String achievementType,
    required String achievementName,
    required String description,
    required String iconName,
    int pointsEarned = 0,
  }) async {
    try {
      final response = await _client
          .from('user_achievements')
          .insert({
            'user_id': userId,
            'achievement_type': achievementType,
            'achievement_name': achievementName,
            'description': description,
            'icon_name': iconName,
            'points_earned': pointsEarned,
          })
          .select()
          .single();

      // Add points to user total
      if (pointsEarned > 0) {
        await addPoints(userId, pointsEarned);
      }

      return response;
    } catch (error) {
      throw Exception('Erreur lors de l\'ajout du succès: $error');
    }
  }
}