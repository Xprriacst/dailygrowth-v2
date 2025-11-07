import 'package:flutter/material.dart';

import '../presentation/challenge_history/challenge_history.dart';
import '../presentation/home_dashboard/home_dashboard.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/notification_settings/notification_settings.dart';
import '../presentation/onboarding_flow/onboarding_flow.dart';
import '../presentation/progress_tracking/progress_tracking.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/user_profile/user_profile.dart';
import '../presentation/admin_panel/admin_panel.dart';
import '../presentation/reset_password/reset_password_screen.dart';
import '../presentation/challenge_selection/challenge_selection_screen.dart';
import '../presentation/notes/notes_screen.dart';
import '../debug/test_notes_widget.dart';

class AppRoutes {
  // Route constants
  static const String splashScreen = '/splash-screen';
  static const String loginScreen = '/login-screen';
  static const String onboardingFlow = '/onboarding-flow';
  static const String homeDashboard = '/home-dashboard';
  static const String userProfile = '/user-profile';
  static const String notificationSettings = '/notification-settings';
  static const String challengeHistory = '/challenge-history';
  static const String progressTracking = '/progress-tracking';
  static const String adminPanel = '/admin-panel';
  static const String resetPassword = '/reset-password';
  static const String challengeSelection = '/challenge-selection';
  static const String notes = '/notes';
  static const String testNotes = '/test-notes';

  // Route map
  static Map<String, WidgetBuilder> get routes => {
        splashScreen: (context) => const SplashScreen(),
        loginScreen: (context) => const LoginScreen(),
        onboardingFlow: (context) => const OnboardingFlow(),
        homeDashboard: (context) => const HomeDashboard(),
        userProfile: (context) => const UserProfile(),
        notificationSettings: (context) => const NotificationSettings(),
        challengeHistory: (context) => const ChallengeHistory(),
        progressTracking: (context) => const ProgressTracking(),
        adminPanel: (context) => const AdminPanel(),
        resetPassword: (context) => const ResetPasswordScreen(),
        challengeSelection: (context) => const ChallengeSelectionScreen(),
        notes: (context) => const NotesScreen(),
        testNotes: (context) => const TestNotesWidget(),
      };

  // Initial route
  static String get initialRoute => splashScreen;
}
