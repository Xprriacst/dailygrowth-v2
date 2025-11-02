import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/supabase_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/web_notification_service.dart';
import 'services/challenge_service.dart';
import 'services/user_service.dart';
import 'services/progress_service.dart';
import 'services/quote_service.dart';
import 'services/gamification_service.dart';
import 'theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'presentation/reset_password/reset_password_screen.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up global error handling for uncaught exceptions
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('❌ Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  try {
    // Initialize Supabase first
    await SupabaseService().initialize();

    // Initialize authentication service
    await AuthService().initialize();

    // Initialize core services
    await UserService().initialize();
    await ChallengeService().initialize();
    await ProgressService().initialize();
    await QuoteService().initialize();
    await GamificationService().initialize();

    // Initialize notification service (without Supabase dependency for now)
    await NotificationService().initialize();

    // Initialize web notification service for PWA
    if (kIsWeb) {
      try {
        await WebNotificationService().initialize();
      } catch (e) {
        debugPrint('⚠️ Web notifications not available: $e');
      }
    }

    debugPrint('✅ All services initialized successfully');
  } catch (e) {
    debugPrint('❌ Service initialization error: $e');
  }

  final shouldForceResetPassword = await _prepareInitialPasswordRecovery();

  runApp(MyApp(
    shouldForceResetPassword: shouldForceResetPassword,
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key, this.shouldForceResetPassword = false}) : super(key: key);

  final bool shouldForceResetPassword;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _authService = AuthService();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _hasForcedResetRoute = false;

  @override
  void initState() {
    super.initState();
    _setupDeepLinkHandling();

    if (widget.shouldForceResetPassword) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToResetPassword();
      });
    }
  }

  void _setupDeepLinkHandling() {
    // Listen for auth state changes including deep link authentication
    _authService.authStateChanges.listen(
      (data) {
        try {
          debugPrint('Auth state changed: ${data.event}');

          if (data.event == AuthChangeEvent.passwordRecovery) {
            debugPrint('🔐 Password recovery event detected');
            _navigateToResetPassword();
          } else if (data.event == AuthChangeEvent.signedIn || data.event == AuthChangeEvent.tokenRefreshed) {
            debugPrint('User signed in successfully via deep link or normal flow');
            // Navigation will be handled by individual screens or AuthGuard
          } else if (data.event == AuthChangeEvent.signedOut) {
            debugPrint('User signed out');
          }
        } catch (e) {
          debugPrint('❌ Error handling auth state change: $e');
        }
      },
      onError: (error) {
        debugPrint('❌ Auth state listener error: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, screenType) {
      return MaterialApp(
        title: 'ChallengeMe',
        theme: AppTheme.lightTheme,
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.0),
            ),
            child: child!,
          );
        },
        initialRoute: AppRoutes.initialRoute,
        routes: AppRoutes.routes,
        onGenerateRoute: (settings) {
          // Handle deep links with parameters
          if (settings.name?.startsWith('/reset-password') == true) {
            final uri = Uri.parse(settings.name!);
            final token = uri.queryParameters['token'];
            final type = uri.queryParameters['type'];
            
            return MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(
                token: token,
                type: type,
              ),
            );
          }
          return null;
        },
      );
    });
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }

  void _navigateToResetPassword() {
    if (_hasForcedResetRoute) return;
    _hasForcedResetRoute = true;

    if (_navigatorKey.currentState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.resetPassword,
          (route) => false,
        );
      });
      return;
    }

    _navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.resetPassword,
      (route) => false,
    );
  }
}

Future<bool> _prepareInitialPasswordRecovery() async {
  if (!kIsWeb) {
    return false;
  }

  try {
    final uri = Uri.base;
    final path = uri.path.toLowerCase();
    final fragment = uri.fragment.toLowerCase();
    final hasResetPath = path.contains('reset-password');
    final hasResetFragment = fragment.contains('reset-password');

    if (!hasResetPath && !hasResetFragment) {
      return false;
    }

    final code = uri.queryParameters['code'];
    if (code != null && code.isNotEmpty) {
      try {
        await Supabase.instance.client.auth.exchangeCodeForSession(code);
        debugPrint('✅ Password recovery session established via code parameter');
      } catch (e) {
        debugPrint('❌ Failed to exchange recovery code for session: $e');
      }
    }

    return true;
  } catch (e) {
    debugPrint('❌ Error preparing password recovery: $e');
    return false;
  }
}
