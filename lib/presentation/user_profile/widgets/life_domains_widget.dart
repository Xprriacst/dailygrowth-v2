import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import '../../../models/challenge_problematique.dart';

class LifeDomainsWidget extends StatelessWidget {
  final List<String> selectedDomains;
  final VoidCallback onEditTap;

  const LifeDomainsWidget({
    Key? key,
    required this.selectedDomains,
    required this.onEditTap,
  }) : super(key: key);

  // Fonction pour récupérer l'emoji et le titre d'une problématique
  Map<String, String> _getProblematiqueInfo(String description) {
    // Chercher la problématique correspondante dans la liste
    final problematique = ChallengeProblematique.allProblematiques
        .where((p) => p.description == description)
        .firstOrNull;
    
    if (problematique != null) {
      return {
        'emoji': problematique.emoji,
        'title': problematique.title,
      };
    }
    
    // Fallback si la problématique n'est pas trouvée
    return {
      'emoji': '🎯',
      'title': description,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Objectifs sélectionnés',
                    style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Tooltip(
                    message: 'Un changement de problématique sera effectif 24h après la modification dans la plateforme',
                    padding: EdgeInsets.all(3.w),
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      size: 18.sp,
                      color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onEditTap,
                child: Text(
                  'Modifier',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Column(
            children: selectedDomains.map((domain) {
              final problematiqueInfo = _getProblematiqueInfo(domain);
              
              return Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 2.h),
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.5.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Emoji avec animation
                    Container(
                      padding: EdgeInsets.all(1.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        problematiqueInfo['emoji']!,
                        style: TextStyle(
                          fontSize: 20.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    
                    // Titre
                    Expanded(
                      child: Text(
                        problematiqueInfo['title']!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightTheme.colorScheme.primary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Icône de sélection
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 20.sp,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
