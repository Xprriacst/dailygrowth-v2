import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/challenge_problematique.dart';

class LifeDomainsModal extends StatefulWidget {
  final List<String> selectedDomains;
  final Function(List<String>) onDomainsChanged;

  const LifeDomainsModal({
    Key? key,
    required this.selectedDomains,
    required this.onDomainsChanged,
  }) : super(key: key);

  @override
  State<LifeDomainsModal> createState() => _LifeDomainsModalState();
}

class _LifeDomainsModalState extends State<LifeDomainsModal> {
  late List<String> _selectedDomains;
  String? _expandedCategory;

  // Grouper les problématiques par catégorie
  Map<String, List<ChallengeProblematique>> get _problematiquesParCategorie {
    final map = <String, List<ChallengeProblematique>>{};
    for (final p in ChallengeProblematique.allProblematiques) {
      map.putIfAbsent(p.category, () => []).add(p);
    }
    return map;
  }

  @override
  void initState() {
    super.initState();
    _selectedDomains = List.from(widget.selectedDomains);
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
                'Domaines de vie',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  widget.onDomainsChanged(_selectedDomains);
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
            'Sélectionnez le domaine qui vous intéresse le plus pour recevoir des défis personnalisés.',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Expanded(
            child: ListView.builder(
              itemCount: _problematiquesParCategorie.keys.length,
              itemBuilder: (context, categoryIndex) {
                final category = _problematiquesParCategorie.keys.elementAt(categoryIndex);
                final problematiques = _problematiquesParCategorie[category]!;
                final isExpanded = _expandedCategory == category;
                
                // Vérifier si une problématique de cette catégorie est sélectionnée
                final hasSelectedInCategory = problematiques.any(
                  (p) => _selectedDomains.contains(p.description)
                );

                return Container(
                  margin: EdgeInsets.only(bottom: 1.5.h),
                  decoration: BoxDecoration(
                    color: hasSelectedInCategory
                        ? AppTheme.lightTheme.colorScheme.primary.withOpacity(0.05)
                        : Colors.transparent,
                    border: Border.all(
                      color: hasSelectedInCategory
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.outline.withOpacity(0.3),
                      width: hasSelectedInCategory ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // En-tête de catégorie
                      InkWell(
                        onTap: () {
                          setState(() {
                            _expandedCategory = isExpanded ? null : category;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.all(3.w),
                          child: Row(
                            children: [
                              Text(
                                _getCategoryEmoji(category),
                                style: TextStyle(fontSize: 20.sp),
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category,
                                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: hasSelectedInCategory
                                            ? AppTheme.lightTheme.colorScheme.primary
                                            : AppTheme.lightTheme.colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      '${problematiques.length} problématiques',
                                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isExpanded ? Icons.expand_less : Icons.expand_more,
                                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Liste des problématiques (si expandé)
                      if (isExpanded)
                        ...problematiques.map((p) {
                          final isSelected = _selectedDomains.contains(p.description);
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedDomains.clear();
                                if (!isSelected) {
                                  _selectedDomains.add(p.description);
                                }
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1)
                                    : Colors.transparent,
                                border: Border(
                                  top: BorderSide(
                                    color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.2),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(p.emoji, style: TextStyle(fontSize: 16.sp)),
                                  SizedBox(width: 3.w),
                                  Expanded(
                                    child: Text(
                                      p.title,
                                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
                                      size: 5.w,
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'Mental & émotionnel':
        return '🧠';
      case 'Relations & communication':
        return '💬';
      case 'Argent & carrière':
        return '💼';
      case 'Santé & habitudes de vie':
        return '❤️';
      case 'Productivité & concentration':
        return '⚡';
      case 'Confiance & identité':
        return '🛡️';
      default:
        return '📌';
    }
  }
}
