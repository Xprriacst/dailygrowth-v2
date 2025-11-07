import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../models/note.dart';
import '../../services/note_service.dart';
import '../home_dashboard/widgets/bottom_navigation_widget.dart';
import 'package:intl/intl.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NoteService _noteService = NoteService();
  List<Note> _notes = [];
  bool _isLoading = true;
  int _currentBottomNavIndex = 1; // Index for Notes tab

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);

    try {
      final notes = await _noteService.getAllNotes();
      if (mounted) {
        setState(() {
          _notes = notes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notes: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteNote(String noteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer la note'),
        content: Text('Êtes-vous sûr de vouloir supprimer cette note ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _noteService.deleteNote(noteId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note supprimée'),
            backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
          ),
        );
        _loadNotes();
      }
    }
  }

  void _handleBottomNavigation(int index) {
    if (index == _currentBottomNavIndex) return;

    setState(() => _currentBottomNavIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.homeDashboard);
        break;
      case 1:
        // Already on Notes screen
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.challengeHistory);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, AppRoutes.userProfile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Mes Notes',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'refresh',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 6.w,
            ),
            onPressed: _loadNotes,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            )
          : _notes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'note_add',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                            .withOpacity(0.3),
                        size: 20.w,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Aucune note pour le moment',
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                              .withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Commencez à prendre des notes\nsur vos défis quotidiens',
                        textAlign: TextAlign.center,
                        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                              .withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotes,
                  child: GridView.builder(
                    padding: EdgeInsets.all(4.w),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 3.w,
                      mainAxisSpacing: 2.h,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      return _buildNoteCard(note);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNoteEditor(),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        icon: CustomIconWidget(
          iconName: 'add',
          color: Colors.white,
          size: 6.w,
        ),
        label: Text(
          'Nouvelle note',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationWidget(
        currentIndex: _currentBottomNavIndex,
        onTap: _handleBottomNavigation,
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    final dateFormat = DateFormat('d MMM yyyy', 'fr_FR');
    final formattedDate = dateFormat.format(note.createdAt);

    return GestureDetector(
      onTap: () => _showNoteEditor(note: note),
      child: Container(
        decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with challenge title if available
          if (note.challengeTitle != null) ...[
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'emoji_events',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 4.w,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      note.challengeTitle!,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Note content
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      note.content,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                        height: 1.4,
                      ),
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formattedDate,
                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                                .withOpacity(0.6),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _deleteNote(note.id!),
                        child: Padding(
                          padding: EdgeInsets.all(2.w),
                          child: CustomIconWidget(
                            iconName: 'delete',
                            color: Colors.red.shade400,
                            size: 4.w,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _showNoteEditor({Note? note}) async {
    final isEditing = note != null;
    final TextEditingController contentController = TextEditingController(
      text: note?.content ?? '',
    );

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: 80.h,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: CustomIconWidget(
                        iconName: 'close',
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                        size: 6.w,
                      ),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    Expanded(
                      child: Text(
                        isEditing ? 'Modifier la note' : 'Nouvelle note',
                        style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (contentController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('La note ne peut pas être vide'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        bool success = false;
                        if (isEditing) {
                          final updatedNote = await _noteService.updateNote(
                            noteId: note.id!,
                            content: contentController.text.trim(),
                          );
                          success = updatedNote != null;
                        } else {
                          final newNote = await _noteService.createNote(
                            content: contentController.text.trim(),
                          );
                          success = newNote != null;
                        }

                        if (success) {
                          Navigator.pop(context, true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur lors de la sauvegarde'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Sauvegarder',
                        style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content editor
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: TextField(
                    controller: contentController,
                    maxLines: null,
                    expands: true,
                    autofocus: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: AppTheme.lightTheme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Écrivez votre note ici...',
                      hintStyle: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Reload notes if saved
    if (result == true) {
      await _loadNotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Note mise à jour' : 'Note créée'),
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          ),
        );
      }
    }
  }
}
