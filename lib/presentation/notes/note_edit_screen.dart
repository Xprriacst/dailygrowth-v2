import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/note.dart';
import '../../models/challenge_problematique.dart';
import '../../services/note_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';

class NoteEditScreen extends StatefulWidget {
  final Note? note; // null si création, non-null si édition
  final String? initialProblematique; // Problématique pré-sélectionnée

  const NoteEditScreen({
    Key? key,
    this.note,
    this.initialProblematique,
  }) : super(key: key);

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  final _noteService = NoteService();
  final _userService = UserService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _contentController;

  String? _selectedProblematique;
  bool _isLoading = false;
  bool _isSaving = false;
  Map<String, dynamic>? _progressData;
  
  // Track original values to detect changes
  String? _originalContent;
  String? _originalProblematique;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _selectedProblematique = widget.note?.problematique ?? widget.initialProblematique;
    
    // Store original values to detect changes
    _originalContent = widget.note?.content ?? '';
    _originalProblematique = _selectedProblematique;

    if (_selectedProblematique != null) {
      _loadProgressData();
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadProgressData() async {
    if (_selectedProblematique == null) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final allProgress = await _userService.getProgressByProblematique(userId);
      if (mounted) {
        setState(() {
          _progressData = allProgress[_selectedProblematique];
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement de la progression: $e');
    }
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProblematique == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une problématique'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      if (widget.note == null) {
        // Création d'une nouvelle note
        await _noteService.createNote(
          content: _contentController.text.trim(),
          problematique: _selectedProblematique!,
        );
      } else {
        // Mise à jour d'une note existante
        await _noteService.updateNote(
          noteId: widget.note!.id!,
          content: _contentController.text.trim(),
          problematique: _selectedProblematique,
        );
      }

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.note == null
                ? '✅ Note sauvegardée avec succès !'
                : '✅ Note mise à jour avec succès !',
            ),
            backgroundColor: AppTheme.successLight,
          ),
        );
        Navigator.of(context).pop(true); // Retour avec succès
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
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Color _getProblematiqueCouleur(String? problematique) {
    if (problematique == null) return Colors.grey;
    
    // Couleurs par catégorie
    final prob = ChallengeProblematique.allProblematiques.firstWhere(
      (p) => p.title == problematique,
      orElse: () => ChallengeProblematique.allProblematiques.first,
    );
    
    switch (prob.category) {
      case 'Mental & émotionnel':
        return Colors.purple;
      case 'Relations & communication':
        return Colors.blue;
      case 'Argent & carrière':
        return Colors.green;
      case 'Santé & habitudes de vie':
        return Colors.red;
      case 'Productivité & concentration':
        return Colors.orange;
      case 'Confiance & identité':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  Widget _buildProblematiqueSelector() {
    // Trouver la problématique sélectionnée
    final problematique = ChallengeProblematique.allProblematiques.firstWhere(
      (p) => p.title == _selectedProblematique,
      orElse: () => ChallengeProblematique(
        id: 'custom',
        title: _selectedProblematique ?? 'Problématique',
        category: 'Mental & émotionnel',
        description: _selectedProblematique ?? '',
        emoji: '🎯',
      ),
    );
    
    final couleur = _getProblematiqueCouleur(_selectedProblematique);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.dividerLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Problématique',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.5.h),
          // Badge de problématique (statique, non modifiable)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              color: couleur.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: couleur.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Text(
                  problematique.emoji,
                  style: TextStyle(fontSize: 20.sp),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    problematique.title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: couleur,
                    ),
                  ),
                ),
                // Icône de verrouillage pour indiquer que c'est fixe
                Icon(
                  Icons.lock_outline,
                  size: 18.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ],
            ),
          ),
          // Afficher la progression si disponible
          if (_progressData != null) ...[
            SizedBox(height: 1.5.h),
            _buildProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    if (_progressData == null) return const SizedBox.shrink();

    final percentage = _progressData!['percentage'] as int;

    Color progressColor;
    if (percentage >= 80) {
      progressColor = Colors.green;
    } else if (percentage >= 50) {
      progressColor = AppTheme.primaryLight;
    } else if (percentage >= 25) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red.shade300;
    }

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: progressColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: progressColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Votre progression',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: progressColor,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Format date modification style Google Keep
    String modificationText = '';
    if (widget.note != null) {
      final now = DateTime.now();
      final diff = now.difference(widget.note!.updatedAt);
      if (diff.inDays == 0) {
        modificationText = 'Modification : aujourd’hui, ${widget.note!.updatedAt.hour.toString().padLeft(2, '0')}:${widget.note!.updatedAt.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        modificationText = 'Modification : hier, ${widget.note!.updatedAt.hour.toString().padLeft(2, '0')}:${widget.note!.updatedAt.minute.toString().padLeft(2, '0')}';
      } else {
        modificationText = 'Modification : ${widget.note!.updatedAt.day}/${widget.note!.updatedAt.month}/${widget.note!.updatedAt.year}';
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF202124)),
          onPressed: () {
            // Only navigate back, don't auto-save (user must click Sauvegarder)
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/notes');
            }
          },
        ),
        title: null, // Pas de titre dans Google Keep
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sélecteur de problématique (compact)
                    _buildProblematiqueSelector(),

                    SizedBox(height: 2.h),

                    // Champ Contenu (style Google Keep)
                    TextFormField(
                      controller: _contentController,
                      autofocus: widget.note == null,
                      decoration: InputDecoration(
                        hintText: 'Note',
                        hintStyle: TextStyle(
                          color: Color(0xFF5F6368),
                          fontSize: 16.sp,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Color(0xFF202124),
                        height: 1.5,
                      ),
                      maxLines: null,
                      minLines: 10,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez entrer du contenu';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Toolbar en bas style Google Keep
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              child: Row(
                children: [
                  // Timestamp de modification
                  if (modificationText.isNotEmpty)
                    Expanded(
                      child: Text(
                        modificationText,
                        style: TextStyle(
                          color: Color(0xFF5F6368),
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  if (modificationText.isEmpty)
                    Spacer(),
                  
                  // Bouton Sauvegarder
                  TextButton(
                    onPressed: _isSaving ? null : () async {
                      await _saveNote();
                      if (mounted) {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context).pushReplacementNamed('/notes');
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF1A73E8),
                              ),
                            ),
                          )
                        : Text(
                            'Sauvegarder',
                            style: TextStyle(
                              color: Color(0xFF1A73E8),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
