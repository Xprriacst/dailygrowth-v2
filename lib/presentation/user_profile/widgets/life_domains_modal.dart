import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

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

  final List<Map<String, dynamic>> _availableDomains = [
    {"name": "Santé & Bien-être", "icon": "favorite"},
    {"name": "Relations & Famille", "icon": "people"},
    {"name": "Carrière & Travail", "icon": "work"},
    {"name": "Finances", "icon": "account_balance_wallet"},
    {"name": "Développement Personnel", "icon": "psychology"},
    {"name": "Loisirs & Hobbies", "icon": "sports_esports"},
    {"name": "Spiritualité", "icon": "self_improvement"},
    {"name": "Éducation & Apprentissage", "icon": "school"},
    {"name": "Créativité & Art", "icon": "palette"},
    {"name": "Voyage & Aventure", "icon": "flight"},
  ];

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
                  .withValues(alpha: 0.3),
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
            'Sélectionnez les domaines qui vous intéressent le plus pour recevoir des défis personnalisés.',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Expanded(
            child: ListView.builder(
              itemCount: _availableDomains.length,
              itemBuilder: (context, index) {
                final domain = _availableDomains[index];
                final isSelected =
                    _selectedDomains.contains(domain["name"] as String);

                return Container(
                  margin: EdgeInsets.only(bottom: 2.h),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedDomains.remove(domain["name"] as String);
                        } else {
                          _selectedDomains.add(domain["name"] as String);
                        }
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
                            child: CustomIconWidget(
                              iconName: domain["icon"] as String,
                              color: isSelected
                                  ? AppTheme.lightTheme.colorScheme.onPrimary
                                  : AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                              size: 6.w,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              domain["name"] as String,
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
