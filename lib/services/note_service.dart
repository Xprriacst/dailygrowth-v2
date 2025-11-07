import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note.dart';
import './supabase_service.dart';
import './auth_service.dart';

class NoteService {
  static final NoteService _instance = NoteService._internal();
  factory NoteService() => _instance;
  NoteService._internal();

  final _supabaseService = SupabaseService();
  final _authService = AuthService();
  SupabaseClient get _supabase => _supabaseService.clientSync;

  bool _initialized = false;

  // Initialize service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      debugPrint('[NoteService] Initializing...');
      _initialized = true;
      debugPrint('[NoteService] ✅ Initialized successfully');
    } catch (e) {
      debugPrint('[NoteService] ❌ Initialization error: $e');
      _initialized = false;
      rethrow;
    }
  }

  // Get current user ID
  String? get _currentUserId => _authService.userId;

  // Create a new note
  Future<Note?> createNote({
    required String content,
    String? challengeId,
    String? challengeTitle,
    String? problematique,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      if (content.trim().isEmpty) {
        throw Exception('Note content cannot be empty');
      }

      final now = DateTime.now();
      final noteData = {
        'user_id': _currentUserId,
        'challenge_id': challengeId,
        'content': content.trim(),
        'challenge_title': challengeTitle,
        'problematique': problematique,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      debugPrint('========================================');
      debugPrint('[NoteService] 🆕 CREATING NEW NOTE');
      debugPrint('  User ID: $_currentUserId');
      debugPrint('  Challenge ID: ${challengeId ?? "AUCUN (note indépendante)"}');
      debugPrint('  Content: ${content.trim()}');
      debugPrint('  Content length: ${content.trim().length} chars');
      debugPrint('========================================');

      final response = await _supabase
          .from('notes')
          .insert(noteData)
          .select()
          .single();

      debugPrint('✅ [NoteService] Note created with ID: ${response['id']}');
      debugPrint('========================================');
      
      return Note.fromJson(response);
    } catch (e) {
      debugPrint('[NoteService] ❌ Error creating note: $e');
      return null;
    }
  }

  // Update an existing note
  Future<Note?> updateNote({
    required String noteId,
    required String content,
    String? problematique,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      if (content.trim().isEmpty) {
        throw Exception('Note content cannot be empty');
      }

      final updateData = {
        'content': content.trim(),
        'problematique': problematique,
        'updated_at': DateTime.now().toIso8601String(),
      };

      debugPrint('[NoteService] Updating note $noteId');

      final response = await _supabase
          .from('notes')
          .update(updateData)
          .eq('id', noteId)
          .eq('user_id', _currentUserId!)
          .select()
          .single();

      debugPrint('[NoteService] ✅ Note updated successfully');
      return Note.fromJson(response);
    } catch (e) {
      debugPrint('[NoteService] ❌ Error updating note: $e');
      return null;
    }
  }

  // Delete a note
  Future<bool> deleteNote(String noteId) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('[NoteService] Deleting note $noteId');

      await _supabase
          .from('notes')
          .delete()
          .eq('id', noteId)
          .eq('user_id', _currentUserId!);

      debugPrint('[NoteService] ✅ Note deleted successfully');
      return true;
    } catch (e) {
      debugPrint('[NoteService] ❌ Error deleting note: $e');
      return false;
    }
  }

  // Get all notes for current user
  Future<List<Note>> getAllNotes() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('========================================');
      debugPrint('[NoteService] 📥 FETCHING ALL NOTES');
      debugPrint('  User ID: $_currentUserId');

      final response = await _supabase
          .from('notes')
          .select()
          .eq('user_id', _currentUserId!)
          .order('created_at', ascending: false);

      final notes = (response as List)
          .map((json) => Note.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ [NoteService] Fetched ${notes.length} notes');
      for (var i = 0; i < notes.length; i++) {
        debugPrint('  Note ${i + 1}: "${notes[i].content.substring(0, notes[i].content.length > 30 ? 30 : notes[i].content.length)}..." (ID: ${notes[i].id})');
      }
      debugPrint('========================================');
      
      return notes;
    } catch (e) {
      debugPrint('[NoteService] ❌ Error fetching notes: $e');
      return [];
    }
  }

  // Get note for specific challenge
  Future<Note?> getNoteForChallenge(String challengeId) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('[NoteService] Fetching note for challenge $challengeId');

      final response = await _supabase
          .from('notes')
          .select()
          .eq('user_id', _currentUserId!)
          .eq('challenge_id', challengeId)
          .maybeSingle();

      if (response == null) {
        debugPrint('[NoteService] No note found for challenge');
        return null;
      }

      debugPrint('[NoteService] ✅ Note found for challenge');
      return Note.fromJson(response);
    } catch (e) {
      debugPrint('[NoteService] ❌ Error fetching note for challenge: $e');
      return null;
    }
  }

  // Get notes filtered by date
  Future<List<Note>> getNotesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('[NoteService] Fetching notes from $startDate to $endDate');

      final response = await _supabase
          .from('notes')
          .select()
          .eq('user_id', _currentUserId!)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);

      final notes = (response as List)
          .map((json) => Note.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('[NoteService] ✅ Fetched ${notes.length} notes');
      return notes;
    } catch (e) {
      debugPrint('[NoteService] ❌ Error fetching notes by date range: $e');
      return [];
    }
  }

  // Search notes by content
  Future<List<Note>> searchNotes(String query) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      if (query.trim().isEmpty) {
        return getAllNotes();
      }

      debugPrint('[NoteService] Searching notes with query: $query');

      final response = await _supabase
          .from('notes')
          .select()
          .eq('user_id', _currentUserId!)
          .ilike('content', '%${query.trim()}%')
          .order('created_at', ascending: false);

      final notes = (response as List)
          .map((json) => Note.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('[NoteService] ✅ Found ${notes.length} notes');
      return notes;
    } catch (e) {
      debugPrint('[NoteService] ❌ Error searching notes: $e');
      return [];
    }
  }
}
