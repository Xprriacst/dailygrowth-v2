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

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _selectedProblematique = widget.note?.problematique ?? widget.initialProblematique;

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

  Widget _buildProblematiqueSelector() {
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
          Row(
            children: [
              Text(
                'Problématique',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.errorLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          DropdownButtonFormField<String>(
            value: _selectedProblematique,
            decoration: InputDecoration(
              hintText: 'Sélectionnez une problématique',
              filled: true,
              fillColor: AppTheme.backgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 3.w,
                vertical: 1.5.h,
              ),
            ),
            items: ChallengeProblematique.allProblematiques.map((prob) {
              return DropdownMenuItem<String>(
                value: prob.title,
                child: Row(
                  children: [
                    Text(
                      prob.emoji,
                      style: TextStyle(fontSize: 18.sp),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        prob.title,
                        style: TextStyle(fontSize: 13.sp),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedProblematique = value;
                _progressData = null;
              });
              _loadProgressData();
            },
          ),
          // Afficher la progression si disponible
          if (_progressData != null) ...[
            SizedBox(height: 1.h),
            _buildProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    if (_progressData == null) return const SizedBox.shrink();

    final percentage = _progressData!['percentage'] as int;
    final completed = _progressData!['completed'] as int;
    final total = _progressData!['total'] as int;

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
          widget.note == null ? 'Nouvelle note' : 'Modifier la note',
          style: TextStyle(
            color: AppTheme.textPrimaryLight,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sélecteur de problématique
              _buildProblematiqueSelector(),

              SizedBox(height: 2.h),

              // Champ Contenu
              Container(
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
                      'Contenu',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    TextFormField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        hintText: 'Écrivez vos réflexions, idées, objectifs...',
                        filled: true,
                        fillColor: AppTheme.backgroundLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 1.5.h,
                        ),
                      ),
                      style: TextStyle(fontSize: 14.sp),
                      maxLines: 10,
                      minLines: 5,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez entrer du contenu pour votre note';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 3.h),

              // Bouton de sauvegarde
              GestureDetector(
                onTap: _isSaving ? null : _saveNote,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  decoration: BoxDecoration(
                    gradient: _isSaving
                        ? LinearGradient(
                            colors: [Colors.grey.shade400, Colors.grey.shade500],
                          )
                        : const LinearGradient(
                            colors: [AppTheme.primaryLight, AppTheme.primaryVariantLight],
                          ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _isSaving
                        ? []
                        : [
                            BoxShadow(
                              color: AppTheme.primaryLight.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Center(
                    child: _isSaving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.onPrimaryLight,
                              ),
                            ),
                          )
                        : Text(
                            widget.note == null ? '💾 Sauvegarder la note' : '💾 Mettre à jour la note',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onPrimaryLight,
                            ),
                          ),
                  ),
                ),
              ),

              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }
}
