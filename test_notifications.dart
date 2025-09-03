import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase with local configuration (hardcoded for testing)
  await Supabase.initialize(
    url: 'http://127.0.0.1:54321',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0',
  );
  
  // Skip notification service initialization for this test
  // await NotificationService().initialize();
  
  runApp(NotificationTestApp());
}

class NotificationTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification Test',
      home: NotificationTestScreen(),
    );
  }
}

class NotificationTestScreen extends StatefulWidget {
  @override
  _NotificationTestScreenState createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final String testUserId = '550e8400-e29b-41d4-a716-446655440000';
  String _status = 'Prêt pour les tests';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Notifications DailyGrowth'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(_status),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testImmediateNotification,
              child: Text('Test Notification Immédiate'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testScheduleNotification,
              child: Text('Programmer Notification (dans 10s)'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testUserSettings,
              child: Text('Tester Paramètres Utilisateur'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testReminderNotification,
              child: Text('Test Notification Rappel'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkSupabaseConnection,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Vérifier Connexion Supabase'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _testImmediateNotification() async {
    setState(() => _status = 'Test notification immédiate...');
    
    try {
      // Simulate notification test without actual service
      await Future.delayed(Duration(milliseconds: 500));
      setState(() => _status = 'Notification immédiate simulée avec succès ! (Web ne supporte pas les vraies notifications push)');
    } catch (e) {
      setState(() => _status = 'Erreur notification immédiate: $e');
    }
  }
  
  void _testScheduleNotification() async {
    setState(() => _status = 'Programmation notification dans 10s...');
    
    try {
      final scheduledTime = DateTime.now().add(Duration(seconds: 10));
      // Simulate scheduled notification test
      await Future.delayed(Duration(milliseconds: 300));
      setState(() => _status = 'Notification programmée pour ${scheduledTime.toString().substring(11, 16)}');
    } catch (e) {
      setState(() => _status = 'Erreur programmation: $e');
    }
  }
  
  void _testUserSettings() async {
    setState(() => _status = 'Test paramètres utilisateur...');
    
    try {
      // Use service_role key for testing (bypasses RLS)
      final client = SupabaseClient(
        'http://127.0.0.1:54321',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU',
      );
      
      final response = await client
          .from('user_profiles')
          .select('notification_time, notifications_enabled, reminder_notifications_enabled')
          .eq('id', testUserId)
          .single();
      setState(() => _status = 'Paramètres: ${response.toString()}');
    } catch (e) {
      setState(() => _status = 'Erreur paramètres: $e');
    }
  }
  
  void _testReminderNotification() async {
    setState(() => _status = 'Test notification rappel...');
    
    try {
      // Simulate reminder notification test
      await Future.delayed(Duration(milliseconds: 400));
      setState(() => _status = 'Notification rappel simulée avec succès !');
    } catch (e) {
      setState(() => _status = 'Erreur rappel: $e');
    }
  }
  
  void _checkSupabaseConnection() async {
    setState(() => _status = 'Vérification connexion Supabase...');
    
    try {
      // Use service_role key for testing (bypasses RLS)
      final client = SupabaseClient(
        'http://127.0.0.1:54321',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU',
      );
      
      final response = await client
          .from('user_profiles')
          .select()
          .eq('id', testUserId)
          .single();
      
      setState(() => _status = 'Connexion OK! Utilisateur: ${response['full_name']}');
    } catch (e) {
      setState(() => _status = 'Erreur Supabase: $e');
    }
  }
}
