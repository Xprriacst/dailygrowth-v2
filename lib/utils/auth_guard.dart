import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthGuard {
  static final AuthService _authService = AuthService();

  // Guard for protected routes - validates auth before navigation
  static Future<bool> canNavigate(
      BuildContext context, String routeName) async {
    try {
      // Ensure auth service is initialized
      await _authService.initialize();

      // Validate and refresh session if needed
      final isSessionValid = await _authService.validateAndRefreshSession();

      if (!isSessionValid || !_authService.isAuthenticated) {
        // Redirect to login if not authenticated
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login-screen',
          (route) => false,
        );
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Auth guard error: $e');
      // On error, redirect to login for safety
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login-screen',
        (route) => false,
      );
      return false;
    }
  }

  // Wrapper widget that protects routes
  static Widget protectedRoute({
    required Widget child,
    required BuildContext context,
  }) {
    return StreamBuilder<bool>(
      stream: _authService.authStateStream,
      initialData: _authService.isAuthenticated,
      builder: (context, snapshot) {
        final isAuthenticated = snapshot.data ?? false;

        if (!isAuthenticated) {
          // Redirect to login if not authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login-screen',
              (route) => false,
            );
          });
          return const SizedBox.shrink();
        }

        return child;
      },
    );
  }
}
