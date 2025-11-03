import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note.dart';

/// Service for managing user notes with Google Keep-style functionality
/// 
/// Handles CRUD operations for notes stored in Supabase
class NoteService {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isInitialized = false;

  /// Initialize the note service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('📝 NoteService: Initializing...');
      _isInitialized = true;
      debugPrint('✅ NoteService: Initialized successfully');
    } catch (e) {
      debugPrint('❌ NoteService: Initialization failed: $e');
      rethrow;
    }
  }

  /// Get all notes for a user, sorted by pinned status and creation date
  Future<List<Note>> getAllNotes(String userId) async {
    try {
      debugPrint('📝 NoteService: Fetching all notes for user $userId');
      
      final response = await _supabase
          .from('notes')
          .select()
          .eq('user_id', userId)
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false);

      final notes = (response as List)
          .map((json) => Note.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ NoteService: Fetched ${notes.length} notes');
      return notes;
    } catch (e) {
      debugPrint('❌ NoteService: Failed to fetch notes: $e');
      rethrow;
    }
  }

  /// Get a single note by ID
  Future<Note?> getNote(String noteId) async {
    try {
      debugPrint('📝 NoteService: Fetching note $noteId');
      
      final response = await _supabase
          .from('notes')
          .select()
          .eq('id', noteId)
          .single();

      final note = Note.fromJson(response as Map<String, dynamic>);
      debugPrint('✅ NoteService: Fetched note: ${note.title}');
      return note;
    } catch (e) {
      debugPrint('❌ NoteService: Failed to fetch note: $e');
      return null;
    }
  }

  /// Create a new note
  Future<Note> createNote({
    required String userId,
    String? title,
    required String content,
    String color = 'default',
    bool isPinned = false,
  }) async {
    try {
      debugPrint('📝 NoteService: Creating new note');
      
      final now = DateTime.now();
      final noteData = {
        'user_id': userId,
        'title': title,
        'content': content,
        'color': color,
        'is_pinned': isPinned,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('notes')
          .insert(noteData)
          .select()
          .single();

      final note = Note.fromJson(response as Map<String, dynamic>);
      debugPrint('✅ NoteService: Note created: ${note.id}');
      return note;
    } catch (e) {
      debugPrint('❌ NoteService: Failed to create note: $e');
      rethrow;
    }
  }

  /// Update an existing note
  Future<Note> updateNote({
    required String noteId,
    String? title,
    String? content,
    String? color,
    bool? isPinned,
  }) async {
    try {
      debugPrint('📝 NoteService: Updating note $noteId');
      
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (content != null) updateData['content'] = content;
      if (color != null) updateData['color'] = color;
      if (isPinned != null) updateData['is_pinned'] = isPinned;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('notes')
          .update(updateData)
          .eq('id', noteId)
          .select()
          .single();

      final note = Note.fromJson(response as Map<String, dynamic>);
      debugPrint('✅ NoteService: Note updated: ${note.id}');
      return note;
    } catch (e) {
      debugPrint('❌ NoteService: Failed to update note: $e');
      rethrow;
    }
  }

  /// Toggle the pinned status of a note
  Future<Note> togglePin(String noteId, bool currentPinnedStatus) async {
    try {
      debugPrint('📝 NoteService: Toggling pin for note $noteId');
      
      return await updateNote(
        noteId: noteId,
        isPinned: !currentPinnedStatus,
      );
    } catch (e) {
      debugPrint('❌ NoteService: Failed to toggle pin: $e');
      rethrow;
    }
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    try {
      debugPrint('📝 NoteService: Deleting note $noteId');
      
      await _supabase
          .from('notes')
          .delete()
          .eq('id', noteId);

      debugPrint('✅ NoteService: Note deleted: $noteId');
    } catch (e) {
      debugPrint('❌ NoteService: Failed to delete note: $e');
      rethrow;
    }
  }

  /// Search notes by title or content
  Future<List<Note>> searchNotes(String userId, String query) async {
    try {
      debugPrint('📝 NoteService: Searching notes for: "$query"');
      
      final response = await _supabase
          .from('notes')
          .select()
          .eq('user_id', userId)
          .or('title.ilike.%$query%,content.ilike.%$query%')
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false);

      final notes = (response as List)
          .map((json) => Note.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ NoteService: Found ${notes.length} notes');
      return notes;
    } catch (e) {
      debugPrint('❌ NoteService: Failed to search notes: $e');
      rethrow;
    }
  }

  /// Get pinned notes only
  Future<List<Note>> getPinnedNotes(String userId) async {
    try {
      debugPrint('📝 NoteService: Fetching pinned notes');
      
      final response = await _supabase
          .from('notes')
          .select()
          .eq('user_id', userId)
          .eq('is_pinned', true)
          .order('created_at', ascending: false);

      final notes = (response as List)
          .map((json) => Note.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ NoteService: Fetched ${notes.length} pinned notes');
      return notes;
    } catch (e) {
      debugPrint('❌ NoteService: Failed to fetch pinned notes: $e');
      rethrow;
    }
  }

  /// Get notes count for a user
  Future<int> getNotesCount(String userId) async {
    try {
      final response = await _supabase
          .from('notes')
          .select('id')
          .eq('user_id', userId);

      return (response as List).length;
    } catch (e) {
      debugPrint('❌ NoteService: Failed to count notes: $e');
      return 0;
    }
  }
}
