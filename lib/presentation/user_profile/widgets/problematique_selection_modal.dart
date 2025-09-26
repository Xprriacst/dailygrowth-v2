import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/challenge_problematique.dart';

class ProblematiqueSelectionModal extends StatefulWidget {
  final String? selectedProblematique;
  final Function(String) onProblematiqueChanged;

  const ProblematiqueSelectionModal({
    Key? key,
    required this.selectedProblematique,
    required this.onProblematiqueChanged,
  }) : super(key: key);

  @override
  State<ProblematiqueSelectionModal> createState() => _ProblematiqueSelectionModalState();
}

class _ProblematiqueSelectionModalState extends State<ProblematiqueSelectionModal> {
  String? _selectedProblematique;

  @override
  void initState() {
    super.initState();
    _selectedProblematique = widget.selectedProblematique;
  }

  // Mapping des catégories vers des icônes (gardé pour compatibilité mais on utilisera les emojis)
  String getCategoryIcon(String category) {
    switch (category) {
      case 'Mental & émotionnel':
        return 'psychology';
      case 'Relations & communication':
        return 'people';
      case 'Argent & carrière':
        return 'work';
      case 'Santé & habitudes de vie':
        return 'favorite';
      case 'Productivité & concentration':
        return 'schedule';
      case 'Confiance & identité':
        return 'self_improvement';
      default:
        return 'star';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 3.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Votre objectif',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  if (_selectedProblematique != null) {
                    widget.onProblematiqueChanged(_selectedProblematique!);
                  }
                  Navigator.pop(context);
                },
                child: Text(
                  'Terminé',
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Sélectionnez la problématique sur laquelle vous souhaitez travailler pour recevoir des défis personnalisés.',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Expanded(
            child: ListView.builder(
              itemCount: ChallengeProblematique.allCategories.length,
              itemBuilder: (context, categoryIndex) {
                final category = ChallengeProblematique.allCategories[categoryIndex];
                final problematiques = ChallengeProblematique.getByCategory(category);
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête de catégorie
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                      margin: EdgeInsets.only(bottom: 2.h, top: categoryIndex > 0 ? 3.h : 0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1),
                            AppTheme.lightTheme.colorScheme.primary.withOpacity(0.05),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                      ),
                    ),
                    
                    // Liste des problématiques de cette catégorie
                    ...problematiques.map((problematique) {
                      final isSelected = _selectedProblematique == problematique.description;
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: 2.h),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedProblematique = problematique.description;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.lightTheme.colorScheme.primary
                                      .withOpacity(0.1)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.lightTheme.colorScheme.primary
                                    : AppTheme.lightTheme.colorScheme.outline
                                        .withOpacity(0.3),
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 12.w,
                                  height: 12.w,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1)
                                        : AppTheme
                                            .lightTheme.colorScheme.onSurfaceVariant
                                            .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      problematique.emoji,
                                      style: TextStyle(
                                        fontSize: 20.sp,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Text(
                                    problematique.title,
                                    style: AppTheme.lightTheme.textTheme.bodyLarge
                                        ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? AppTheme.lightTheme.colorScheme.primary
                                          : AppTheme.lightTheme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: AppTheme.lightTheme.colorScheme.primary,
                                    size: 6.w,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
