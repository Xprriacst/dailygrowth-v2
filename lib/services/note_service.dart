import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import './supabase_service.dart';
import '../models/note.dart';

class NoteService {
  static final NoteService _instance = NoteService._internal();
  factory NoteService() => _instance;
  NoteService._internal();

  late final SupabaseClient _client;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      _client = await SupabaseService().client;
      _isInitialized = true;
    }
  }

  /// Créer une nouvelle note
  Future<Note> createNote({
    required String userId,
    required String title,
    required String content,
    required String problematique,
    List<String>? tags,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final noteData = {
        'user_id': userId,
        'title': title,
        'content': content,
        'problematique': problematique,
        'tags': tags ?? [],
      };

      final response = await _client
          .from('notes')
          .insert(noteData)
          .select()
          .single();

      debugPrint(' Note créée avec succès: ${response['id']}');
      return Note.fromJson(response);
    } catch (error) {
      debugPrint('L Erreur lors de la création de la note: $error');
      throw Exception('Erreur lors de la création de la note: $error');
    }
  }

  /// Mettre à jour une note existante
  Future<Note> updateNote({
    required String noteId,
    String? title,
    String? content,
    String? problematique,
    List<String>? tags,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (content != null) updateData['content'] = content;
      if (problematique != null) updateData['problematique'] = problematique;
      if (tags != null) updateData['tags'] = tags;

      if (updateData.isEmpty) {
        throw Exception('Aucune donnée à mettre à jour');
      }

      final response = await _client
          .from('notes')
          .update(updateData)
          .eq('id', noteId)
          .select()
          .single();

      debugPrint(' Note mise à jour avec succès: $noteId');
      return Note.fromJson(response);
    } catch (error) {
      debugPrint('L Erreur lors de la mise à jour de la note: $error');
      throw Exception('Erreur lors de la mise à jour de la note: $error');
    }
  }

  /// Supprimer une note
  Future<void> deleteNote(String noteId) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      await _client
          .from('notes')
          .delete()
          .eq('id', noteId);

      debugPrint(' Note supprimée avec succès: $noteId');
    } catch (error) {
      debugPrint('L Erreur lors de la suppression de la note: $error');
      throw Exception('Erreur lors de la suppression de la note: $error');
    }
  }

  /// Récupérer toutes les notes d'un utilisateur
  Future<List<Note>> getUserNotes(String userId) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final response = await _client
          .from('notes')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      final notes = (response as List)
          .map((json) => Note.fromJson(json))
          .toList();

      debugPrint(' ${notes.length} notes récupérées pour l\'utilisateur');
      return notes;
    } catch (error) {
      debugPrint('L Erreur lors de la récupération des notes: $error');
      throw Exception('Erreur lors de la récupération des notes: $error');
    }
  }

  /// Récupérer les notes d'un utilisateur pour une problématique spécifique
  Future<List<Note>> getUserNotesByProblematique({
    required String userId,
    required String problematique,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final response = await _client
          .from('notes')
          .select()
          .eq('user_id', userId)
          .eq('problematique', problematique)
          .order('updated_at', ascending: false);

      final notes = (response as List)
          .map((json) => Note.fromJson(json))
          .toList();

      debugPrint(' ${notes.length} notes récupérées pour la problématique: $problematique');
      return notes;
    } catch (error) {
      debugPrint('L Erreur lors de la récupération des notes par problématique: $error');
      throw Exception('Erreur lors de la récupération des notes: $error');
    }
  }

  /// Récupérer une note spécifique par ID
  Future<Note?> getNoteById(String noteId) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final response = await _client
          .from('notes')
          .select()
          .eq('id', noteId)
          .single();

      debugPrint(' Note récupérée: $noteId');
      return Note.fromJson(response);
    } catch (error) {
      debugPrint('L Erreur lors de la récupération de la note: $error');
      return null;
    }
  }

  /// Compter le nombre de notes par problématique pour un utilisateur
  Future<Map<String, int>> countNotesByProblematique(String userId) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final response = await _client
          .from('notes')
          .select('problematique')
          .eq('user_id', userId);

      final Map<String, int> counts = {};
      for (var item in response) {
        final problematique = item['problematique'] as String;
        counts[problematique] = (counts[problematique] ?? 0) + 1;
      }

      return counts;
    } catch (error) {
      debugPrint('L Erreur lors du comptage des notes: $error');
      return {};
    }
  }

  /// Rechercher des notes par titre ou contenu
  Future<List<Note>> searchNotes({
    required String userId,
    required String query,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Recherche dans le titre et le contenu
      final response = await _client
          .from('notes')
          .select()
          .eq('user_id', userId)
          .or('title.ilike.%$query%,content.ilike.%$query%')
          .order('updated_at', ascending: false);

      final notes = (response as List)
          .map((json) => Note.fromJson(json))
          .toList();

      debugPrint(' ${notes.length} notes trouvées pour la recherche: "$query"');
      return notes;
    } catch (error) {
      debugPrint('L Erreur lors de la recherche de notes: $error');
      throw Exception('Erreur lors de la recherche de notes: $error');
    }
  }
}
