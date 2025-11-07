import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  print('🔍 Test de connexion à la base de données Notes...\n');

  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: 'https://hekdcsulxrukfturuone.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQwNTEyMDQsImV4cCI6MjA2OTYyNzIwNH0.xLlrQwSL44QpYdeMPF1PIt3DZoaZ6Cjs2OIvEX58CnY',
    );

    final supabase = Supabase.instance.client;
    print('✅ Connexion Supabase initialisée\n');

    // Test 1: Check if notes table exists
    print('📋 Test 1: Vérification de l\'existence de la table notes...');
    try {
      final result = await supabase
          .from('notes')
          .select('count')
          .limit(1);
      print('✅ La table "notes" existe et est accessible');
      print('   Résultat: $result\n');
    } catch (e) {
      print('❌ Erreur: La table "notes" n\'existe pas ou n\'est pas accessible');
      print('   Détails: $e\n');
      return;
    }

    // Test 2: Check current user
    print('📋 Test 2: Vérification de l\'utilisateur connecté...');
    final user = supabase.auth.currentUser;
    if (user != null) {
      print('✅ Utilisateur connecté: ${user.email}');
      print('   User ID: ${user.id}\n');
    } else {
      print('❌ Aucun utilisateur connecté');
      print('   Vous devez vous connecter pour tester les notes\n');
      return;
    }

    // Test 3: Count existing notes
    print('📋 Test 3: Comptage des notes existantes...');
    try {
      final notes = await supabase
          .from('notes')
          .select()
          .eq('user_id', user.id);
      print('✅ Nombre de notes pour cet utilisateur: ${notes.length}');
      if (notes.isNotEmpty) {
        print('   Aperçu des notes:');
        for (var note in notes) {
          print('   - ID: ${note['id']}');
          print('     Contenu: ${note['content'].toString().substring(0, note['content'].toString().length > 50 ? 50 : note['content'].toString().length)}...');
          print('     Créé le: ${note['created_at']}');
        }
      }
      print('');
    } catch (e) {
      print('❌ Erreur lors de la récupération des notes: $e\n');
      return;
    }

    // Test 4: Try to create a test note
    print('📋 Test 4: Création d\'une note de test...');
    try {
      final now = DateTime.now();
      final testNote = {
        'user_id': user.id,
        'content': 'Note de test créée le ${now.toIso8601String()}',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      
      final response = await supabase
          .from('notes')
          .insert(testNote)
          .select()
          .single();
      
      print('✅ Note de test créée avec succès!');
      print('   ID: ${response['id']}');
      print('   Contenu: ${response['content']}\n');

      // Test 5: Delete the test note
      print('📋 Test 5: Suppression de la note de test...');
      await supabase
          .from('notes')
          .delete()
          .eq('id', response['id']);
      print('✅ Note de test supprimée\n');
      
    } catch (e) {
      print('❌ Erreur lors de la création/suppression de la note: $e\n');
      return;
    }

    print('🎉 TOUS LES TESTS SONT PASSÉS!\n');
    print('Le système de notes est fonctionnel. Si vous ne voyez pas vos notes dans l\'app,');
    print('vérifiez les logs de debug de NoteService dans la console Flutter.\n');

  } catch (e) {
    print('❌ ERREUR CRITIQUE: $e');
  }
}
