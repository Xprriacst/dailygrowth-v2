import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../models/note.dart';
import '../../services/note_service.dart';
import '../../utils/auth_guard.dart';
import '../home_dashboard/widgets/bottom_navigation_widget.dart';
import './widgets/note_card_widget.dart';
import './widgets/note_editor_dialog.dart';

/// Google Keep-style notes screen
class NotesScreen extends StatefulWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NoteService _noteService = NoteService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _checkAuthenticationAndInitialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthenticationAndInitialize() async {
    final canProceed = await AuthGuard.canNavigate(context, '/notes');
    if (!canProceed) return;
    
    await _initialize();
  }

  Future<void> _initialize() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      _userId = user.id;
      await _noteService.initialize();
      await _loadNotes();
    } catch (e) {
      debugPrint('❌ Failed to initialize notes screen: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNotes() async {
    try {
      setState(() => _isLoading = true);
      
      final notes = await _noteService.getAllNotes(_userId);
      
      setState(() {
        _notes = notes;
        _filteredNotes = notes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Failed to load notes: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterNotes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredNotes = _notes;
        _isSearching = false;
      } else {
        _isSearching = true;
        _filteredNotes = _notes.where((note) {
          final titleMatch = note.title?.toLowerCase().contains(query.toLowerCase()) ?? false;
          final contentMatch = note.content.toLowerCase().contains(query.toLowerCase());
          return titleMatch || contentMatch;
        }).toList();
      }
    });
  }

  Future<void> _createNote() async {
    final result = await showDialog<Note>(
      context: context,
      builder: (context) => NoteEditorDialog(userId: _userId),
    );

    if (result != null) {
      await _loadNotes();
      _showNotification('Note créée ! 📝', isSuccess: true);
    }
  }

  Future<void> _editNote(Note note) async {
    final result = await showDialog<Note>(
      context: context,
      builder: (context) => NoteEditorDialog(
        userId: _userId,
        existingNote: note,
      ),
    );

    if (result != null) {
      await _loadNotes();
      _showNotification('Note modifiée ! ✏️', isSuccess: true);
    }
  }

  Future<void> _deleteNote(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la note'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette note ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _noteService.deleteNote(note.id);
        await _loadNotes();
        _showNotification('Note supprimée', isSuccess: false);
      } catch (e) {
        _showNotification('Erreur lors de la suppression', isSuccess: false);
      }
    }
  }

  Future<void> _togglePin(Note note) async {
    try {
      await _noteService.togglePin(note.id, note.isPinned);
      await _loadNotes();
      HapticFeedback.lightImpact();
    } catch (e) {
      _showNotification('Erreur lors de l\'épinglage', isSuccess: false);
    }
  }

  void _showNotification(String message, {required bool isSuccess}) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 4.w,
        right: 4.w,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              color: isSuccess 
                ? AppTheme.lightTheme.colorScheme.primaryContainer
                : AppTheme.lightTheme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess 
                    ? AppTheme.lightTheme.colorScheme.onPrimaryContainer
                    : AppTheme.lightTheme.colorScheme.onErrorContainer,
                  size: 5.w,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    message,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: isSuccess 
                        ? AppTheme.lightTheme.colorScheme.onPrimaryContainer
                        : AppTheme.lightTheme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Timer(const Duration(seconds: 2), () => overlayEntry.remove());
  }

  @override
  Widget build(BuildContext context) {
    return AuthGuard.protectedRoute(
      context: context,
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // Header with search
              _buildHeader(),
              
              // Notes list
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                      )
                    : _filteredNotes.isEmpty
                        ? _buildEmptyState()
                        : _buildNotesList(),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _createNote,
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        bottomNavigationBar: BottomNavigationWidget(
          currentIndex: 1,
          onTap: _handleBottomNavTap,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Mes Notes',
            style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          
          // Search bar
          TextField(
            controller: _searchController,
            onChanged: _filterNotes,
            decoration: InputDecoration(
              hintText: 'Rechercher dans vos notes...',
              prefixIcon: Icon(
                Icons.search,
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              suffixIcon: _isSearching
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterNotes('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSearching ? Icons.search_off : Icons.note_add,
            size: 20.w,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          SizedBox(height: 2.h),
          Text(
            _isSearching ? 'Aucune note trouvée' : 'Aucune note',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            _isSearching
                ? 'Essayez une autre recherche'
                : 'Appuyez sur + pour créer votre première note',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    final pinnedNotes = _filteredNotes.where((note) => note.isPinned).toList();
    final unpinnedNotes = _filteredNotes.where((note) => !note.isPinned).toList();

    return RefreshIndicator(
      onRefresh: _loadNotes,
      color: AppTheme.lightTheme.colorScheme.primary,
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          // Pinned notes section
          if (pinnedNotes.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Text(
                'ÉPINGLÉES',
                style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...pinnedNotes.map((note) => NoteCardWidget(
              note: note,
              onTap: () => _editNote(note),
              onDelete: () => _deleteNote(note),
              onTogglePin: () => _togglePin(note),
            )),
            SizedBox(height: 3.h),
          ],
          
          // Other notes section
          if (unpinnedNotes.isNotEmpty) ...[
            if (pinnedNotes.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: Text(
                  'AUTRES',
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ...unpinnedNotes.map((note) => NoteCardWidget(
              note: note,
              onTap: () => _editNote(note),
              onDelete: () => _deleteNote(note),
              onTogglePin: () => _togglePin(note),
            )),
          ],
          
          SizedBox(height: 10.h), // Space for FAB
        ],
      ),
    );
  }

  void _handleBottomNavTap(int index) async {
    if (index == 1) return; // Already on notes screen
    
    final canNavigate = await AuthGuard.canNavigate(context, 'navigation');
    if (!canNavigate) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home-dashboard');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/user-profile');
        break;
    }
  }
}
