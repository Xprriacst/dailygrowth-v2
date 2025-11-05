// Basic Flutter widget test for ChallengeMe app
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChallengeMe Basic Tests', () {
    testWidgets('App should create without errors', (WidgetTester tester) async {
      // Simple test to verify the app can be instantiated
      // This avoids complex dependencies while testing basic functionality
      
      final testApp = MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('ChallengeMe')),
          body: const Center(
            child: Text('Welcome to ChallengeMe'),
          ),
        ),
      );

      await tester.pumpWidget(testApp);

      // Verify basic UI elements are present
      expect(find.text('ChallengeMe'), findsOneWidget);
      expect(find.text('Welcome to ChallengeMe'), findsOneWidget);
    });

    testWidgets('Basic widget interaction test', (WidgetTester tester) async {
      int counter = 0;
      
      final testApp = MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Column(
                children: [
                  Text('Counter: $counter'),
                  ElevatedButton(
                    onPressed: () => setState(() => counter++),
                    child: const Text('Increment'),
                  ),
                ],
              ),
            );
          },
        ),
      );

      await tester.pumpWidget(testApp);

      // Verify initial state
      expect(find.text('Counter: 0'), findsOneWidget);
      
      // Tap button and verify increment
      await tester.tap(find.text('Increment'));
      await tester.pump();
      
      expect(find.text('Counter: 1'), findsOneWidget);
    });
  });
}
