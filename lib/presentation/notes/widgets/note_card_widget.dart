import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../models/note.dart';
import '../../../theme/app_theme.dart';

/// Google Keep-style note card widget
class NoteCardWidget extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;

  const NoteCardWidget({
    Key? key,
    required this.note,
    required this.onTap,
    required this.onDelete,
    required this.onTogglePin,
  }) : super(key: key);

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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'À l\'instant';
        }
        return 'Il y a ${difference.inMinutes} min';
      }
      return 'Il y a ${difference.inHours}h';
    }
    if (difference.inDays == 1) return 'Hier';
    if (difference.inDays < 7) return 'Il y a ${difference.inDays}j';
    if (difference.inDays < 30) return 'Il y a ${(difference.inDays / 7).floor()} sem';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final noteColor = _getNoteColor(note.color);
    final hasTitle = note.title != null && note.title!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
        decoration: BoxDecoration(
          color: noteColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and pin icon
            if (hasTitle || note.isPinned)
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 3.w, 2.w, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasTitle)
                      Expanded(
                        child: Text(
                          note.title!,
                          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (note.isPinned)
                      Icon(
                        Icons.push_pin,
                        size: 4.w,
                        color: Colors.black54,
                      ),
                  ],
                ),
              ),

            // Content
            Padding(
              padding: EdgeInsets.fromLTRB(
                4.w,
                hasTitle ? 1.h : 3.w,
                4.w,
                2.h,
              ),
              child: Text(
                note.content,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                  height: 1.4,
                ),
                maxLines: 10,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Footer with date and actions
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 0, 2.w, 2.w),
              child: Row(
                children: [
                  // Last edited date
                  Expanded(
                    child: Text(
                      _formatDate(note.updatedAt),
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  
                  // Pin button
                  IconButton(
                    icon: Icon(
                      note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 4.5.w,
                    ),
                    color: Colors.black54,
                    onPressed: onTogglePin,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.all(1.w),
                    constraints: const BoxConstraints(),
                  ),
                  
                  // Delete button
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 4.5.w),
                    color: Colors.black54,
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.all(1.w),
                    constraints: const BoxConstraints(),
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
