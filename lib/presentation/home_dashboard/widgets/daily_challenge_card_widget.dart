import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/note_service.dart';

class DailyChallengeCardWidget extends StatefulWidget {
  final String challengeTitle;
  final String challengeDescription;
  final bool isCompleted;
  final VoidCallback onToggleCompletion;
  final String? challengeId;

  const DailyChallengeCardWidget({
    Key? key,
    required this.challengeTitle,
    required this.challengeDescription,
    required this.isCompleted,
    required this.onToggleCompletion,
    this.challengeId,
  }) : super(key: key);

  @override
  State<DailyChallengeCardWidget> createState() =>
      _DailyChallengeCardWidgetState();
}

class _DailyChallengeCardWidgetState extends State<DailyChallengeCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final TextEditingController _noteController = TextEditingController();
  final NoteService _noteService = NoteService();
  bool _isLoadingNote = false;
  bool _isSavingNote = false;
  String? _currentNoteId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _loadNote();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    if (widget.challengeId == null) return;

    setState(() => _isLoadingNote = true);

    try {
      final note = await _noteService.getNoteForChallenge(widget.challengeId!);
      if (note != null && mounted) {
        setState(() {
          _noteController.text = note.content;
          _currentNoteId = note.id;
        });
      }
    } catch (e) {
      debugPrint('Error loading note: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingNote = false);
      }
    }
  }

  Future<void> _saveNote() async {
    if (widget.challengeId == null || _noteController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isSavingNote = true);

    try {
      if (_currentNoteId != null) {
        // Update existing note
        await _noteService.updateNote(
          noteId: _currentNoteId!,
          content: _noteController.text.trim(),
        );
      } else {
        // Create new note
        final note = await _noteService.createNote(
          content: _noteController.text.trim(),
          challengeId: widget.challengeId,
          challengeTitle: widget.challengeTitle,
        );
        if (note != null && mounted) {
          setState(() => _currentNoteId = note.id);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note enregistrée ✓'),
            duration: Duration(seconds: 1),
            backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingNote = false);
      }
    }
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onToggleCompletion();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            padding: EdgeInsets.all(5.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.lightTheme.colorScheme.surface,
                  AppTheme.lightTheme.colorScheme.surface
                      .withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.lightTheme.colorScheme.shadow
                      .withOpacity(0.1),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: widget.isCompleted
                    ? AppTheme.lightTheme.colorScheme.tertiary
                        .withOpacity(0.3)
                    : AppTheme.lightTheme.colorScheme.outline
                        .withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.lightTheme.colorScheme.primary
                            .withOpacity(0.1),
                      ),
                      child: CustomIconWidget(
                        iconName: 'emoji_events',
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 6.w,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        'Défi du jour',
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (widget.isCompleted)
                      CustomIconWidget(
                        iconName: 'check_circle',
                        color: AppTheme.lightTheme.colorScheme.tertiary,
                        size: 6.w,
                      ),
                  ],
                ),

                SizedBox(height: 3.h),

                // Challenge title
                Text(
                  widget.challengeTitle,
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),

                SizedBox(height: 2.h),

                // Challenge description
                Text(
                  widget.challengeDescription,
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),

                SizedBox(height: 4.h),

                // Completion button
                GestureDetector(
                  onTap: _handleTap,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 3.h),
                    decoration: BoxDecoration(
                      color: widget.isCompleted
                          ? AppTheme.lightTheme.colorScheme.tertiary
                          : AppTheme.lightTheme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isCompleted
                                  ? AppTheme.lightTheme.colorScheme.tertiary
                                  : AppTheme.lightTheme.colorScheme.primary)
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: widget.isCompleted
                              ? 'check'
                              : 'radio_button_unchecked',
                          color: Colors.white,
                          size: 5.w,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          widget.isCompleted
                              ? 'Défi accompli !'
                              : 'Marquer comme terminé',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 3.h),

                // Notes section
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surfaceVariant
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.outline
                          .withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'note',
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 4.w,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Mes notes',
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Spacer(),
                          if (_isSavingNote)
                            SizedBox(
                              width: 4.w,
                              height: 4.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.lightTheme.colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      TextField(
                        controller: _noteController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Écrivez vos réflexions ici...',
                          hintStyle: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant
                                .withOpacity(0.5),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppTheme.lightTheme.colorScheme.outline
                                  .withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppTheme.lightTheme.colorScheme.outline
                                  .withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.all(3.w),
                        ),
                        style: AppTheme.lightTheme.textTheme.bodyMedium,
                        onChanged: (value) {
                          // Auto-save after 1 second of inactivity
                          Future.delayed(Duration(seconds: 1), () {
                            if (_noteController.text == value) {
                              _saveNote();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
