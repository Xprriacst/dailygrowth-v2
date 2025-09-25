import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/challenge_problematique.dart';
import './problematique_card_widget.dart';

class ProblematiqueCategory extends StatelessWidget {
  final String title;
  final List<ChallengeProblematique> problematiques;
  final Function(ChallengeProblematique) onProblematiqueTap;

  const ProblematiqueCategory({
    Key? key,
    required this.title,
    required this.problematiques,
    required this.onProblematiqueTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de la catégorie
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
        ),

        SizedBox(height: 2.h),

        // Liste des problématiques
        Column(
          children: problematiques.map((problematique) {
            return Column(
              children: [
                ProblematiqueCard(
                  problematique: problematique,
                  onTap: () => onProblematiqueTap(problematique),
                ),
                SizedBox(height: 2.h),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
