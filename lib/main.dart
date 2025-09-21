import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'services/supabase_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/web_notification_service.dart';
import 'services/pwa_install_service.dart';
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

    // Initialize notification service (without Supabase dependency for now)
    await NotificationService().initialize();

    // Initialize web notification service for PWA
    if (kIsWeb) {
      try {
        await WebNotificationService().initialize();
        
        // Initialize PWA install service
        await PWAInstallService().initialize();
      } catch (e) {
        debugPrint('⚠️ Web notifications not available: $e');
      }
    }

    debugPrint('✅ All services initialized successfully');
  } catch (e) {
    debugPrint('❌ Service initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _setupDeepLinkHandling();
  }

  void _setupDeepLinkHandling() {
    // Listen for auth state changes including deep link authentication
    _authService.authStateChanges.listen(
      (data) {
        try {
          debugPrint('Auth state changed: ${data.event}');

          if (data.event == 'signedIn' || data.event == 'tokenRefreshed') {
            debugPrint('User signed in successfully via deep link or normal flow');
            // Navigation will be handled by individual screens or AuthGuard
          } else if (data.event == 'signedOut') {
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
        title: 'DailyGrowth',
        theme: AppTheme.lightTheme,
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
}
