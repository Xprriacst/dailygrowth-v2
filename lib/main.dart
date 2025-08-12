import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import './services/auth_service.dart';
import './services/supabase_service.dart';
import 'core/app_export.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Supabase first
    await SupabaseService();

    // Initialize authentication service
    await AuthService().initialize();

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
    _authService.authStateChanges.listen((data) {
      debugPrint('Auth state changed: ${data.event}');

      if (data.event == 'signedIn' || data.event == 'tokenRefreshed') {
        debugPrint('User signed in successfully via deep link or normal flow');
        // Navigation will be handled by individual screens or AuthGuard
      } else if (data.event == 'signedOut') {
        debugPrint('User signed out');
      }
    });
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
      );
    });
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}
