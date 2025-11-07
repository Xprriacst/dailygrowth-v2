import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../models/note.dart';
import '../../services/note_service.dart';
import '../home_dashboard/widgets/bottom_navigation_widget.dart';
import 'package:intl/intl.dart';
import 'note_edit_screen.dart';

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
    _initializeAndLoadNotes();
  }

  Future<void> _initializeAndLoadNotes() async {
    await _noteService.initialize();
    await _loadNotes();
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
      debugPrint('❌ [NotesScreen] Error loading notes: $e');
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

  Color _getProblematiqueCouleur(String? problematique) {
    if (problematique == null) return Colors.grey.shade400;
    
    // Couleurs inspirées de Google Keep
    final colors = {
      'lâcher-prise': Color(0xFF91D5FF), // Bleu clair
      'maîtriser': Color(0xFFB7EB8F), // Vert clair
      'revenus': Color(0xFFFFD666), // Jaune/Or
      'développement': Color(0xFFFF85C0), // Rose
      'charisme': Color(0xFFD3ADF7), // Violet
      'santé': Color(0xFF87E8DE), // Turquoise
    };
    
    // Recherche insensible à la casse
    final key = colors.keys.firstWhere(
      (k) => problematique.toLowerCase().contains(k.toLowerCase()),
      orElse: () => '',
    );
    
    return colors[key] ?? Colors.orange.shade300;
  }

  Widget _buildNoteCard(Note note) {
    debugPrint('🎨 Rendu carte: "${note.content}"');
    
    // Format simple sans locale pour éviter l'erreur
    final formattedDate = '${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}';

    return GestureDetector(
      onTap: () => _showNoteEditor(note: note),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.amber.shade50, // Fond crème visible temporaire
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge problématique
            if (note.problematique != null) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getProblematiqueCouleur(note.problematique),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  note.problematique!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 12),
            ],
            
            // Contenu de la note
            Text(
              note.content,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
            
            SizedBox(height: 12),
            
            // Ligne du bas : date + bouton supprimer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                
                // Bouton supprimer
                InkWell(
                  onTap: () => _deleteNote(note.id!),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red.shade600,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNoteEditor({Note? note}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditScreen(
          note: note,
        ),
      ),
    );

    // Reload notes if saved
    if (result == true) {
      await _loadNotes();
    }
  }
}
