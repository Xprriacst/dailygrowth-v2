import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;

import './supabase_service.dart';

class ProgressService {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  late final SupabaseClient _client;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      _client = await SupabaseService().client;
      _isInitialized = true;
    }
  }

  // Get weekly progress data for user
  Future<List<Map<String, dynamic>>> getWeeklyProgress(String userId) async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(Duration(days: 6));

      final weekDays = <Map<String, dynamic>>[];
      
      for (int i = 0; i < 7; i++) {
        final currentDay = startOfWeek.add(Duration(days: i));
        final dateString = currentDay.toIso8601String().split('T')[0];
        
        // Check if user completed challenge on this day
        final challengeResponse = await _client
            .from('daily_challenges')
            .select()
            .eq('user_id', userId)
            .eq('date_assigned', dateString)
            .eq('status', 'completed')
            .maybeSingle();

        weekDays.add({
          'day': _getDayAbbreviation(currentDay.weekday),
          'date': dateString,
          'completed': challengeResponse != null,
          'isToday': _isSameDay(currentDay, now),
        });
      }

      return weekDays;
    } catch (error) {
      throw Exception('Erreur lors de la récupération du progrès hebdomadaire: $error');
    }
  }

  // Get monthly progress statistics
  Future<Map<String, dynamic>> getMonthlyProgress(String userId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final monthStats = <String, dynamic>{
        'total_days': endOfMonth.day,
        'completed_days': 0,
        'completion_rate': 0.0,
        'daily_progress': <Map<String, dynamic>>[],
      };

      // Get all days in the month
      for (int day = 1; day <= endOfMonth.day; day++) {
        final currentDay = DateTime(now.year, now.month, day);
        final dateString = currentDay.toIso8601String().split('T')[0];
        
        // Don't check future days
        if (currentDay.isAfter(now)) break;

        final challengeResponse = await _client
            .from('daily_challenges')
            .select()
            .eq('user_id', userId)
            .eq('date_assigned', dateString)
            .eq('status', 'completed')
            .maybeSingle();

        final isCompleted = challengeResponse != null;
        if (isCompleted) {
          monthStats['completed_days'] = (monthStats['completed_days'] as int) + 1;
        }

        (monthStats['daily_progress'] as List).add({
          'day': day,
          'date': dateString,
          'completed': isCompleted,
          'isToday': _isSameDay(currentDay, now),
        });
      }

      // Calculate completion rate
      final activeDays = (monthStats['daily_progress'] as List).length;
      if (activeDays > 0) {
        monthStats['completion_rate'] = 
            (monthStats['completed_days'] as int) / activeDays;
      }

      return monthStats;
    } catch (error) {
      throw Exception('Erreur lors de la récupération du progrès mensuel: $error');
    }
  }

  // Get yearly progress statistics
  Future<Map<String, dynamic>> getYearlyProgress(String userId) async {
    try {
      final now = DateTime.now();
      final startOfYear = DateTime(now.year, 1, 1);

      final yearStats = <String, dynamic>{
        'year': now.year,
        'total_challenges': 0,
        'completed_challenges': 0,
        'completion_rate': 0.0,
        'monthly_breakdown': <Map<String, dynamic>>[],
        'best_month': null,
        'current_streak': 0,
        'longest_streak': 0,
      };

      // Get monthly breakdown
      for (int month = 1; month <= 12; month++) {
        final startOfMonth = DateTime(now.year, month, 1);
        final endOfMonth = DateTime(now.year, month + 1, 0);
        
        // Don't process future months
        if (startOfMonth.isAfter(now)) break;

        final monthChallengesResult = await _client
            .from('daily_challenges')
            .select()
            .eq('user_id', userId)
            .gte('date_assigned', startOfMonth.toIso8601String().split('T')[0])
            .lte('date_assigned', endOfMonth.toIso8601String().split('T')[0])
            .count();

        final monthCompletedResult = await _client
            .from('daily_challenges')
            .select()
            .eq('user_id', userId)
            .eq('status', 'completed')
            .gte('date_assigned', startOfMonth.toIso8601String().split('T')[0])
            .lte('date_assigned', endOfMonth.toIso8601String().split('T')[0])
            .count();

        final totalChallenges = monthChallengesResult.count ?? 0;
        final completedChallenges = monthCompletedResult.count ?? 0;
        final completionRate = totalChallenges > 0 ? completedChallenges / totalChallenges : 0.0;

        (yearStats['monthly_breakdown'] as List).add({
          'month': month,
          'month_name': _getMonthName(month),
          'total_challenges': totalChallenges,
          'completed_challenges': completedChallenges,
          'completion_rate': completionRate,
        });

        yearStats['total_challenges'] = (yearStats['total_challenges'] as int) + totalChallenges;
        yearStats['completed_challenges'] = (yearStats['completed_challenges'] as int) + completedChallenges;
      }

      // Calculate overall completion rate
      if ((yearStats['total_challenges'] as int) > 0) {
        yearStats['completion_rate'] = 
            (yearStats['completed_challenges'] as int) / (yearStats['total_challenges'] as int);
      }

      // Find best month
      final monthlyBreakdown = yearStats['monthly_breakdown'] as List<Map<String, dynamic>>;
      if (monthlyBreakdown.isNotEmpty) {
        monthlyBreakdown.sort((a, b) => (b['completion_rate'] as double).compareTo(a['completion_rate'] as double));
        yearStats['best_month'] = monthlyBreakdown.first;
      }

      // Calculate streaks
      final streakData = await _calculateUserStreaks(userId);
      yearStats['current_streak'] = streakData['current_streak'];
      yearStats['longest_streak'] = streakData['longest_streak'];

      return yearStats;
    } catch (error) {
      throw Exception('Erreur lors de la récupération du progrès annuel: $error');
    }
  }

  // Get progress by life domain
  Future<Map<String, dynamic>> getProgressByDomain(String userId) async {
    try {
      final challengesResponse = await _client
          .from('daily_challenges')
          .select('life_domain, status')
          .eq('user_id', userId);

      final challenges = List<Map<String, dynamic>>.from(challengesResponse);
      
      final domainStats = <String, Map<String, dynamic>>{};

      // Initialize all domains
      const domains = ['sante', 'relations', 'carriere', 'finances', 'developpement', 'spiritualite', 'loisirs', 'famille'];
      for (final domain in domains) {
        domainStats[domain] = {
          'domain': domain,
          'domain_name': _getDomainName(domain),
          'total_challenges': 0,
          'completed_challenges': 0,
          'completion_rate': 0.0,
        };
      }

      // Count challenges by domain
      for (final challenge in challenges) {
        final domain = challenge['life_domain'] as String;
        final status = challenge['status'] as String;

        if (domainStats.containsKey(domain)) {
          domainStats[domain]!['total_challenges'] = 
              (domainStats[domain]!['total_challenges'] as int) + 1;
          
          if (status == 'completed') {
            domainStats[domain]!['completed_challenges'] = 
                (domainStats[domain]!['completed_challenges'] as int) + 1;
          }
        }
      }

      // Calculate completion rates
      for (final stats in domainStats.values) {
        final total = stats['total_challenges'] as int;
        final completed = stats['completed_challenges'] as int;
        stats['completion_rate'] = total > 0 ? completed / total : 0.0;
      }

      return {
        'domain_stats': domainStats.values.toList(),
        'most_active_domain': _getMostActiveDomain(domainStats),
        'best_performing_domain': _getBestPerformingDomain(domainStats),
      };
    } catch (error) {
      throw Exception('Erreur lors de la récupération du progrès par domaine: $error');
    }
  }

  // Calculate detailed streak information
  Future<Map<String, dynamic>> _calculateUserStreaks(String userId) async {
    try {
      // Get all completed challenges ordered by date
      final challengesResponse = await _client
          .from('daily_challenges')
          .select('date_assigned')
          .eq('user_id', userId)
          .eq('status', 'completed')
          .order('date_assigned', ascending: true);

      final challenges = List<Map<String, dynamic>>.from(challengesResponse);
      
      if (challenges.isEmpty) {
        return {'current_streak': 0, 'longest_streak': 0};
      }

      final completedDates = challenges
          .map((c) => DateTime.parse(c['date_assigned']))
          .toSet()
          .toList()
        ..sort();

      int currentStreak = 0;
      int longestStreak = 0;
      int tempStreak = 1;

      // Calculate longest streak
      for (int i = 1; i < completedDates.length; i++) {
        final prevDate = completedDates[i - 1];
        final currentDate = completedDates[i];
        final difference = currentDate.difference(prevDate).inDays;

        if (difference == 1) {
          tempStreak++;
        } else {
          longestStreak = math.max(longestStreak, tempStreak);
          tempStreak = 1;
        }
      }
      longestStreak = math.max(longestStreak, tempStreak);

      // Calculate current streak (working backwards from today)
      final today = DateTime.now();
      final todayString = today.toIso8601String().split('T')[0];
      
      // Check if user completed today's challenge
      final todayChallenge = await _client
          .from('daily_challenges')
          .select()
          .eq('user_id', userId)
          .eq('date_assigned', todayString)
          .eq('status', 'completed')
          .maybeSingle();

      if (todayChallenge != null) {
        currentStreak = 1;
        // Count backwards
        for (int i = 1; i < 365; i++) {
          final checkDate = today.subtract(Duration(days: i));
          final checkDateString = checkDate.toIso8601String().split('T')[0];
          
          final challengeOnDate = await _client
              .from('daily_challenges')
              .select()
              .eq('user_id', userId)
              .eq('date_assigned', checkDateString)
              .eq('status', 'completed')
              .maybeSingle();

          if (challengeOnDate != null) {
            currentStreak++;
          } else {
            break;
          }
        }
      }

      return {
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
      };
    } catch (error) {
      debugPrint('Error calculating streaks: $error');
      return {'current_streak': 0, 'longest_streak': 0};
    }
  }

  // Helper methods
  String _getDayAbbreviation(int weekday) {
    const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[month - 1];
  }

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

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  Map<String, dynamic>? _getMostActiveDomain(Map<String, Map<String, dynamic>> domainStats) {
    if (domainStats.isEmpty) return null;

    return domainStats.values
        .where((stats) => (stats['total_challenges'] as int) > 0)
        .fold<Map<String, dynamic>?>(null, (prev, current) {
      if (prev == null) return current;
      return (current['total_challenges'] as int) > (prev['total_challenges'] as int) 
          ? current : prev;
    });
  }

  Map<String, dynamic>? _getBestPerformingDomain(Map<String, Map<String, dynamic>> domainStats) {
    if (domainStats.isEmpty) return null;

    return domainStats.values
        .where((stats) => (stats['total_challenges'] as int) > 0)
        .fold<Map<String, dynamic>?>(null, (prev, current) {
      if (prev == null) return current;
      return (current['completion_rate'] as double) > (prev['completion_rate'] as double) 
          ? current : prev;
    });
  }
}