import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/auth_guard.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../services/challenge_service.dart';
import '../../services/quote_service.dart';
import '../../services/user_service.dart';
import '../../services/progress_service.dart';
import '../../services/gamification_service.dart';
import '../../services/notification_service.dart';
import '../../services/web_notification_service.dart';
import '../../widgets/notification_permission_dialog.dart';
import './widgets/achievements_section_widget.dart';
import './widgets/bottom_navigation_widget.dart';
import './widgets/daily_challenge_card_widget.dart';
import './widgets/greeting_header_widget.dart';
import './widgets/inspirational_quote_card_widget.dart';
import './widgets/weekly_progress_widget.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({Key? key}) : super(key: key);

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> with TickerProviderStateMixin {
  int _currentBottomNavIndex = 0;
  bool _isChallengeCompleted = false;
  bool _isRefreshing = false;
  bool _isLoadingData = true;

  // Real user data from database
  String _userName = "Utilisateur";
  int _currentStreak = 0;
  String _userId = "";

  // Real daily challenge data
  Map<String, dynamic> _dailyChallenge = {
    "title": "Chargement...",
    "description": "Récupération du défi du jour...",
  };

  // Real inspirational quote data
  Map<String, dynamic> _inspirationalQuote = {
    "quote": "Chargement de votre citation inspirante...",
    "author": "",
  };

  // Real achievements data
  List<Map<String, dynamic>> _recentAchievements = [];

  // Real weekly progress data (no more mock data)
  List<Map<String, dynamic>> _weeklyData = [];
  double _weeklyCompletionRate = 0.0;

  // Service instances
  final ChallengeService _challengeService = ChallengeService();
  final QuoteService _quoteService = QuoteService();
  final UserService _userService = UserService();
  final ProgressService _progressService = ProgressService();
  final GamificationService _gamificationService = GamificationService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _checkAuthenticationAndInitialize();
  }

  Future<void> _checkAuthenticationAndInitialize() async {
    // Ensure user is authenticated before initializing
    final canProceed = await AuthGuard.canNavigate(context, '/home-dashboard');
    if (!canProceed) return;
    
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize all services
      await _challengeService.initialize();
      await _quoteService.initialize();
      await _userService.initialize();
      await _progressService.initialize();
      await _gamificationService.initialize();
      await _notificationService.initialize();

      // Load user data
      await _loadUserData();

      setState(() {
        _isLoadingData = false;
      });

      // Show notification permission dialog if needed (after UI is ready)
      _schedulePermissionDialog();
    } catch (e) {
      debugPrint('Failed to initialize services: $e');
      setState(() {
        _isLoadingData = false;
      });
      
      // Still show permission dialog even if services failed to initialize
      _schedulePermissionDialog();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      _userId = user.id;

      // Get user profile
      final userProfile = await _userService.getUserProfile(_userId);
      if (userProfile != null) {
        setState(() {
          _userName = userProfile['full_name'] ?? 'Utilisateur';
          _currentStreak = userProfile['streak_count'] ?? 0;
        });
      }

      // Load all data in parallel for better performance
      await Future.wait([
        _loadTodayChallenge(),
        _loadTodayQuote(),
        _loadRecentAchievements(),
        _loadWeeklyProgress(),
      ]);
    } catch (e) {
      debugPrint('Failed to load user data: $e');
    }
  }

  Future<void> _loadTodayChallenge() async {
    try {
      // First try to get existing challenge for today
      final existingChallenge = await _challengeService.getTodayChallenge(_userId);
      
      if (existingChallenge != null) {
        // Use existing challenge for today
        setState(() {
          _dailyChallenge = {
            'id': existingChallenge['id'],
            'title': existingChallenge['title'],
            'description': existingChallenge['description'],
          };
          _isChallengeCompleted = existingChallenge['status'] == 'completed';
        });
        debugPrint('✅ Loaded existing challenge: ${existingChallenge['title']}');
        return;
      }

      // No existing challenge, generate new one
      final userProfile = await _userService.getUserProfile(_userId);
      final selectedDomains =
          userProfile?['selected_life_domains'] as List<dynamic>? ??
              ['sante'];
      final primaryDomain =
          selectedDomains.isNotEmpty ? selectedDomains.first : 'sante';

      // Generate new challenge (not force regenerate)
      final newChallenge = await _challengeService.generateTodayChallenge(
        userId: _userId,
        lifeDomain: primaryDomain,
      );

      setState(() {
        _dailyChallenge = {
          'id': newChallenge['id'],
          'title': newChallenge['title'],
          'description': newChallenge['description'],
        };
        _isChallengeCompleted = newChallenge['status'] == 'completed';
      });
      
      debugPrint('✅ Challenge loaded: ${newChallenge['title']}');
    } catch (e) {
      debugPrint('Failed to load today\'s challenge: $e');
      // Fallback to existing challenge if regeneration fails
      try {
        final existingChallenge = await _challengeService.getTodayChallenge(_userId);
        if (existingChallenge != null) {
          setState(() {
            _dailyChallenge = {
              'id': existingChallenge['id'],
              'title': existingChallenge['title'],
              'description': existingChallenge['description'],
            };
            _isChallengeCompleted = existingChallenge['status'] == 'completed';
          });
        }
      } catch (fallbackError) {
        debugPrint('Fallback challenge loading also failed: $fallbackError');
      }
    }
  }

  Future<void> _loadTodayQuote() async {
    try {
      // First try to get existing quote
      final existingQuote = await _quoteService.getTodayQuote(_userId);

      if (existingQuote != null) {
        setState(() {
          _inspirationalQuote = {
            'quote': existingQuote['quote_text'],
            'author': existingQuote['author'],
          };
        });
      } else {
        // Generate new quote using QuoteService (already has AI integration)
        final userProfile = await _userService.getUserProfile(_userId);
        final selectedDomains =
            userProfile?['selected_life_domains'] as List<dynamic>? ??
                ['sante'];
        final primaryDomain =
            selectedDomains.isNotEmpty ? selectedDomains.first : 'sante';

        final newQuote = await _quoteService.generateTodaysQuote(
          userId: _userId,
          lifeDomain: primaryDomain,
        );

        setState(() {
          _inspirationalQuote = {
            'quote': newQuote['quote_text'],
            'author': newQuote['quote_author'],
          };
        });
      }
    } catch (e) {
      debugPrint('Failed to load today\'s quote: $e');
    }
  }

  Future<void> _loadRecentAchievements() async {
    try {
      if (_userId == null) {
        debugPrint('⚠️ User ID is null, skipping achievements load');
        setState(() {
          _recentAchievements = [];
        });
        return;
      }

      final achievements = await _userService.getUserAchievements(_userId!);

      setState(() {
        _recentAchievements = achievements
            .take(3) // Show only 3 most recent
            .map((achievement) => {
                  'id': achievement['id'],
                  'title': achievement['achievement_name'] ?? 'Achievement',
                  'description': achievement['description'] ?? 'Description',
                  'icon': achievement['icon_name'] ?? 'star',
                  'date': _formatDate(achievement['unlocked_at']),
                })
            .toList();
      });
    } catch (e) {
      debugPrint('Failed to load achievements: $e');
      setState(() {
        _recentAchievements = [];
      });
    }
  }

  Future<void> _loadWeeklyProgress() async {
    try {
      if (_userId == null) {
        debugPrint('⚠️ User ID is null, skipping weekly progress load');
        setState(() {
          _weeklyData = [];
          _weeklyCompletionRate = 0.0;
        });
        return;
      }

      final weeklyProgress = await _progressService.getWeeklyProgress(_userId!);

      final completedDays =
          weeklyProgress.where((day) => day['completed'] as bool? ?? false).length;
      final totalDays = weeklyProgress.length;

      setState(() {
        _weeklyData = weeklyProgress;
        _weeklyCompletionRate = totalDays > 0 ? completedDays / totalDays : 0.0;
      });
    } catch (e) {
      debugPrint('Failed to load weekly progress: $e');
      // Fallback to empty state if loading fails
      setState(() {
        _weeklyData = [];
        _weeklyCompletionRate = 0.0;
      });
    }
  }

  String _getLifeDomainName(String domain) {
    switch (domain) {
      case 'sante':
        return 'santé';
      case 'relations':
        return 'relations';
      case 'carriere':
        return 'carrière';
      case 'finances':
        return 'finances';
      case 'developpement':
        return 'développement personnel';
      case 'spiritualite':
        return 'spiritualité';
      case 'loisirs':
        return 'loisirs';
      case 'famille':
        return 'famille';
      default:
        return 'développement personnel';
    }
  }

  String _formatDate(String dateTime) {
    final date = DateTime.parse(dateTime);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Aujourd\'hui';
    if (difference.inDays == 1) return 'Hier';
    if (difference.inDays < 7) return 'Il y a ${difference.inDays} jours';
    return 'Il y a ${(difference.inDays / 7).floor()} semaines';
  }

  @override
  Widget build(BuildContext context) {
    return AuthGuard.protectedRoute(
      context: context,
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: SafeArea(
            child: _isLoadingData
                ? Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        CircularProgressIndicator(
                            color: AppTheme.lightTheme.colorScheme.primary),
                        SizedBox(height: 2.h),
                        Text('Chargement de votre tableau de bord...',
                            style: AppTheme.lightTheme.textTheme.bodyMedium),
                      ]))
                : RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: AppTheme.lightTheme.colorScheme.primary,
                    child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Greeting Header
                              GreetingHeaderWidget(
                                  userName: _userName,
                                  currentStreak: _currentStreak,
                                  onProfileTap: _handleProfileTap,
                                  onNotificationTap: _handleNotificationTap),

                              SizedBox(height: 2.h),

                              // Daily Challenge Card
                              DailyChallengeCardWidget(
                                  challengeTitle:
                                      _dailyChallenge['title'] as String,
                                  challengeDescription:
                                      _dailyChallenge['description'] as String,
                                  isCompleted: _isChallengeCompleted,
                                  onToggleCompletion: _handleChallengeToggle),

                              SizedBox(height: 2.h),

                              // Inspirational Quote Card - MASQUÉ
                              // InspirationalQuoteCardWidget(
                              //     quote: _inspirationalQuote['quote'] as String,
                              //     author:
                              //         _inspirationalQuote['author'] as String,
                              //     onShare: _handleQuoteShare),

                              // SizedBox(height: 3.h), // Espacement supprimé avec la citation

                              // Recent Achievements Section
                              AchievementsSectionWidget(
                                  recentAchievements: _recentAchievements),

                              SizedBox(height: 3.h),

                              // Weekly Progress Widget
                              WeeklyProgressWidget(
                                  weeklyData: _weeklyData,
                                  weeklyCompletionRate: _weeklyCompletionRate),

                              SizedBox(height: 3.h),

                              SizedBox(
                                  height: 10.h), // Space for bottom navigation
                            ])))),
        bottomNavigationBar: BottomNavigationWidget(
            currentIndex: _currentBottomNavIndex, onTap: _handleBottomNavTap),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await _loadUserData();
      _showDiscreteNotification('Contenu actualisé !', isSuccess: true);
    } catch (e) {
      _showDiscreteNotification('Erreur lors de l\'actualisation', isSuccess: false);
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _handleChallengeToggle() async {
    HapticFeedback.mediumImpact();

    try {
      final challengeId = _dailyChallenge['id'] as String;

      if (!_isChallengeCompleted) {
        // Complete the challenge
        await _challengeService.completeChallenge(
            challengeId: challengeId, userId: _userId);

        // Update user streak and check for achievements
        await _userService.updateStreak(_userId);
        await _gamificationService.checkAllAchievements(_userId);

        setState(() {
          _isChallengeCompleted = true;
          _currentStreak += 1; // Optimistic update
        });

        // Generate personalized congratulations message
        try {
          final motivationalMessage =
              await _challengeService.generateMotivationalMessage(
            userId: _userId,
            challengeTitle: _dailyChallenge['title'] as String,
            streakCount: _currentStreak,
          );
          _showToast(motivationalMessage);
        } catch (e) {
          _showToast('Félicitations ! Défi accompli ! 🎉');
        }

        // Reload achievements and weekly progress to show updates
        await Future.wait([
          _loadRecentAchievements(),
          _loadWeeklyProgress(),
        ]);
      } else {
        // Mark as incomplete (if needed)
        await _challengeService.skipChallenge(
            challengeId: challengeId, userId: _userId);

        setState(() {
          _isChallengeCompleted = false;
        });

        _showToast('Défi marqué comme non terminé');
      }
    } catch (e) {
      _showToast('Erreur lors de la mise à jour du défi');
    }
  }

  void _handleQuoteShare() {
    final String shareText =
        '"${_inspirationalQuote['quote']}" - ${_inspirationalQuote['author']}';

    // In a real app, you would use share_plus package
    // Share.share(shareText);

    // For now, copy to clipboard
    Clipboard.setData(ClipboardData(text: shareText));
    _showToast('Citation copiée dans le presse-papiers');
  }

  void _handleProfileTap() {
    Navigator.pushNamed(context, '/user-profile');
  }

  void _handleNotificationTap() {
    Navigator.pushNamed(context, '/notification-settings');
  }

  void _handleBottomNavTap(int index) async {
    if (index == _currentBottomNavIndex) return;

    // Validate authentication before any navigation
    final canNavigate = await AuthGuard.canNavigate(context, 'navigation');
    if (!canNavigate) return;

    setState(() {
      _currentBottomNavIndex = index;
    });

    // Navigate to different screens based on index using pushReplacement
    switch (index) {
      case 0:
        // Already on home dashboard
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/challenge-history');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/user-profile');
        break;
    }
  }

  void _navigateToProfile() async {
    // Enhanced profile navigation with auth check
    final canNavigate = await AuthGuard.canNavigate(context, '/user-profile');
    if (canNavigate) {
      Navigator.pushReplacementNamed(context, '/user-profile');
    }
  }

  void _showToast(String message) {
    _showBeautifulSuccessMessage(message);
  }

  void _showBeautifulSuccessMessage(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animation de confettis/succès
                Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.lightTheme.colorScheme.primary,
                        AppTheme.lightTheme.colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.celebration,
                    color: Colors.white,
                    size: 14.w,
                  ),
                ),
                SizedBox(height: 3.h),
                
                // Titre festif
                Text(
                  'Bravo ! 🎉',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: 2.h),
                
                // Message personnalisé
                Text(
                  message,
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),
                
                // Bouton stylé
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.3),
                    ),
                    child: Text(
                      'Continuer',
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDiscreteNotification(String message, {bool isSuccess = true}) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 4.w,
        right: 4.w,
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              color: isSuccess 
                ? AppTheme.lightTheme.colorScheme.primaryContainer
                : AppTheme.lightTheme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess 
                    ? AppTheme.lightTheme.colorScheme.onPrimaryContainer
                    : AppTheme.lightTheme.colorScheme.onErrorContainer,
                  size: 5.w,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    message,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: isSuccess 
                        ? AppTheme.lightTheme.colorScheme.onPrimaryContainer
                        : AppTheme.lightTheme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss après 2 secondes
    Timer(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  /// Schedule the notification permission dialog to show after the UI is fully rendered
  void _schedulePermissionDialog() {
    // Wait a bit for the UI to settle, then show the dialog if needed
    Timer(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;
      
      try {
        final webNotificationService = WebNotificationService();
        final shouldShow = await webNotificationService.shouldShowPermissionDialog();
        
        if (shouldShow && mounted) {
          await NotificationPermissionDialog.showIfNeeded(
            context,
            onPermissionGranted: () {
              debugPrint('🎉 User granted notification permission from home dialog');
              // Optionally refresh notification settings or update UI
            },
            onPermissionDenied: () {
              debugPrint('😔 User denied notification permission from home dialog');
              // Could show alternative engagement strategy
            },
          );
        }
      } catch (e) {
        debugPrint('❌ Error checking/showing permission dialog: $e');
      }
    });
  }
}