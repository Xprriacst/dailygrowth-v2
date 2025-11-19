import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_export.dart';
import '../../models/note.dart';
import '../../services/note_service.dart';
import '../../services/user_service.dart';
import '../home_dashboard/widgets/bottom_navigation_widget.dart';
import 'note_edit_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NoteService _noteService = NoteService();
  final UserService _userService = UserService();
  List<Note> _notes = [];
  Map<String, Map<String, dynamic>> _progressByProblematique = {};
  String? _currentProblematique;
  bool _isLoading = true;
  int _currentBottomNavIndex = 1; // Index for Notes tab

  @override
  void initState() {
    super.initState();
    _initializeAndLoadNotes();
  }

  Future<void> _initializeAndLoadNotes() async {
    await _noteService.initialize();
    await _userService.initialize();
    await _loadCurrentProblematique();
    await _loadNotes();
    await _loadProgress();
  }

  Future<void> _loadCurrentProblematique() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ [NotesScreen] User not authenticated');
        return;
      }

      final problematique = await _userService.getCurrentProblematique(userId);
      
      if (mounted) {
        setState(() {
          _currentProblematique = problematique;
        });
      }
      
      debugPrint('✅ [NotesScreen] Current problematique loaded: $_currentProblematique');
    } catch (e) {
      debugPrint('❌ [NotesScreen] Error loading current problematique: $e');
    }
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

  Future<void> _loadProgress() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ [NotesScreen] User not authenticated');
        return;
      }

      final progressData = await _userService.getProgressByProblematique(userId);
      
      if (mounted) {
        setState(() {
          _progressByProblematique = progressData;
        });
      }
      
      debugPrint('✅ [NotesScreen] Progress loaded: $_progressByProblematique');
    } catch (e) {
      debugPrint('❌ [NotesScreen] Error loading progress: $e');
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
      backgroundColor: Color(0xFFF5F5F5), // Gris clair Google Keep
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        title: Text(
          'Notes',
          style: TextStyle(
            color: Color(0xFF202124),
            fontWeight: FontWeight.w600,
            fontSize: 20.sp,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: Color(0xFF5F6368),
              size: 24,
            ),
            onPressed: () async {
              await _loadCurrentProblematique();
              await _loadNotes();
              await _loadProgress();
            },
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
                  onRefresh: () async {
                    await _loadCurrentProblematique();
                    await _loadNotes();
                    await _loadProgress();
                  },
                  child: GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 2.w,
                      mainAxisSpacing: 2.w,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      return _buildNoteCard(note);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoteEditor(),
        backgroundColor: Colors.white,
        elevation: 4,
        child: Icon(
          Icons.add,
          color: Color(0xFF202124),
          size: 28,
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

    // Format date style Google Keep - utiliser la date de création
    final now = DateTime.now();
    final difference = now.difference(note.createdAt);
    String formattedDate;

    if (difference.inDays == 0) {
      formattedDate = '${note.createdAt.hour.toString().padLeft(2, '0')}:${note.createdAt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      formattedDate = '${difference.inDays}j';
    } else {
      formattedDate = '${note.createdAt.day}/${note.createdAt.month}';
    }

    return GestureDetector(
      onTap: () => _showNoteEditor(note: note),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge problématique discret en haut
            if (note.problematique != null) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getProblematiqueCouleur(note.problematique).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  note.problematique!,
                  style: TextStyle(
                    color: _getProblematiqueCouleur(note.problematique),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 2.w),
            ],
            
            // Contenu de la note
            Expanded(
              child: Text(
                note.content,
                style: TextStyle(
                  color: Color(0xFF202124),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                  letterSpacing: 0.2,
                ),
                maxLines: 10,
                overflow: TextOverflow.fade,
              ),
            ),
            
            SizedBox(height: 2.w),
            
            // Ligne du bas : date modifiée
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date modifiée
                Text(
                  'Modifié : $formattedDate',
                  style: TextStyle(
                    color: Color(0xFF5F6368),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                
                // Menu 3 points (discret)
                GestureDetector(
                  onTap: () => _showNoteMenu(note),
                  child: Icon(
                    Icons.more_vert,
                    color: Color(0xFF5F6368),
                    size: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNoteMenu(Note note) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red),
              title: Text('Supprimer'),
              onTap: () {
                Navigator.pop(context);
                _deleteNote(note.id!);
              },
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
          initialProblematique: note?.problematique ?? _currentProblematique,
        ),
      ),
    );

    // Reload notes and progress if saved
    if (result == true) {
      await _loadNotes();
      await _loadProgress();
      await _loadCurrentProblematique();
    }
  }
}
