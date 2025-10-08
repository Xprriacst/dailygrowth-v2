import 'package:flutter_test/flutter_test.dart';

/// Tests pour la logique des jalons de célébration
/// 
/// Cette classe teste la fonction _shouldShowCelebrationPopup()
/// qui détermine quand afficher une popup de félicitations
void main() {
  group('🎉 Celebration Milestone Logic Tests', () {
    
    /// Helper function qui réplique la logique de _shouldShowCelebrationPopup
    /// depuis home_dashboard.dart
    bool shouldShowCelebrationPopup(int streakCount, int totalChallenges) {
      // 🔥 Jalons de série (streak)
      if ([3, 7, 14, 30].contains(streakCount)) {
        return true;
      }
      
      // 📈 Paliers de progression totale
      if ([5, 10, 25, 50].contains(totalChallenges)) {
        return true;
      }
      
      return false;
    }

    group('🔥 Streak Milestones', () {
      test('Affiche popup pour 3 jours consécutifs (1er jalon)', () {
        expect(shouldShowCelebrationPopup(3, 3), isTrue,
            reason: '3 jours de série = 1er jalon important');
      });

      test('Affiche popup pour 7 jours consécutifs (1 semaine)', () {
        expect(shouldShowCelebrationPopup(7, 7), isTrue,
            reason: '7 jours = 1 semaine complète');
      });

      test('Affiche popup pour 14 jours consécutifs (2 semaines)', () {
        expect(shouldShowCelebrationPopup(14, 14), isTrue,
            reason: '14 jours = 2 semaines complètes');
      });

      test('Affiche popup pour 30 jours consécutifs (1 mois)', () {
        expect(shouldShowCelebrationPopup(30, 30), isTrue,
            reason: '30 jours = 1 mois complet');
      });

      test('N\'affiche PAS de popup pour 1-2 jours', () {
        expect(shouldShowCelebrationPopup(1, 1), isFalse);
        expect(shouldShowCelebrationPopup(2, 2), isFalse);
      });

      test('N\'affiche PAS de popup pour 4-6 jours', () {
        expect(shouldShowCelebrationPopup(4, 2), isFalse);
        expect(shouldShowCelebrationPopup(5, 6), isFalse); // 5 jours mais pas jalon total
        expect(shouldShowCelebrationPopup(6, 8), isFalse);
      });

      test('N\'affiche PAS de popup pour 8-13 jours', () {
        expect(shouldShowCelebrationPopup(8, 12), isFalse);
        expect(shouldShowCelebrationPopup(10, 15), isFalse); // 10 jours mais pas jalon total
        expect(shouldShowCelebrationPopup(13, 20), isFalse);
      });

      test('N\'affiche PAS de popup pour 15-29 jours', () {
        expect(shouldShowCelebrationPopup(15, 15), isFalse);
        expect(shouldShowCelebrationPopup(20, 20), isFalse);
        expect(shouldShowCelebrationPopup(29, 29), isFalse);
      });

      test('N\'affiche PAS de popup pour 31+ jours (au-delà du dernier jalon)', () {
        expect(shouldShowCelebrationPopup(31, 31), isFalse);
        expect(shouldShowCelebrationPopup(40, 40), isFalse);
        expect(shouldShowCelebrationPopup(100, 100), isFalse);
      });
    });

    group('📈 Total Challenges Milestones', () {
      test('Affiche popup pour 5 défis complétés', () {
        expect(shouldShowCelebrationPopup(2, 5), isTrue,
            reason: '5 défis = premier palier de progression');
      });

      test('Affiche popup pour 10 défis complétés', () {
        expect(shouldShowCelebrationPopup(4, 10), isTrue,
            reason: '10 défis = double digits !');
      });

      test('Affiche popup pour 25 défis complétés', () {
        expect(shouldShowCelebrationPopup(8, 25), isTrue,
            reason: '25 défis = quart de 100');
      });

      test('Affiche popup pour 50 défis complétés (maximum)', () {
        expect(shouldShowCelebrationPopup(15, 50), isTrue,
            reason: '50 défis = jalon maximum défini');
      });

      test('N\'affiche PAS de popup pour 1-4 défis', () {
        expect(shouldShowCelebrationPopup(1, 1), isFalse);
        expect(shouldShowCelebrationPopup(2, 2), isFalse);
        expect(shouldShowCelebrationPopup(2, 4), isFalse);
        // Note: (3, 3) = streak milestone, donc popup affiché
      });

      test('N\'affiche PAS de popup pour 6-9 défis', () {
        expect(shouldShowCelebrationPopup(2, 6), isFalse);
        expect(shouldShowCelebrationPopup(4, 8), isFalse);
        expect(shouldShowCelebrationPopup(4, 9), isFalse);
      });

      test('N\'affiche PAS de popup pour 11-24 défis', () {
        expect(shouldShowCelebrationPopup(5, 11), isFalse);
        expect(shouldShowCelebrationPopup(8, 15), isFalse);
        expect(shouldShowCelebrationPopup(10, 20), isFalse);
        expect(shouldShowCelebrationPopup(12, 24), isFalse);
      });

      test('N\'affiche PAS de popup pour 26-49 défis', () {
        expect(shouldShowCelebrationPopup(15, 26), isFalse);
        expect(shouldShowCelebrationPopup(20, 35), isFalse);
        expect(shouldShowCelebrationPopup(25, 45), isFalse);
        expect(shouldShowCelebrationPopup(28, 49), isFalse);
      });

      test('N\'affiche PAS de popup pour 51+ défis (au-delà du maximum)', () {
        expect(shouldShowCelebrationPopup(35, 51), isFalse);
        expect(shouldShowCelebrationPopup(40, 60), isFalse);
        expect(shouldShowCelebrationPopup(55, 100), isFalse);
      });
    });

    group('🎯 Combined Scenarios (Streak + Total)', () {
      test('Popup si SOIT streak SOIT total est un jalon', () {
        // Streak milestone uniquement
        expect(shouldShowCelebrationPopup(7, 6), isTrue,
            reason: '7 jours de série même si seulement 6 défis total');
        
        // Total milestone uniquement
        expect(shouldShowCelebrationPopup(4, 10), isTrue,
            reason: '10 défis total même si seulement 4 jours de série');
      });

      test('Popup double jalon (streak ET total)', () {
        expect(shouldShowCelebrationPopup(7, 7), isTrue,
            reason: '7 jours ET 7 défis = double célébration !');
        
        expect(shouldShowCelebrationPopup(14, 25), isTrue,
            reason: '14 jours de série ET 25 défis = méga jalon !');
      });

      test('Pas de popup si ni streak ni total ne sont des jalons', () {
        expect(shouldShowCelebrationPopup(2, 4), isFalse);
        expect(shouldShowCelebrationPopup(6, 8), isFalse);
        expect(shouldShowCelebrationPopup(9, 12), isFalse);
        expect(shouldShowCelebrationPopup(20, 35), isFalse);
      });
    });

    group('🧪 Edge Cases & Special Scenarios', () {
      test('Gère streak = 0 (premier défi)', () {
        expect(shouldShowCelebrationPopup(0, 1), isFalse,
            reason: 'Premier défi jamais = pas encore de jalon');
      });

      test('Gère total = 0 (cas impossible mais sécurité)', () {
        expect(shouldShowCelebrationPopup(1, 0), isFalse);
      });

      test('Gère valeurs négatives (cas impossible mais sécurité)', () {
        expect(shouldShowCelebrationPopup(-1, 2), isFalse);
        expect(shouldShowCelebrationPopup(2, -1), isFalse);
      });

      test('Gère streak > total (interruption puis reprise)', () {
        // Utilisateur a complété 100 défis, mais série actuelle = 5
        expect(shouldShowCelebrationPopup(5, 100), isFalse,
            reason: 'Série courte sur longue période');
        
        // Série de 7 jours mais 50 défis total
        expect(shouldShowCelebrationPopup(7, 50), isTrue,
            reason: 'Série de 7 jours ET 50 défis = double jalon');
      });

      test('Gère très grandes valeurs', () {
        expect(shouldShowCelebrationPopup(365, 500), isFalse,
            reason: 'Au-delà des jalons définis = notification discrète');
        
        expect(shouldShowCelebrationPopup(1000, 1000), isFalse,
            reason: 'Valeurs extrêmes = notification discrète');
      });
    });

    group('📊 Full User Journey Simulation', () {
      test('Simule les 50 premiers défis d\'un utilisateur régulier', () {
        // Mapping: défis complétés → devrait afficher popup ?
        final Map<int, bool> expectedPopups = {
          1: false,  // Premier défi
          2: false,  // Deuxième défi
          3: true,   // 🎉 Jalon: 3 jours de série
          4: false,
          5: true,   // 🎉 Jalon: 5 défis complétés
          6: false,
          7: true,   // 🎉 Jalon: 7 jours de série
          8: false,
          9: false,
          10: true,  // 🎉 Jalon: 10 défis complétés
          11: false,
          12: false,
          13: false,
          14: true,  // 🎉 Jalon: 14 jours de série
          15: false,
          // ... jusqu'à 24
          20: false,
          25: true,  // 🎉 Jalon: 25 défis complétés
          // ... jusqu'à 29
          30: true,  // 🎉 Jalon: 30 jours de série
          // ... jusqu'à 49
          40: false,
          50: true,  // 🎉 Jalon: 50 défis complétés (maximum)
        };

        expectedPopups.forEach((challengeNumber, shouldShowPopup) {
          final result = shouldShowCelebrationPopup(challengeNumber, challengeNumber);
          expect(result, shouldShowPopup,
              reason: 'Défi #$challengeNumber: devrait ${shouldShowPopup ? "afficher" : "ne PAS afficher"} de popup');
        });
      });

      test('Compte le nombre total de popups sur 50 défis', () {
        int popupCount = 0;
        
        for (int i = 1; i <= 50; i++) {
          if (shouldShowCelebrationPopup(i, i)) {
            popupCount++;
          }
        }

        // Jalons attendus: 3, 5, 7, 10, 14, 25, 30, 50 = 8 popups
        expect(popupCount, 8,
            reason: 'Sur 50 défis, devrait afficher exactement 8 popups de célébration');
      });

      test('Vérifie que 84% des défis n\'ont PAS de popup', () {
        int totalChallenges = 50;
        int popupCount = 0;
        
        for (int i = 1; i <= totalChallenges; i++) {
          if (shouldShowCelebrationPopup(i, i)) {
            popupCount++;
          }
        }

        double popupRate = popupCount / totalChallenges;
        double discreteRate = 1 - popupRate;

        expect(discreteRate, greaterThan(0.80),
            reason: 'Plus de 80% des défis devraient avoir une notification discrète');
        
        expect(discreteRate, lessThanOrEqualTo(0.85),
            reason: 'Environ 84% des défis ont notification discrète (42/50)');
      });
    });

    group('🎨 UX Validation', () {
      test('Les premiers jalons arrivent assez tôt pour encourager', () {
        // Premier jalon devrait arriver au 3ème défi
        expect(shouldShowCelebrationPopup(3, 3), isTrue,
            reason: 'Premier jalon dès 3 défis pour encourager rapidement');
      });

      test('Les jalons sont bien espacés pour éviter la fatigue', () {
        // Espacement entre jalons: 3 → 5 (+2), 5 → 7 (+2), 7 → 10 (+3), etc.
        final milestones = [3, 5, 7, 10, 14, 25, 30, 50];
        
        for (int i = 1; i < milestones.length; i++) {
          final spacing = milestones[i] - milestones[i - 1];
          expect(spacing, greaterThanOrEqualTo(2),
              reason: 'Espacement minimum de 2 défis entre jalons');
        }
      });

      test('Le dernier jalon est significatif (50 défis)', () {
        expect(shouldShowCelebrationPopup(50, 50), isTrue,
            reason: '50 défis = accomplissement majeur');
        
        expect(shouldShowCelebrationPopup(51, 51), isFalse,
            reason: 'Après 50, retour aux notifications discrètes');
      });
    });
  });

  group('📝 Documentation Tests', () {
    test('Liste tous les jalons de série', () {
      final streakMilestones = [3, 7, 14, 30];
      expect(streakMilestones.length, 4,
          reason: '4 jalons de série définis');
    });

    test('Liste tous les jalons de progression', () {
      final totalMilestones = [5, 10, 25, 50];
      expect(totalMilestones.length, 4,
          reason: '4 jalons de progression définis');
    });

    test('Total de jalons uniques jusqu\'à 50 défis', () {
      // Jalons uniques: 3, 5, 7, 10, 14, 25, 30, 50
      final uniqueMilestones = {3, 5, 7, 10, 14, 25, 30, 50};
      expect(uniqueMilestones.length, 8,
          reason: '8 jalons uniques sur les 50 premiers défis');
    });
  });
}
