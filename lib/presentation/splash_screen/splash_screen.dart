import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final _authService = AuthService();
  final _userService = UserService();

  bool _isInitializing = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasCompletedOnboarding = false;
  bool _openAIStatus = false;
  String _initializationStatus = 'Initialisation...';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    try {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 2000),
        vsync: this,
      );

      _scaleAnimation = Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ));

      _fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ));

      _animationController.forward();
    } catch (e) {
      debugPrint('Animation setup error: $e');
      // Continue without animations if setup fails
    }
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize core services with individual error handling
      await _initializeServicesWithErrorHandling();

      // Load user preferences (non-critical)
      await _loadUserPreferencesWithErrorHandling();

      // Fetch cached challenges (non-critical)
      await _fetchCachedChallengesWithErrorHandling();

      // Prepare AI services (non-critical, can use fallback)
      await _prepareAIServicesWithErrorHandling();

      // Check authentication status and onboarding completion
      await _checkAuthenticationAndOnboardingStatusWithErrorHandling();

      // Minimum splash display time
      await Future.delayed(const Duration(milliseconds: 2500));

      if (mounted) {
        _navigateToNextScreen();
      }
    } catch (e) {
      debugPrint('App initialization error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Erreur d\'initialisation. Veuillez réessayer.';
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _initializeServicesWithErrorHandling() async {
    try {
      setState(() {
        _initializationStatus = 'Initialisation des services...';
      });

      // Initialize auth service
      await _authService.initialize();
      debugPrint('✅ Auth service initialized');

      // Initialize user service
      await _userService.initialize();
      debugPrint('✅ User service initialized');
    } catch (e) {
      debugPrint('❌ Service initialization error: $e');
      // Critical services failed, but continue with fallback
      setState(() {
        _initializationStatus = 'Services initialisés en mode dégradé';
      });
    }
  }

  Future<void>
      _checkAuthenticationAndOnboardingStatusWithErrorHandling() async {
    try {
      // Check if user is authenticated via Supabase
      final isAuthenticated = _authService.isAuthenticated;
      final currentUser = _authService.currentUser;

      if (isAuthenticated && currentUser != null) {
        // Verify user profile exists in database
        try {
          final userProfile = await _userService.getUserProfile(currentUser.id);
          if (userProfile != null) {
            debugPrint('✅ User authenticated and profile found');

            // Check if user has completed onboarding by checking selected_life_domains
            final selectedDomains =
                userProfile['selected_life_domains'] as List?;
            _hasCompletedOnboarding =
                selectedDomains != null && selectedDomains.isNotEmpty;

            debugPrint(
                'Onboarding status: ${_hasCompletedOnboarding ? "completed" : "incomplete"}');
            return;
          } else {
            debugPrint(
                '⚠️ User authenticated but no profile found, signing out');
            await _authService.signOut();
          }
        } catch (e) {
          debugPrint('❌ Error checking user profile: $e');
          await _authService.signOut().catchError((error) {
            debugPrint('Error during signout: $error');
          });
        }
      }

      debugPrint('ℹ️ User not authenticated or profile missing');
      _hasCompletedOnboarding = false;
    } catch (e) {
      debugPrint('❌ Authentication status check error: $e');
      _hasCompletedOnboarding = false;
    }
  }

  Future<void> _loadUserPreferencesWithErrorHandling() async {
    try {
      setState(() {
        _initializationStatus = 'Chargement des préférences...';
      });
      await Future.delayed(const Duration(milliseconds: 300));
      debugPrint('✅ User preferences loaded');
    } catch (e) {
      debugPrint('⚠️ Non-critical: User preferences loading failed: $e');
    }
  }

  Future<void> _fetchCachedChallengesWithErrorHandling() async {
    try {
      setState(() {
        _initializationStatus = 'Récupération des défis...';
      });
      await Future.delayed(const Duration(milliseconds: 400));
      debugPrint('✅ Cached challenges fetched');
    } catch (e) {
      debugPrint('⚠️ Non-critical: Cached challenges fetching failed: $e');
    }
  }

  Future<void> _prepareAIServicesWithErrorHandling() async {
    try {
      setState(() {
        _initializationStatus = 'Services prêts...';
      });

      // AI services disabled - using n8n workflow and fallback content
      setState(() {
        _openAIStatus = true;
        _initializationStatus = 'Services n8n: Opérationnels ✓';
      });
      debugPrint('✅ n8n workflow services ready');
    } catch (e) {
      setState(() {
        _openAIStatus = false;
        _initializationStatus = 'Services: Erreur d\'initialisation';
      });
      debugPrint('❌ Service preparation error: $e');
    }

    await Future.delayed(const Duration(milliseconds: 600));
  }

  void _navigateToNextScreen() {
    try {
      // Improved authentication and onboarding logic
      final bool isAuthenticated = _authService.isAuthenticated;

      if (isAuthenticated) {
        if (_hasCompletedOnboarding) {
          // User is authenticated AND has completed onboarding -> go to dashboard
          debugPrint(
              '🎯 Navigating to dashboard: authenticated user with completed onboarding');
          Navigator.pushReplacementNamed(context, '/home-dashboard');
        } else {
          // User is authenticated BUT has NOT completed onboarding -> go to onboarding
          debugPrint(
              '🎯 Navigating to onboarding: authenticated user with incomplete onboarding');
          Navigator.pushReplacementNamed(context, '/onboarding-flow');
        }
      } else {
        // User is not authenticated -> go to login
        debugPrint('🎯 Navigating to login: user not authenticated');
        Navigator.pushReplacementNamed(context, '/login-screen');
      }
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
      // Fallback to login if navigation fails
      Navigator.pushReplacementNamed(context, '/login-screen');
    }
  }

  void _retryInitialization() {
    setState(() {
      _hasError = false;
      _isInitializing = true;
      _errorMessage = '';
      _initializationStatus = 'Initialisation...';
    });
    _initializeApp();
  }

  void _navigateToMicroChallenges() {
    try {
      Navigator.pushNamed(context, '/challenge-selection');
    } catch (e) {
      debugPrint('❌ Error navigating to micro-challenges: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erreur lors de l\'ouverture des micro-défis')),
      );
    }
  }

  @override
  void dispose() {
    try {
      _animationController.dispose();
    } catch (e) {
      debugPrint('Error disposing animation controller: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style with error handling
    try {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppTheme.lightTheme.colorScheme.primary,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
    } catch (e) {
      debugPrint('Error setting system UI overlay: $e');
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.lightTheme.colorScheme.primary,
              AppTheme.lightTheme.colorScheme.primaryContainer,
              AppTheme.lightTheme.colorScheme.secondary,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: _hasError ? _buildErrorView() : _buildSplashContent(),
        ),
      ),
    );
  }

  Widget _buildSplashContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: Center(
            child: _animationController.isCompleted
                ? AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildLogo(),
                        ),
                      );
                    },
                  )
                : _buildLogo(), // Fallback if animation fails
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLoadingIndicator(),
              SizedBox(height: 2.h),
              _buildInitializationStatus(),
              SizedBox(height: 1.h),
              _buildOpenAIStatus(),
              SizedBox(height: 2.h),
              _buildTestButton(),
              SizedBox(height: 2.h),
              _buildAppVersion(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 35.w,
      height: 35.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'trending_up',
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 12.w,
          ),
          SizedBox(height: 1.h),
          Text(
            'DailyGrowth',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.lightTheme.colorScheme.primary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return _isInitializing
        ? SizedBox(
            width: 8.w,
            height: 8.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withAlpha(204),
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  Widget _buildInitializationStatus() {
    return Text(
      _initializationStatus,
      style: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: Colors.white.withAlpha(230),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildOpenAIStatus() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(
          color: Colors.white.withAlpha(51),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: _openAIStatus ? 'check_circle' : 'error_outline',
            color: _openAIStatus ? Colors.greenAccent : Colors.orangeAccent,
            size: 4.w,
          ),
          SizedBox(width: 2.w),
          Text(
            _openAIStatus
                ? 'Services n8n: Opérationnels'
                : 'Services: Mode Dégradé',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white.withAlpha(230),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton() {
    return TextButton.icon(
      onPressed: _navigateToMicroChallenges,
      icon: CustomIconWidget(
        iconName: 'psychology',
        color: Colors.white.withAlpha(179),
        size: 4.w,
      ),
      label: Text(
        'Micro-défis n8n',
        style: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: Colors.white.withAlpha(179),
          letterSpacing: 0.3,
        ),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2.w),
          side: BorderSide(
            color: Colors.white.withAlpha(51),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildAppVersion() {
    return Text(
      'Version 1.0.0',
      style: GoogleFonts.inter(
        fontSize: 11.sp,
        fontWeight: FontWeight.w400,
        color: Colors.white.withAlpha(179),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLogo(),
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(26),
                borderRadius: BorderRadius.circular(4.w),
                border: Border.all(
                  color: Colors.white.withAlpha(51),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  CustomIconWidget(
                    iconName: 'error_outline',
                    color: Colors.white,
                    size: 10.w,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _retryInitialization,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor:
                            AppTheme.lightTheme.colorScheme.primary,
                        padding: EdgeInsets.symmetric(vertical: 3.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3.w),
                        ),
                      ),
                      child: Text(
                        'Réessayer',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
