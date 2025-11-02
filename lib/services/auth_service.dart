import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import './supabase_service.dart';
import './user_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  late final SupabaseClient _client;
  bool _isInitialized = false;
  StreamSubscription<AuthState>? _authSubscription;

  // Authentication state stream controller
  final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();
  Stream<bool> get authStateStream => _authStateController.stream;

  Future<void> initialize() async {
    if (!_isInitialized) {
      _client = await SupabaseService().client;
      _isInitialized = true;

      // Set up persistent auth state monitoring
      _setupAuthStateMonitoring();
    }
  }

  void _setupAuthStateMonitoring() {
    _authSubscription = _client.auth.onAuthStateChange.listen(
      (event) {
        try {
          final isAuthenticated =
              event.session != null && event.session?.user != null;
          _authStateController.add(isAuthenticated);

          if (event.event == AuthChangeEvent.signedOut ||
              event.event == AuthChangeEvent.tokenRefreshed) {
            debugPrint('Auth state changed: ${event.event}');
          }

          // Handle session expiry
          if (event.event == AuthChangeEvent.tokenRefreshed &&
              event.session == null) {
            debugPrint('Session expired - user needs to re-authenticate');
          }
        } catch (e) {
          debugPrint('❌ Error in auth state monitoring: $e');
          // Ensure we don't break the auth flow on errors
          _authStateController.add(false);
        }
      },
      onError: (error) {
        debugPrint('❌ Auth state stream error: $error');
        
        // Handle specific PKCE/localStorage errors
        if (error.toString().contains('Code verifier could not be found')) {
          debugPrint('🔧 Detected PKCE localStorage issue - attempting fix...');
          // Clear auth state and suggest manual browser storage clear
          clearAuthState().then((_) {
            debugPrint('💡 Please clear browser storage manually:');
            debugPrint('   1. Open console (F12)');
            debugPrint('   2. Run: localStorage.clear(); sessionStorage.clear();');
            debugPrint('   3. Refresh page and try again');
          });
        }
        
        _authStateController.add(false);
      },
    );
  }

  // Check if user is currently authenticated with enhanced validation
  bool get isAuthenticated {
    try {
      final user = _client.auth.currentUser;
      final session = _client.auth.currentSession;

      if (user == null || session == null) return false;

      // Check if session is expired
      final expiresAt =
          DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
      if (DateTime.now().isAfter(expiresAt)) {
        debugPrint('Session expired');
        return false;
      }

      return user.aud == 'authenticated';
    } catch (e) {
      debugPrint('Error checking authentication: $e');
      return false;
    }
  }

  // Get current user
  User? get currentUser {
    try {
      return _client.auth.currentUser;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  // Get current user ID
  String? get userId {
    try {
      return _client.auth.currentUser?.id;
    } catch (e) {
      debugPrint('Error getting user ID: $e');
      return null;
    }
  }

  // Get current session
  Session? get currentSession {
    try {
      return _client.auth.currentSession;
    } catch (e) {
      debugPrint('Error getting current session: $e');
      return null;
    }
  }

  // Enhanced session validation with automatic refresh
  Future<bool> validateAndRefreshSession() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) return false;

      // Check if session is close to expiring (within 5 minutes)
      final expiresAt =
          DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
      final now = DateTime.now();
      final timeUntilExpiry = expiresAt.difference(now);

      // If session expires in less than 5 minutes, refresh it
      if (timeUntilExpiry.inMinutes < 5) {
        debugPrint('Session expiring soon, refreshing...');
        try {
          final response = await _client.auth.refreshSession();
          return response.session != null;
        } catch (e) {
          debugPrint('Failed to refresh session: $e');
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Session validation failed: $e');
      return false;
    }
  }

  // Sign in with email and password - ENHANCED FOR BETTER ERROR HANDLING
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Attempting sign-in for email: $email');

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Sign in failed - no user returned');
      }

      debugPrint('Sign-in successful for user: ${response.user!.email}');
      
      // NOUVEAU: Synchroniser les problématiques après connexion réussie
      await _syncProblematiquesAfterLogin();
      
      return response;
    } catch (error) {
      debugPrint('Sign in error: $error');

      // Enhanced error handling for common authentication issues
      String errorMessage = 'Erreur de connexion: ';

      if (error.toString().contains('Invalid login credentials') ||
          error.toString().contains('invalid_credentials')) {
        errorMessage += 'Email ou mot de passe incorrect.';
      } else if (error.toString().contains('Email not confirmed') ||
          error.toString().contains('email_not_confirmed')) {
        errorMessage +=
            'Veuillez confirmer votre email avant de vous connecter.';
      } else if (error.toString().contains('Too many requests') ||
          error.toString().contains('rate_limit')) {
        errorMessage +=
            'Trop de tentatives. Veuillez réessayer dans quelques minutes.';
      } else if (error.toString().contains('User not found') ||
          error.toString().contains('user_not_found')) {
        errorMessage += 'Aucun compte trouvé avec cet email.';
      } else {
        errorMessage += error.toString();
      }

      throw Exception(errorMessage);
    }
  }

  // Sign up with email and password - ENHANCED FOR DEEP LINKING
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    List<String>? selectedLifeDomains,
  }) async {
    try {
      debugPrint('Attempting sign-up for email: $email');

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          if (selectedLifeDomains != null)
            'selected_life_domains': selectedLifeDomains,
        },
        emailRedirectTo: kIsWeb
            ? null
            : 'io.supabase.dailygrowth://login-callback/', // Deep link for mobile
      );

      if (response.user == null) {
        throw Exception('Sign up failed - no user returned');
      }

      debugPrint('Sign-up successful for user: ${response.user!.email}');
      debugPrint(
          'Email confirmation needed: ${response.user!.emailConfirmedAt == null ? "Yes" : "No"}');

      return response;
    } catch (error) {
      debugPrint('Sign up error: $error');

      // Enhanced error handling for sign up issues
      String errorMessage = 'Erreur d\'inscription: ';

      if (error.toString().contains('User already registered') ||
          error.toString().contains('already_registered')) {
        errorMessage += 'Un compte existe déjà avec cet email.';
      } else if (error.toString().contains('Password should be at least') ||
          error.toString().contains('password_too_short')) {
        errorMessage += 'Le mot de passe doit contenir au moins 6 caractères.';
      } else if (error.toString().contains('Invalid email') ||
          error.toString().contains('invalid_email')) {
        errorMessage += 'Format d\'email invalide.';
      } else {
        errorMessage += error.toString();
      }

      throw Exception(errorMessage);
    }
  }

  // Sign in with Google - ENHANCED FOR MOBILE DEEP LINKING
  Future<bool> signInWithGoogle() async {
    try {
      debugPrint('Attempting Google sign-in...');

      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.dailygrowth://login-callback/',
      );

      debugPrint('Google sign-in response: $response');
      return response;
    } catch (error) {
      debugPrint('Google sign in error: $error');
      throw Exception('Erreur de connexion Google: $error');
    }
  }

  // Sign in with Apple - ENHANCED FOR MOBILE DEEP LINKING
  Future<bool> signInWithApple() async {
    try {
      debugPrint('Attempting Apple sign-in...');

      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: kIsWeb ? null : 'io.supabase.dailygrowth://login-callback/',
      );

      debugPrint('Apple sign-in response: $response');
      return response;
    } catch (error) {
      debugPrint('Apple sign in error: $error');
      throw Exception('Erreur de connexion Apple: $error');
    }
  }

  // Reset password - ENHANCED FOR MOBILE DEEP LINKING
  Future<void> resetPassword(String email) async {
    try {
      debugPrint('Sending password reset email to: $email');

      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb 
          ? 'https://challengeme.ch/reset-password' 
          : 'io.supabase.dailygrowth://reset-password/',
      );

      debugPrint('Password reset email sent successfully');
    } catch (error) {
      debugPrint('Reset password error: $error');
      throw Exception('Erreur de réinitialisation: $error');
    }
  }

  // Resend email confirmation
  Future<void> resendConfirmation(String email) async {
    try {
      debugPrint('Resending confirmation email to: $email');

      await _client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: kIsWeb ? null : 'io.supabase.dailygrowth://confirm/',
      );

      debugPrint('Confirmation email resent successfully');
    } catch (error) {
      debugPrint('Resend confirmation error: $error');
      throw Exception('Erreur de renvoi de confirmation: $error');
    }
  }

  // Update password
  Future<UserResponse> updatePassword({required String newPassword}) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        throw Exception('Password update failed');
      }

      return response;
    } catch (error) {
      debugPrint('Update password error: $error');
      throw Exception('Erreur de mise à jour du mot de passe: $error');
    }
  }

  // Update email
  Future<UserResponse> updateEmail({required String newEmail}) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(email: newEmail),
      );

      if (response.user == null) {
        throw Exception('Email update failed');
      }

      return response;
    } catch (error) {
      debugPrint('Update email error: $error');
      throw Exception('Erreur de mise à jour de l\'email: $error');
    }
  }

  // Refresh session
  Future<AuthResponse> refreshSession() async {
    try {
      final response = await _client.auth.refreshSession();

      if (response.user == null) {
        throw Exception('Session refresh failed');
      }

      return response;
    } catch (error) {
      debugPrint('Refresh session error: $error');
      throw Exception('Erreur de rafraîchissement de session: $error');
    }
  }

  // Sign out with cleanup
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      _authStateController.add(false);
    } catch (error) {
      debugPrint('Sign out error: $error');
      throw Exception('Erreur de déconnexion: $error');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // This would require admin privileges or RPC function
      // Implementation depends on your backend setup
      throw Exception('Fonctionnalité non implémentée');
    } catch (error) {
      debugPrint('Delete account error: $error');
      throw Exception('Erreur de suppression de compte: $error');
    }
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges {
    return _client.auth.onAuthStateChange;
  }

  // Get access token
  String? get accessToken {
    try {
      return _client.auth.currentSession?.accessToken;
    } catch (e) {
      debugPrint('Error getting access token: $e');
      return null;
    }
  }

  // Check if session is expired
  bool get isSessionExpired {
    try {
      final session = _client.auth.currentSession;
      if (session == null) return true;

      final expiresAt =
          DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
      return DateTime.now().isAfter(expiresAt);
    } catch (e) {
      debugPrint('Error checking session expiry: $e');
      return true;
    }
  }

  // Validate current session
  Future<bool> validateSession() async {
    try {
      if (!isAuthenticated || isSessionExpired) {
        return false;
      }

      // Try to get user profile to validate session
      final user = await _client.auth.getUser();
      return user.user != null;
    } catch (e) {
      debugPrint('Session validation failed: $e');
      return false;
    }
  }



  // Clear authentication state and local storage
  Future<void> clearAuthState() async {
    try {
      debugPrint('🧹 Clearing authentication state and local storage...');
      
      // Sign out if authenticated
      if (isAuthenticated) {
        await signOut();
      }
      
      // Clear any remaining session data
      await _client.auth.signOut();
      
      debugPrint('✅ Authentication state cleared successfully');
    } catch (e) {
      debugPrint('❌ Error clearing auth state: $e');
    }
  }

  // Clean up resources
  void dispose() {
    _authSubscription?.cancel();
    _authStateController.close();
  }

  // Synchroniser les problématiques depuis SharedPreferences vers Supabase après connexion
  Future<void> _syncProblematiquesAfterLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedProblematiques = prefs.getStringList('selected_problematiques');
      
      if (selectedProblematiques != null && selectedProblematiques.isNotEmpty) {
        debugPrint('🔄 Synchronisation des problématiques après connexion: $selectedProblematiques');
        
        final userService = UserService();
        await userService.initialize();
        
        final currentUser = _client.auth.currentUser;
        if (currentUser != null) {
          await userService.updateUserProfile(
            userId: currentUser.id,
            selectedProblematiques: selectedProblematiques,
          );
          debugPrint('✅ Problématiques synchronisées vers Supabase après connexion');
        }
      } else {
        debugPrint('ℹ️ Aucune problématique à synchroniser');
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la synchronisation des problématiques: $e');
    }
  }
}