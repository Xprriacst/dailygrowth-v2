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

  // Mapping des catégories vers des icônes
  Map<String, String> getCategoryIcon(String category) {
    switch (category) {
      case 'Mental & émotionnel':
        return {'icon': 'psychology', 'name': 'Mental & émotionnel'};
      case 'Relations & communication':
        return {'icon': 'people', 'name': 'Relations & communication'};
      case 'Argent & carrière':
        return {'icon': 'work', 'name': 'Argent & carrière'};
      case 'Santé & habitudes de vie':
        return {'icon': 'favorite', 'name': 'Santé & habitudes de vie'};
      case 'Productivité & concentration':
        return {'icon': 'schedule', 'name': 'Productivité & concentration'};
      case 'Confiance & identité':
        return {'icon': 'self_improvement', 'name': 'Confiance & identité'};
      default:
        return {'icon': 'star', 'name': category};
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
                  .withValues(alpha: 0.3),
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
              itemCount: ChallengeProblematique.allProblematiques.length,
              itemBuilder: (context, index) {
                final problematique = ChallengeProblematique.allProblematiques[index];
                final isSelected = _selectedProblematique == problematique.description;
                final categoryInfo = getCategoryIcon(problematique.category);

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
                                .withValues(alpha: 0.1)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.lightTheme.colorScheme.outline
                                  .withValues(alpha: 0.3),
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
                                  ? AppTheme.lightTheme.colorScheme.primary
                                  : AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                problematique.emoji,
                                style: TextStyle(fontSize: 6.w),
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  problematique.title,
                                  style: AppTheme.lightTheme.textTheme.bodyLarge
                                      ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppTheme.lightTheme.colorScheme.primary
                                        : AppTheme.lightTheme.colorScheme.onSurface,
                                  ),
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  categoryInfo['name']!,
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            CustomIconWidget(
                              iconName: 'check_circle',
                              color: AppTheme.lightTheme.colorScheme.primary,
                              size: 6.w,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
