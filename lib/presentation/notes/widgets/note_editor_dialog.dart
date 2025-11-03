import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../models/note.dart';
import '../../../services/note_service.dart';
import '../../../theme/app_theme.dart';

/// Google Keep-style note editor dialog
class NoteEditorDialog extends StatefulWidget {
  final String userId;
  final Note? existingNote;

  const NoteEditorDialog({
    Key? key,
    required this.userId,
    this.existingNote,
  }) : super(key: key);

  @override
  State<NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<NoteEditorDialog> {
  final NoteService _noteService = NoteService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  
  String _selectedColor = 'default';
  bool _isPinned = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingNote != null) {
      _titleController.text = widget.existingNote!.title ?? '';
      _contentController.text = widget.existingNote!.content;
      _selectedColor = widget.existingNote!.color;
      _isPinned = widget.existingNote!.isPinned;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Color _getNoteColor(String colorName) {
    switch (colorName) {
      case 'red':
        return const Color(0xFFF28B82);
      case 'orange':
        return const Color(0xFFFBBC04);
      case 'yellow':
        return const Color(0xFFFFF475);
      case 'green':
        return const Color(0xFFCCFF90);
      case 'blue':
        return const Color(0xFFA7FFEB);
      case 'purple':
        return const Color(0xFFD7AEFB);
      case 'pink':
        return const Color(0xFFFDCFE8);
      case 'gray':
        return const Color(0xFFE8EAED);
      default:
        return Colors.white;
    }
  }

  Future<void> _saveNote() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le contenu ne peut pas être vide')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      Note result;
      
      if (widget.existingNote != null) {
        // Update existing note
        result = await _noteService.updateNote(
          noteId: widget.existingNote!.id,
          title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
          content: _contentController.text.trim(),
          color: _selectedColor,
          isPinned: _isPinned,
        );
      } else {
        // Create new note
        result = await _noteService.createNote(
          userId: widget.userId,
          title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
          content: _contentController.text.trim(),
          color: _selectedColor,
          isPinned: _isPinned,
        );
      }

      if (mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      debugPrint('❌ Failed to save note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'enregistrement')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(4.w),
      child: Container(
        constraints: BoxConstraints(maxHeight: 80.h),
        decoration: BoxDecoration(
          color: _getNoteColor(_selectedColor),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close and save buttons
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 2.w, 2.w, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: Colors.black87,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                    color: Colors.black87,
                    onPressed: () => setState(() => _isPinned = !_isPinned),
                  ),
                  if (_isSaving)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: SizedBox(
                        width: 5.w,
                        height: 5.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                      ),
                    )
                  else
                    TextButton(
                      onPressed: _saveNote,
                      child: Text(
                        'Enregistrer',
                        style: TextStyle(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Title input
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Titre',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.black54),
                ),
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
              ),
            ),

            SizedBox(height: 1.h),

            // Content input
            Flexible(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    hintText: 'Note',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.black54),
                  ),
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  maxLines: null,
                  autofocus: widget.existingNote == null,
                ),
              ),
            ),

            SizedBox(height: 2.h),

            // Color picker
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: NoteColor.values.map((noteColor) {
                    final isSelected = _selectedColor == noteColor.value;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = noteColor.value),
                      child: Container(
                        width: 10.w,
                        height: 10.w,
                        margin: EdgeInsets.only(right: 2.w),
                        decoration: BoxDecoration(
                          color: _getNoteColor(noteColor.value),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.lightTheme.colorScheme.primary
                                : Colors.black26,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: AppTheme.lightTheme.colorScheme.primary,
                                size: 5.w,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
