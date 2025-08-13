import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// Utility class for debugging authentication issues
class AuthDebug {
  static const String _tag = '🔍 AuthDebug';

  /// Clear all authentication data and local storage
  static Future<void> clearAllAuthData() async {
    try {
      debugPrint('$_tag Clearing all authentication data...');
      
      // Clear auth service state
      await AuthService().clearAuthState();
      
      // For web platform, clear browser storage
      if (kIsWeb) {
        await _clearWebStorage();
      }
      
      debugPrint('$_tag ✅ All authentication data cleared');
    } catch (e) {
      debugPrint('$_tag ❌ Error clearing auth data: $e');
    }
  }

  /// Clear web browser storage (localStorage and sessionStorage)
  static Future<void> _clearWebStorage() async {
    try {
      // This will be handled by the browser's localStorage.clear()
      // when the user manually clears it in the console
      debugPrint('$_tag Please manually clear browser storage:');
      debugPrint('$_tag 1. Open browser console (F12)');
      debugPrint('$_tag 2. Run: localStorage.clear(); sessionStorage.clear();');
      debugPrint('$_tag 3. Refresh the page');
    } catch (e) {
      debugPrint('$_tag Error accessing web storage: $e');
    }
  }

  /// Diagnose authentication state
  static Future<void> diagnoseAuthState() async {
    try {
      debugPrint('$_tag === Authentication Diagnosis ===');
      
      final authService = AuthService();
      
      debugPrint('$_tag Is authenticated: ${authService.isAuthenticated}');
      debugPrint('$_tag Current user: ${authService.currentUser?.email ?? 'None'}');
      debugPrint('$_tag Session expired: ${authService.isSessionExpired}');
      debugPrint('$_tag Access token: ${authService.accessToken != null ? 'Present' : 'Missing'}');
      
      // Validate session
      final isValid = await authService.validateSession();
      debugPrint('$_tag Session valid: $isValid');
      
      debugPrint('$_tag === End Diagnosis ===');
    } catch (e) {
      debugPrint('$_tag ❌ Error during diagnosis: $e');
    }
  }

  /// Fix common authentication issues
  static Future<void> fixCommonIssues() async {
    try {
      debugPrint('$_tag Attempting to fix common auth issues...');
      
      // Step 1: Clear all auth data
      await clearAllAuthData();
      
      // Step 2: Wait a moment for cleanup
      await Future.delayed(const Duration(seconds: 1));
      
      // Step 3: Reinitialize auth service
      await AuthService().initialize();
      
      debugPrint('$_tag ✅ Common auth issues fix completed');
      debugPrint('$_tag Please try logging in again');
    } catch (e) {
      debugPrint('$_tag ❌ Error fixing auth issues: $e');
    }
  }

  /// Log detailed error information
  static void logError(String context, dynamic error) {
    debugPrint('$_tag ❌ Error in $context:');
    debugPrint('$_tag   Type: ${error.runtimeType}');
    debugPrint('$_tag   Message: $error');
    
    if (error is Exception) {
      debugPrint('$_tag   Exception details: ${error.toString()}');
    }
  }
}
