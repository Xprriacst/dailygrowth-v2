import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dailygrowth/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Onboarding Flow Integration Tests', () {
    testWidgets('Complete onboarding flow - new user journey', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Test 1: Landing page should be visible
      expect(find.text('DailyGrowth'), findsOneWidget);
      
      // Test 2: Navigate to signup
      await tester.tap(find.text('S\'inscrire'));
      await tester.pumpAndSettle();
      
      // Test 3: Fill signup form
      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'Test User');
      await tester.enterText(find.byType(TextField).at(2), 'password123');
      
      // Test 4: Submit signup (mock success)
      await tester.tap(find.text('Créer un compte'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Test 5: Should navigate to onboarding
      expect(find.text('Bienvenue'), findsOneWidget);
      
      // Test 6: Complete life domain selection
      await tester.tap(find.text('Développement personnel'));
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      
      // Test 7: Select specific problematiques
      await tester.tap(find.text('devenir plus charismatique'));
      await tester.tap(find.text('développer mon réseau'));
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      
      // Test 8: Configure notifications
      await tester.tap(find.byType(Switch));
      await tester.tap(find.text('09:00'));
      await tester.tap(find.text('Terminer'));
      await tester.pumpAndSettle();
      
      // Test 9: Should reach dashboard
      expect(find.text('Votre défi du jour'), findsOneWidget);
      
      // Test 10: Verify first challenge is generated
      expect(find.textContaining('micro-défi'), findsOneWidget);
    });

    testWidgets('Onboarding validation - incomplete data', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to onboarding (assume logged in)
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();
      
      // Try to continue without selecting anything
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      
      // Should show validation error
      expect(find.text('Veuillez sélectionner'), findsOneWidget);
    });

    testWidgets('Onboarding skip and return', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Start onboarding
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();
      
      // Skip onboarding
      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();
      
      // Should reach dashboard with default settings
      expect(find.text('Tableau de bord'), findsOneWidget);
      
      // Return to complete onboarding later
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Compléter le profil'));
      await tester.pumpAndSettle();
      
      // Should return to onboarding
      expect(find.text('Sélectionnez vos domaines'), findsOneWidget);
    });

    testWidgets('Onboarding data persistence', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Complete partial onboarding
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Développement personnel'));
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      
      // Close app (simulate app restart)
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/platform',
        null,
        (data) {},
      );
      
      // Restart app
      app.main();
      await tester.pumpAndSettle();
      
      // Should resume from where left off
      expect(find.text('Sélectionnez vos problématiques'), findsOneWidget);
      
      // Previous selection should be maintained
      expect(find.text('Développement personnel'), findsOneWidget);
    });

    testWidgets('Multiple problematiques selection and validation', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to problematiques selection
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Développement personnel'));
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      
      // Select multiple problematiques
      await tester.tap(find.text('devenir plus charismatique'));
      await tester.tap(find.text('développer mon réseau'));
      await tester.tap(find.text('lâcher-prise'));
      
      // Verify selection count
      expect(find.text('3 sélectionnées'), findsOneWidget);
      
      // Try to select more than maximum allowed
      await tester.tap(find.text('gérer mon stress'));
      await tester.pumpAndSettle();
      
      // Should show limit message
      expect(find.text('Maximum 3 problématiques'), findsOneWidget);
      
      // Continue with valid selection
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      
      // Should proceed to next step
      expect(find.text('Configuration des notifications'), findsOneWidget);
    });

    testWidgets('Notification configuration during onboarding', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to notification configuration
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();
      
      // Complete previous steps quickly
      await tester.tap(find.text('Développement personnel'));
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('devenir plus charismatique'));
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      
      // Test notification configuration
      expect(find.text('Notifications quotidiennes'), findsOneWidget);
      
      // Enable notifications
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      
      // Change notification time
      await tester.tap(find.text('09:00'));
      await tester.pumpAndSettle();
      
      // Select different time in time picker
      await tester.tap(find.text('10'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      
      // Verify time changed
      expect(find.text('10:00'), findsOneWidget);
      
      // Enable reminder notifications
      final reminderSwitch = find.byType(Switch).last;
      await tester.tap(reminderSwitch);
      await tester.pumpAndSettle();
      
      // Complete onboarding
      await tester.tap(find.text('Terminer'));
      await tester.pumpAndSettle();
      
      // Should reach dashboard with notifications configured
      expect(find.text('Notifications activées à 10:00'), findsOneWidget);
    });
  });
}
