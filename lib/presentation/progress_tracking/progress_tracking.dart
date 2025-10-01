import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/gamification_service.dart';
import '../../services/progress_service.dart';
import '../../services/user_service.dart';
import '../../utils/auth_guard.dart';
import '../home_dashboard/widgets/bottom_navigation_widget.dart';
import './widgets/achievement_grid_widget.dart';
import './widgets/statistics_cards_widget.dart';
import './widgets/streak_counter_widget.dart';

class ProgressTracking extends StatefulWidget {
  const ProgressTracking({Key? key}) : super(key: key);

  @override
  State<ProgressTracking> createState() => _ProgressTrackingState();
}

class _ProgressTrackingState extends State<ProgressTracking>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _userId = "";

  // Real progress data
  Map<String, dynamic> _userStats = {};
  Map<String, dynamic> _monthlyProgress = {};
  Map<String, dynamic> _yearlyProgress = {};
  Map<String, dynamic> _domainProgress = {};
  Map<String, dynamic> _userLevel = {};
  List<Map<String, dynamic>> _userBadges = [];

  // Service instances
  final ProgressService _progressService = ProgressService();
  final GamificationService _gamificationService = GamificationService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkAuthenticationAndInitialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthenticationAndInitialize() async {
    // Ensure user is authenticated before initializing
    final canProceed = await AuthGuard.canNavigate(context, '/progress-tracking');
    if (!canProceed) return;
    
    _initializeAndLoadData();
  }

  Future<void> _initializeAndLoadData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      // Initialize services
      await Future.wait([
        _progressService.initialize(),
        _gamificationService.initialize(),
        _userService.initialize(),
      ]);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      _userId = user.id;

      // Load all progress data
      await _loadAllProgressData();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to initialize progress tracking: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadAllProgressData() async {
    try {
      // Load data with timeout and error handling
      final results = await Future.wait([
        _userService.getUserStats(_userId).timeout(Duration(seconds: 10)),
        _progressService
            .getMonthlyProgress(_userId)
            .timeout(Duration(seconds: 10)),
        _progressService
            .getYearlyProgress(_userId)
            .timeout(Duration(seconds: 10)),
        _progressService
            .getProgressByDomain(_userId)
            .timeout(Duration(seconds: 10)),
        _gamificationService
            .getUserBadges(_userId)
            .timeout(Duration(seconds: 10)),
      ], eagerError: true);

      if (mounted) {
        setState(() {
          _userStats = results[0] as Map<String, dynamic>? ?? {};
          _monthlyProgress = results[1] as Map<String, dynamic>? ?? {};
          _yearlyProgress = results[2] as Map<String, dynamic>? ?? {};
          _domainProgress = results[3] as Map<String, dynamic>? ?? {};
          _userBadges = results[4] as List<Map<String, dynamic>>? ?? [];

          // Calculate user level
          final totalPoints = _userStats['total_points'] ?? 0;
          _userLevel = _gamificationService.calculateUserLevel(totalPoints);
        });
      }
    } catch (e) {
      debugPrint('Failed to load progress data: $e');
      // Set empty/default values instead of throwing
      if (mounted) {
        setState(() {
          _userStats = {
            'total_points': 0,
            'current_streak': 0,
          'completed_challenges': 0
        };
        _monthlyProgress = {
          'completion_rate': 0.0,
          'completed_days': 0,
          'daily_progress': []
        };
        _yearlyProgress = {
          'completion_rate': 0.0,
          'completed_challenges': 0,
          'total_challenges': 0
        };
        _domainProgress = {'domain_stats': []};
        _userBadges = [];
        _userLevel = {
          'current_level': 1,
          'level_name': 'Débutant',
          'progress_percentage': 0.0
        };
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthGuard.protectedRoute(
      context: context,
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: SafeArea(
            child: _isLoading
                ? _buildLoadingState()
                : _hasError
                    ? _buildErrorState()
                    : Column(children: [
                        // Header with user level
                        Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                  AppTheme.lightTheme.colorScheme.primary,
                                  AppTheme.lightTheme.colorScheme.primary
                                      .withOpacity(0.8),
                                ])),
                            child: Column(children: [
                              Text('Votre Progression',
                                  style: AppTheme
                                      .lightTheme.textTheme.headlineMedium
                                      ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                              SizedBox(height: 2.h),

                              // User Level Display
                              Container(
                                  padding: EdgeInsets.all(3.w),
                                  decoration: BoxDecoration(
                                      color:
                                          Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16)),
                                  child: Column(children: [
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    'Niveau ${_userLevel['current_level'] ?? 1}',
                                                    style: AppTheme.lightTheme
                                                        .textTheme.titleLarge
                                                        ?.copyWith(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                Text(
                                                    _userLevel['level_name'] ??
                                                        'Débutant',
                                                    style: AppTheme.lightTheme
                                                        .textTheme.bodyLarge
                                                        ?.copyWith(
                                                            color: Colors.white
                                                                .withOpacity(0.9))),
                                              ]),
                                          Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                    '${_userStats['total_points'] ?? 0} points',
                                                    style: AppTheme.lightTheme
                                                        .textTheme.titleMedium
                                                        ?.copyWith(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                if (_userLevel[
                                                        'points_for_next_level'] !=
                                                    null)
                                                  Text(
                                                      'Prochain: ${_userLevel['points_for_next_level']}',
                                                      style: AppTheme.lightTheme
                                                          .textTheme.bodyMedium
                                                          ?.copyWith(
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(0.8))),
                                              ]),
                                        ]),
                                    if (_userLevel['points_for_next_level'] !=
                                        null) ...[
                                      SizedBox(height: 2.h),
                                      LinearProgressIndicator(
                                          value: (_userLevel[
                                                      'progress_percentage'] ??
                                                  0.0) /
                                              100,
                                          backgroundColor: Colors.white
                                              .withOpacity(0.3),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white)),
                                    ],
                                  ])),
                            ])),

                        // Tab Bar
                        TabBar(
                            controller: _tabController,
                            tabs: [
                              Tab(text: 'Résumé'),
                              Tab(text: 'Mensuel'),
                              Tab(text: 'Domaines'),
                              Tab(text: 'Badges'),
                            ],
                            labelColor: AppTheme.lightTheme.colorScheme.primary,
                            unselectedLabelColor: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            indicatorColor:
                                AppTheme.lightTheme.colorScheme.primary),

                        // Tab Content
                        Expanded(
                            child: TabBarView(
                                controller: _tabController,
                                children: [
                              _buildOverviewTab(),
                              _buildMonthlyTab(),
                              _buildDomainsTab(),
                              _buildBadgesTab(),
                            ])),
                      ])),
        bottomNavigationBar: BottomNavigationWidget(
            currentIndex: 2, onTap: _handleBottomNavTap),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
          SizedBox(height: 2.h),
          Text(
            'Chargement de vos statistiques...',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'error_outline',
            color: AppTheme.lightTheme.colorScheme.error,
            size: 12.w,
          ),
          SizedBox(height: 2.h),
          Text(
            'Erreur de chargement',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.error,
            ),
          ),
          SizedBox(height: 1.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'Impossible de charger vos statistiques',
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: _initializeAndLoadData,
            child: Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
        onRefresh: _loadAllProgressData,
        child: SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Statistics Cards
              StatisticsCardsWidget(statistics: _userStats),

              SizedBox(height: 3.h),

              // Streak Counter
              StreakCounterWidget(
                streakCount: _userStats['current_streak'] ?? 0,
                isActive: (_userStats['current_streak'] ?? 0) > 0,
              ),

              SizedBox(height: 3.h),

              // Achievement Grid
              AchievementGridWidget(
                achievements: _userBadges.take(6).toList(),
                onAchievementTapped: (achievement) {},
              ),

              if (_yearlyProgress['best_month'] != null) ...[
                SizedBox(height: 3.h),

                // Best Month Card
                Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.tertiary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.lightTheme.colorScheme.tertiary
                                .withOpacity(0.3))),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            CustomIconWidget(
                                iconName: 'star',
                                color: AppTheme.lightTheme.colorScheme.tertiary,
                                size: 6.w),
                            SizedBox(width: 2.w),
                            Text('Meilleur Mois',
                                style: AppTheme.lightTheme.textTheme.titleMedium
                                    ?.copyWith(
                                        color: AppTheme
                                            .lightTheme.colorScheme.tertiary,
                                        fontWeight: FontWeight.w600)),
                          ]),
                          SizedBox(height: 1.h),
                          Text(
                              _yearlyProgress['best_month']['month_name'] ??
                                  'Inconnu',
                              style: AppTheme.lightTheme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                              '${((_yearlyProgress['best_month']['completion_rate'] ?? 0.0) * 100).round()}% de réussite',
                              style: AppTheme.lightTheme.textTheme.bodyLarge
                                  ?.copyWith(
                                      color: AppTheme.lightTheme.colorScheme
                                          .onSurfaceVariant)),
                        ])),
              ],
            ])));
  }

  Widget _buildMonthlyTab() {
    final monthlyData =
        _monthlyProgress['daily_progress'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Monthly Overview
          Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.lightTheme.colorScheme.shadow
                            .withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2)),
                  ]),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ce Mois-ci',
                        style: AppTheme.lightTheme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    SizedBox(height: 2.h),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Jours actifs',
                              '${monthlyData.length}', 'calendar_today'),
                          _buildStatItem(
                              'Complétés',
                              '${_monthlyProgress['completed_days'] ?? 0}',
                              'check_circle'),
                          _buildStatItem(
                              'Taux',
                              '${((_monthlyProgress['completion_rate'] ?? 0.0) * 100).round()}%',
                              'trending_up'),
                        ]),
                  ])),

          SizedBox(height: 3.h),

          // Monthly Calendar View (simplified)
          if (monthlyData.isNotEmpty)
            Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.lightTheme.colorScheme.shadow
                              .withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2)),
                    ]),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Progression Quotidienne',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      SizedBox(height: 2.h),
                      GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  crossAxisSpacing: 1.w,
                                  mainAxisSpacing: 1.w),
                          itemCount: monthlyData.length,
                          itemBuilder: (context, index) {
                            final dayData =
                                monthlyData[index] as Map<String, dynamic>;
                            final isCompleted =
                                dayData['completed'] as bool? ?? false;
                            final isToday =
                                dayData['isToday'] as bool? ?? false;

                            return Container(
                                decoration: BoxDecoration(
                                    color: isCompleted
                                        ? AppTheme
                                            .lightTheme.colorScheme.tertiary
                                        : AppTheme.lightTheme.colorScheme.outline
                                            .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: isToday
                                        ? Border.all(
                                            color: AppTheme
                                                .lightTheme.colorScheme.primary,
                                            width: 2)
                                        : null),
                                child: Center(
                                    child: Text('${dayData['day'] ?? index + 1}',
                                        style: AppTheme.lightTheme.textTheme.bodySmall
                                            ?.copyWith(
                                                color: isCompleted
                                                    ? Colors.white
                                                    : AppTheme
                                                        .lightTheme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                fontWeight: isToday
                                                    ? FontWeight.bold
                                                    : FontWeight.normal))));
                          }),
                    ])),
        ]));
  }

  Widget _buildDomainsTab() {
    final domainStats = _domainProgress['domain_stats'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_domainProgress['most_active_domain'] != null ||
              _domainProgress['best_performing_domain'] != null) ...[
            // Top Domains Summary
            Row(children: [
              if (_domainProgress['most_active_domain'] != null)
                Expanded(
                    child: Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Plus Actif',
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                          color: AppTheme
                                              .lightTheme.colorScheme.primary,
                                          fontWeight: FontWeight.w600)),
                              Text(
                                  _domainProgress['most_active_domain']
                                          ['domain_name'] ??
                                      'Inconnu',
                                  style: AppTheme
                                      .lightTheme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                            ]))),
              SizedBox(width: 2.w),
              if (_domainProgress['best_performing_domain'] != null)
                Expanded(
                    child: Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.tertiary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Meilleur',
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                          color: AppTheme
                                              .lightTheme.colorScheme.tertiary,
                                          fontWeight: FontWeight.w600)),
                              Text(
                                  _domainProgress['best_performing_domain']
                                          ['domain_name'] ??
                                      'Inconnu',
                                  style: AppTheme
                                      .lightTheme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                            ]))),
            ]),
            SizedBox(height: 3.h),
          ],

          // Domain Progress List
          if (domainStats.isEmpty)
            Center(
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  CustomIconWidget(
                    iconName: 'analytics',
                    size: 20.w,
                    color: AppTheme.lightTheme.colorScheme.outline,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Aucune donnée disponible',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Complétez des défis pour voir vos progrès par domaine !',
                    textAlign: TextAlign.center,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else
            ...domainStats.map((domain) {
              final domainMap = domain as Map<String, dynamic>;
              return Container(
                  margin: EdgeInsets.only(bottom: 2.h),
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: AppTheme.lightTheme.colorScheme.shadow
                                .withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2)),
                      ]),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(domainMap['domain_name'] ?? 'Inconnu',
                                  style: AppTheme
                                      .lightTheme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              Text(
                                  '${domainMap['completed_challenges'] ?? 0}/${domainMap['total_challenges'] ?? 0}',
                                  style: AppTheme
                                      .lightTheme.textTheme.bodyMedium
                                      ?.copyWith(
                                          color: AppTheme.lightTheme.colorScheme
                                              .onSurfaceVariant)),
                            ]),
                        SizedBox(height: 1.h),
                        LinearProgressIndicator(
                            value: (domainMap['completion_rate'] as double?) ??
                                0.0,
                            backgroundColor: AppTheme
                                .lightTheme.colorScheme.outline
                                .withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.lightTheme.colorScheme.primary)),
                        SizedBox(height: 0.5.h),
                        Text(
                            '${(((domainMap['completion_rate'] as double?) ?? 0.0) * 100).round()}% de réussite',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant)),
                      ]));
            }).toList(),
        ]));
  }

  Widget _buildBadgesTab() {
    return SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Collection de Badges',
              style: AppTheme.lightTheme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text('${_userBadges.length} badges débloqués',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant)),
          SizedBox(height: 3.h),
          if (_userBadges.isEmpty)
            Center(
                child: Column(children: [
              SizedBox(height: 10.h),
              CustomIconWidget(
                  iconName: 'emoji_events',
                  size: 20.w,
                  color: AppTheme.lightTheme.colorScheme.outline),
              SizedBox(height: 2.h),
              Text('Aucun badge pour le moment',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant)),
              Text('Complétez des défis pour débloquer vos premiers badges !',
                  textAlign: TextAlign.center,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant)),
            ]))
          else
            GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 3.w,
                    mainAxisSpacing: 3.w,
                    childAspectRatio: 1.2),
                itemCount: _userBadges.length,
                itemBuilder: (context, index) {
                  final badge = _userBadges[index];
                  return Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: AppTheme.lightTheme.colorScheme.shadow
                                    .withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 2)),
                          ],
                          border: Border.all(
                              color: _getBadgeColor(badge['rarity'] ?? 'common')
                                  .withOpacity(0.3),
                              width: 2)),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                                padding: EdgeInsets.all(3.w),
                                decoration: BoxDecoration(
                                    color: _getBadgeColor(
                                            badge['rarity'] ?? 'common')
                                        .withOpacity(0.1),
                                    shape: BoxShape.circle),
                                child: CustomIconWidget(
                                    iconName: badge['icon'] ?? 'emoji_events',
                                    color: _getBadgeColor(
                                        badge['rarity'] ?? 'common'),
                                    size: 8.w)),
                            SizedBox(height: 1.h),
                            Text(badge['name'] ?? 'Badge',
                                textAlign: TextAlign.center,
                                style: AppTheme.lightTheme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            Text('+${badge['points'] ?? 0} pts',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                        color: _getBadgeColor(
                                            badge['rarity'] ?? 'common'),
                                        fontWeight: FontWeight.w500)),
                          ]));
                }),
        ]));
  }

  Widget _buildStatItem(String label, String value, String iconName) {
    return Column(children: [
      CustomIconWidget(
          iconName: iconName,
          color: AppTheme.lightTheme.colorScheme.primary,
          size: 6.w),
      SizedBox(height: 1.h),
      Text(value,
          style: AppTheme.lightTheme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold)),
      Text(label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant)),
    ]);
  }

  Color _getBadgeColor(String rarity) {
    switch (rarity) {
      case 'legendary':
        return Color(0xFFFFD700); // Gold
      case 'epic':
        return Color(0xFF9C27B0); // Purple
      case 'rare':
        return Color(0xFF2196F3); // Blue
      case 'uncommon':
        return Color(0xFF4CAF50); // Green
      default:
        return Color(0xFF9E9E9E); // Gray
    }
  }

  void _handleBottomNavTap(int index) async {
    if (index == 2) return; // Already on progress tracking

    // Validate authentication before any navigation
    final canNavigate = await AuthGuard.canNavigate(context, 'navigation');
    if (!canNavigate) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home-dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/challenge-history');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/user-profile');
        break;
    }
  }
}