import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/note.dart';
import '../../models/challenge_problematique.dart';
import '../../services/note_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import 'note_edit_screen.dart';
import 'widgets/note_card_widget.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({Key? key}) : super(key: key);

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final _noteService = NoteService();
  final _userService = UserService();

  List<Note> _notes = [];
  Map<String, Map<String, dynamic>> _progressData = {};
  bool _isLoading = true;
  String? _filterProblematique;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      // Charger les notes
      final notes = await _noteService.getUserNotes(userId);

      // Charger la progression pour toutes les problématiques
      final allProgress = await _userService.getProgressByProblematique(userId);

      if (mounted) {
        setState(() {
          _notes = notes;
          _progressData = allProgress;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des notes: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorLight,
          ),
        );
      }
    }
  }

  Future<void> _deleteNote(Note note) async {
    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la note'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${note.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorLight),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _noteService.deleteNote(note.id);
        _loadNotes(); // Recharger la liste
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Note supprimée'),
              backgroundColor: AppTheme.successLight,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erreur: $e'),
              backgroundColor: AppTheme.errorLight,
            ),
          );
        }
      }
    }
  }

  Future<void> _navigateToEdit({Note? note, String? problematique}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditScreen(
          note: note,
          initialProblematique: problematique,
        ),
      ),
    );

    if (result == true) {
      _loadNotes(); // Recharger si modification
    }
  }

  List<Note> get _filteredNotes {
    if (_filterProblematique == null) {
      return _notes;
    }
    return _notes.where((note) => note.problematique == _filterProblematique).toList();
  }

  Widget _buildFilterChips() {
    // Obtenir les problématiques uniques des notes
    final uniqueProblematiques = _notes.map((n) => n.problematique).toSet().toList();
    if (uniqueProblematiques.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 6.h,
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        children: [
          // Chip "Toutes"
          Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: FilterChip(
              label: const Text('Toutes'),
              selected: _filterProblematique == null,
              onSelected: (selected) {
                setState(() {
                  _filterProblematique = null;
                });
              },
              selectedColor: AppTheme.primaryLight.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryLight,
            ),
          ),
          // Chips pour chaque problématique
          ...uniqueProblematiques.map((prob) {
            final problematique = ChallengeProblematique.allProblematiques
                .firstWhere((p) => p.title == prob, orElse: () => ChallengeProblematique.allProblematiques.first);

            return Padding(
              padding: EdgeInsets.only(right: 2.w),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(problematique.emoji),
                    const SizedBox(width: 4),
                    Text(
                      prob.length > 25 ? '${prob.substring(0, 25)}...' : prob,
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ],
                ),
                selected: _filterProblematique == prob,
                onSelected: (selected) {
                  setState(() {
                    _filterProblematique = selected ? prob : null;
                  });
                },
                selectedColor: AppTheme.primaryLight.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryLight,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Mes Notes',
          style: TextStyle(
            color: AppTheme.textPrimaryLight,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryLight),
            onPressed: _loadNotes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filtres
                if (_notes.isNotEmpty) _buildFilterChips(),

                // Liste des notes
                Expanded(
                  child: _filteredNotes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.note_outlined,
                                size: 60.sp,
                                color: AppTheme.textSecondaryLight,
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                _filterProblematique == null
                                    ? 'Aucune note pour le moment'
                                    : 'Aucune note pour cette problématique',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppTheme.textSecondaryLight,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                'Appuyez sur + pour créer votre première note',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppTheme.textDisabledLight,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                          itemCount: _filteredNotes.length,
                          itemBuilder: (context, index) {
                            final note = _filteredNotes[index];
                            final progressInfo = _progressData[note.problematique];

                            return NoteCardWidget(
                              note: note,
                              progressInfo: progressInfo,
                              onTap: () => _navigateToEdit(note: note),
                              onDelete: () => _deleteNote(note),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEdit(),
        backgroundColor: AppTheme.primaryLight,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Nouvelle note',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
