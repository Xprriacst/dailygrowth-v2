import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/challenge_service.dart';
import '../../services/user_service.dart';
import '../../utils/auth_guard.dart';
import '../home_dashboard/widgets/bottom_navigation_widget.dart';
import './widgets/challenge_card_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/month_header_widget.dart';
import './widgets/search_bar_widget.dart';

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyHeaderDelegate({required this.child});

  @override
  double get minExtent => 60;

  @override
  double get maxExtent => 60;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class ChallengeHistory extends StatefulWidget {
  const ChallengeHistory({Key? key}) : super(key: key);

  @override
  State<ChallengeHistory> createState() => _ChallengeHistoryState();
}

class _ChallengeHistoryState extends State<ChallengeHistory>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  // Bottom navigation state
  int _currentBottomNavIndex = 1; // History is index 1

  String _searchQuery = '';
  String _selectedDomain = 'Tous';
  String _selectedStatus = 'Tous';
  DateTimeRange? _selectedDateRange;
  bool _showBackToTop = false;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String _userId = '';

  // Real data from database instead of mock data
  List<Map<String, dynamic>> _allChallenges = [];
  List<Map<String, dynamic>> _filteredChallenges = [];
  Map<String, List<Map<String, dynamic>>> _groupedChallenges = {};

  // Service instances
  final ChallengeService _challengeService = ChallengeService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this, initialIndex: 0); // Masqué l'onglet Citations
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _checkAuthenticationAndInitialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthenticationAndInitialize() async {
    // Ensure user is authenticated before initializing
    final canProceed =
        await AuthGuard.canNavigate(context, '/challenge-history');
    if (!canProceed) return;

    _initializeAndLoadData();
  }

  Future<void> _initializeAndLoadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Initialize services
      await _challengeService.initialize();
      await _userService.initialize();

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _showError('Utilisateur non connecté');
        return;
      }

      _userId = user.id;
      await _loadChallengeHistory();
    } catch (e) {
      _showError('Erreur lors de l\'initialisation: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadChallengeHistory() async {
    try {
      final historyData = await _challengeService.getChallengeHistory(
        userId: _userId,
        limit: 100,
      );

      setState(() {
        _allChallenges = historyData.map((item) {
          final challenge = item['daily_challenges'];
          return {
            'id': item['id'],
            'domain': _getDomainDisplayName(challenge['life_domain']),
            'text': challenge['description'],
            'title': challenge['title'],
            'status': 'completed', // All in history are completed
            'completionDate': DateTime.parse(item['completed_at']),
            'monthYear': _getMonthYear(DateTime.parse(item['completed_at'])),
            'points': item['points_earned'],
            'notes': item['notes'],
            'date_assigned': challenge['date_assigned'],
          };
        }).toList();
      });

      _applyFilters();
    } catch (error) {
      debugPrint('Error loading challenge history: $error');
      _showError('Erreur lors du chargement de l\'historique');
    }
  }

  String _getDomainDisplayName(String domain) {
    final names = {
      'sante': 'Santé',
      'relations': 'Relations',
      'carriere': 'Carrière',
      'finances': 'Finances',
      'developpement': 'Développement',
      'spiritualite': 'Spiritualité',
      'loisirs': 'Loisirs',
      'famille': 'Famille',
    };
    return names[domain] ?? 'Autre';
  }

  String _getMonthYear(DateTime date) {
    final months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _onScroll() {
    if (_scrollController.offset > 200 && !_showBackToTop) {
      setState(() => _showBackToTop = true);
    } else if (_scrollController.offset <= 200 && _showBackToTop) {
      setState(() => _showBackToTop = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredChallenges = _allChallenges.where((challenge) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final searchLower = _searchQuery.toLowerCase();
          if (!(challenge['text'] as String)
                  .toLowerCase()
                  .contains(searchLower) &&
              !((challenge['title'] as String?)
                      ?.toLowerCase()
                      .contains(searchLower) ??
                  false) &&
              !(challenge['domain'] as String)
                  .toLowerCase()
                  .contains(searchLower)) {
            return false;
          }
        }

        // Domain filter
        if (_selectedDomain != 'Tous' &&
            challenge['domain'] != _selectedDomain) {
          return false;
        }

        // Status filter (all history items are completed)
        if (_selectedStatus != 'Tous' && _selectedStatus != 'Terminé') {
          return false;
        }

        // Date range filter
        if (_selectedDateRange != null) {
          final challengeDate = challenge['completionDate'] as DateTime;
          if (challengeDate.isBefore(_selectedDateRange!.start) ||
              challengeDate
                  .isAfter(_selectedDateRange!.end.add(Duration(days: 1)))) {
            return false;
          }
        }

        return true;
      }).toList();

      // Group by month
      _groupedChallenges = {};
      for (var challenge in _filteredChallenges) {
        final monthYear = challenge['monthYear'] as String;
        if (!_groupedChallenges.containsKey(monthYear)) {
          _groupedChallenges[monthYear] = [];
        }
        _groupedChallenges[monthYear]!.add(challenge);
      }
    });
  }

  Future<void> _refreshChallenges() async {
    setState(() => _isRefreshing = true);

    try {
      await _loadChallengeHistory();
      _showSuccess('Historique actualisé !');
    } catch (e) {
      _showError('Erreur lors de l\'actualisation');
    } finally {
      setState(() => _isRefreshing = false);
    }

    // Provide haptic feedback
    HapticFeedback.lightImpact();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => FilterBottomSheetWidget(
          selectedDomain: _selectedDomain,
          selectedStatus: _selectedStatus,
          selectedDateRange: _selectedDateRange,
          onApplyFilters: (domain, status, dateRange) {
            setState(() {
              _selectedDomain = domain;
              _selectedStatus = status;
              _selectedDateRange = dateRange;
            });
            _applyFilters();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthGuard.protectedRoute(
      context: context,
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // App Bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.lightTheme.colorScheme.outline
                                .withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: CustomIconWidget(
                          iconName: 'arrow_back',
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        'Historique des défis',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Bar - MASQUÉ (onglet Citations supprimé)
              // Container(
              //   decoration: BoxDecoration(
              //     color: AppTheme.lightTheme.colorScheme.surface,
              //     border: Border(
              //       bottom: BorderSide(
              //         color: AppTheme.lightTheme.colorScheme.outline
              //             .withValues(alpha: 0.1),
              //         width: 1,
              //       ),
              //     ),
              //   ),
              //   child: TabBar(
              //     controller: _tabController,
              //     tabs: [
              //       Tab(text: 'Citations'),
              //       Tab(text: 'Historique'),
              //     ],
              //   ),
              // ),

              // Tab Bar View - SIMPLIFIÉ (plus d'onglets)
              Expanded(
                child: _buildHistoryTab(), // Affichage direct de l'historique
              ),
            ],
          ),
        ),
        // Add persistent bottom navigation
        bottomNavigationBar: BottomNavigationWidget(
          currentIndex: _currentBottomNavIndex,
          onTap: _handleBottomNavTap,
        ),
        floatingActionButton: _showBackToTop
            ? FloatingActionButton(
                onPressed: _scrollToTop,
                mini: true,
                child: CustomIconWidget(
                  iconName: 'keyboard_arrow_up',
                  color: AppTheme.lightTheme.colorScheme.onTertiary,
                  size: 20,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
            SizedBox(height: 2.h),
            Text(
              'Chargement de votre historique...',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (_allChallenges.isEmpty) {
      return EmptyStateWidget(
        onStartJourney: () {
          Navigator.pushNamed(context, '/home-dashboard');
        },
      );
    }

    return Column(
      children: [
        // Search Bar
        SearchBarWidget(
          onSearchChanged: (query) {
            setState(() => _searchQuery = query);
            _applyFilters();
          },
          onFilterTap: _showFilterBottomSheet,
          searchQuery: _searchQuery,
        ),

        // Results count
        if (_filteredChallenges.isNotEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Text(
              '${_filteredChallenges.length} défi${_filteredChallenges.length > 1 ? 's' : ''} trouvé${_filteredChallenges.length > 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
            ),
          ),

        // Challenge List
        Expanded(
          child: _filteredChallenges.isEmpty
              ? _buildEmptySearchResults()
              : RefreshIndicator(
                  onRefresh: _refreshChallenges,
                  color: AppTheme.lightTheme.colorScheme.primary,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      ..._buildGroupedChallenges(),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  List<Widget> _buildGroupedChallenges() {
    List<Widget> slivers = [];

    for (String monthYear in _groupedChallenges.keys) {
      final challenges = _groupedChallenges[monthYear]!;

      // Month header
      slivers.add(
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyHeaderDelegate(
            child: MonthHeaderWidget(
              monthYear: monthYear,
              challengeCount: challenges.length,
            ),
          ),
        ),
      );

      // Challenge cards
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final challenge = challenges[index];
              return ChallengeCardWidget(
                challenge: challenge,
                onTap: () => _showChallengeDetails(challenge),
                onShare: () => _shareChallenge(challenge),
                onFavorite: () => _toggleFavorite(challenge),
                onRetry: () => _retryChallenge(challenge),
              );
            },
            childCount: challenges.length,
          ),
        ),
      );
    }

    return slivers;
  }

  Widget _buildEmptySearchResults() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'search_off',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.3),
              size: 60,
            ),
            SizedBox(height: 3.h),
            Text(
              'Aucun résultat trouvé',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Essayez de modifier vos critères de recherche ou vos filtres',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedDomain = 'Tous';
                  _selectedStatus = 'Tous';
                  _selectedDateRange = null;
                });
                _applyFilters();
              },
              child: Text('Réinitialiser les filtres'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChallengeDetails(Map<String, dynamic> challenge) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              challenge['domain'] as String,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
            ),
            SizedBox(height: 1.h),
            Text(
              challenge['title'] as String? ?? 'Défi terminé',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 2.h),
            Text(
              challenge['text'] as String,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    height: 1.5,
                  ),
            ),
            if (challenge['points'] != null) ...[
              SizedBox(height: 2.h),
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'stars',
                    color: AppTheme.lightTheme.colorScheme.tertiary,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '+${challenge['points']} points gagnés',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  void _shareChallenge(Map<String, dynamic> challenge) {
    // Implement share functionality
    _showSuccess('Défi partagé !');
  }

  void _toggleFavorite(Map<String, dynamic> challenge) {
    // Implement favorite functionality
    _showSuccess('Ajouté aux favoris !');
  }

  void _retryChallenge(Map<String, dynamic> challenge) {
    // Implement retry functionality
    _showSuccess('Défi ajouté à votre liste !');
  }

  void _handleBottomNavTap(int index) async {
    if (index == _currentBottomNavIndex) return;

    // Validate authentication before any navigation
    final canNavigate = await AuthGuard.canNavigate(context, 'navigation');
    if (!canNavigate) return;

    // Navigate to different screens based on index
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home-dashboard');
        break;
      case 1:
        // Already on challenge history
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/user-profile');
        break;
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
