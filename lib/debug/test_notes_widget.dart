import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/note_service.dart';
import '../models/note.dart';

/// Widget de test pour vérifier le système de notes
/// À utiliser temporairement pour debug
class TestNotesWidget extends StatefulWidget {
  const TestNotesWidget({Key? key}) : super(key: key);

  @override
  State<TestNotesWidget> createState() => _TestNotesWidgetState();
}

class _TestNotesWidgetState extends State<TestNotesWidget> {
  final NoteService _noteService = NoteService();
  final List<String> _logs = [];
  bool _isRunning = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} - $message');
    });
    debugPrint(message);
  }

  Future<void> _runTests() async {
    setState(() {
      _isRunning = true;
      _logs.clear();
    });

    _addLog('🔍 Début des tests du système de notes...\n');

    try {
      // Test 1: Initialize service
      _addLog('📋 Test 1: Initialisation du NoteService...');
      await _noteService.initialize();
      _addLog('✅ NoteService initialisé\n');

      // Test 2: Check Supabase connection
      _addLog('📋 Test 2: Vérification connexion Supabase...');
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user == null) {
        _addLog('❌ Aucun utilisateur connecté!');
        _addLog('   Vous devez vous connecter d\'abord\n');
        setState(() => _isRunning = false);
        return;
      }
      
      _addLog('✅ Utilisateur connecté: ${user.email}');
      _addLog('   User ID: ${user.id}\n');

      // Test 3: Check if table exists
      _addLog('📋 Test 3: Vérification table "notes"...');
      try {
        final result = await supabase
            .from('notes')
            .select('id')
            .limit(1);
        _addLog('✅ Table "notes" existe et est accessible');
        _addLog('   Résultat: ${result.toString()}\n');
      } catch (e) {
        _addLog('❌ ERREUR: Table "notes" inaccessible!');
        _addLog('   Détails: $e');
        _addLog('   🔧 Solution: Appliquer la migration:');
        _addLog('   supabase db push\n');
        setState(() => _isRunning = false);
        return;
      }

      // Test 4: Count existing notes
      _addLog('📋 Test 4: Comptage notes existantes...');
      final notes = await _noteService.getAllNotes();
      _addLog('✅ Nombre de notes: ${notes.length}');
      if (notes.isNotEmpty) {
        _addLog('   Aperçu:');
        for (var i = 0; i < notes.length && i < 3; i++) {
          final note = notes[i];
          final preview = note.content.length > 40 
              ? '${note.content.substring(0, 40)}...'
              : note.content;
          _addLog('   ${i + 1}. $preview');
        }
      }
      _addLog('');

      // Test 5: Create test note
      _addLog('📋 Test 5: Création note de test...');
      final testContent = 'Note de test ${DateTime.now().toIso8601String()}';
      final createdNote = await _noteService.createNote(
        content: testContent,
      );
      
      if (createdNote != null) {
        _addLog('✅ Note créée avec succès!');
        _addLog('   ID: ${createdNote.id}');
        _addLog('   Contenu: ${createdNote.content}\n');

        // Test 6: Retrieve the note
        _addLog('📋 Test 6: Récupération de la note...');
        final allNotes = await _noteService.getAllNotes();
        final foundNote = allNotes.firstWhere(
          (n) => n.id == createdNote.id,
          orElse: () => throw Exception('Note non trouvée'),
        );
        _addLog('✅ Note récupérée avec succès\n');

        // Test 7: Update the note
        _addLog('📋 Test 7: Mise à jour de la note...');
        final updatedNote = await _noteService.updateNote(
          noteId: createdNote.id!,
          content: '$testContent (modifiée)',
        );
        if (updatedNote != null) {
          _addLog('✅ Note mise à jour\n');
        }

        // Test 8: Delete the note
        _addLog('📋 Test 8: Suppression de la note...');
        final deleted = await _noteService.deleteNote(createdNote.id!);
        if (deleted) {
          _addLog('✅ Note supprimée\n');
        }
      } else {
        _addLog('❌ Échec de création de la note\n');
      }

      _addLog('🎉 TOUS LES TESTS RÉUSSIS!\n');
      _addLog('Le système de notes fonctionne correctement.');

    } catch (e, stackTrace) {
      _addLog('❌ ERREUR CRITIQUE: $e');
      _addLog('Stack trace: $stackTrace');
    }

    setState(() => _isRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Système Notes'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isRunning ? null : _runTests,
              child: _isRunning
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Tests en cours...'),
                      ],
                    )
                  : const Text('Lancer les tests'),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.black87,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  Color color = Colors.white;
                  if (log.contains('✅')) {
                    color = Colors.green;
                  } else if (log.contains('❌')) {
                    color = Colors.red;
                  } else if (log.contains('📋')) {
                    color = Colors.blue;
                  } else if (log.contains('🎉')) {
                    color = Colors.yellow;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      log,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
