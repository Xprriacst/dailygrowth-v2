import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../../models/note.dart';
import '../../../models/challenge_problematique.dart';
import '../../../theme/app_theme.dart';

class NoteCardWidget extends StatelessWidget {
  final Note note;
  final Map<String, dynamic>? progressInfo;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NoteCardWidget({
    Key? key,
    required this.note,
    this.progressInfo,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  Color _getProgressColor(int percentage) {
    if (percentage >= 80) {
      return Colors.green;
    } else if (percentage >= 50) {
      return AppTheme.primaryLight;
    } else if (percentage >= 25) {
      return Colors.orange;
    } else {
      return Colors.red.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final problematique = ChallengeProblematique.allProblematiques.firstWhere(
      (p) => p.title == note.problematique,
      orElse: () => ChallengeProblematique.allProblematiques.first,
    );

    final percentage = progressInfo?['percentage'] as int? ?? 0;
    final progressColor = _getProgressColor(percentage);

    final formattedDate = DateFormat('d MMM yyyy', 'fr_FR').format(note.updatedAt);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.dividerLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Problématique + Badge progression
                Row(
                  children: [
                    // Emoji + Problématique
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            problematique.emoji,
                            style: TextStyle(fontSize: 20.sp),
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              note.problematique,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badge de progression
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: progressColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 14.sp,
                            color: Colors.white,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            '$percentage%',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Menu de suppression
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: AppTheme.errorLight,
                        size: 20.sp,
                      ),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                SizedBox(height: 1.h),

                // Barre de progression
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 6,
                  ),
                ),

                SizedBox(height: 1.5.h),

                // Titre de la note
                Text(
                  note.title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                if (note.content.isNotEmpty) ...[
                  SizedBox(height: 1.h),
                  // Aperçu du contenu
                  Text(
                    note.content,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textSecondaryLight,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                SizedBox(height: 1.5.h),

                // Footer: Date de modification
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14.sp,
                      color: AppTheme.textDisabledLight,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'Modifié le $formattedDate',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.textDisabledLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
