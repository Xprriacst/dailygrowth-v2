import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import './life_domain_card_widget.dart';

class LifeDomainSelectionWidget extends StatelessWidget {
  final List<String> selectedDomains;
  final Function(String) onDomainToggle;

  const LifeDomainSelectionWidget({
    Key? key,
    required this.selectedDomains,
    required this.onDomainToggle,
  }) : super(key: key);

  final List<Map<String, dynamic>> lifeDomains = const [
    {
      'id': 'sante',
      'title': 'Santé & Bien-être',
      'icon': 'favorite',
      'color': Color(0xFFE8F5E8),
      'iconColor': Color(0xFF4CAF50),
    },
    {
      'id': 'relations',
      'title': 'Relations & Famille',
      'icon': 'people',
      'color': Color(0xFFE3F2FD),
      'iconColor': Color(0xFF2196F3),
    },
    {
      'id': 'carriere',
      'title': 'Carrière & Travail',
      'icon': 'business_center',
      'color': Color(0xFFFFF3E0),
      'iconColor': Color(0xFFFF9800),
    },
    {
      'id': 'finances',
      'title': 'Finances & Argent',
      'icon': 'help_outline',
      'color': Color(0xFFF3E5F5),
      'iconColor': Color(0xFF9C27B0),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(6.w),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: 8.h),

          // Title
          Text('Choisissez vos domaines de vie',
              style: TextStyle(
                  fontSize: 28.sp, fontWeight: FontWeight.bold, height: 1.2)),

          SizedBox(height: 2.h),

          // Subtitle
          Text(
              'Sélectionnez les domaines sur lesquels vous souhaitez vous concentrer pour votre développement personnel.',
              style: TextStyle(fontSize: 16.sp, height: 1.4)),

          SizedBox(height: 6.h),

          // Domain cards
          Expanded(
              child: Column(children: [
            for (int i = 0; i < lifeDomains.length; i += 2) ...[
              Row(children: [
                Expanded(
                    child: LifeDomainCardWidget(
                        title: lifeDomains[i]['title'] as String,
                        iconName: lifeDomains[i]['icon'] as String,
                        isSelected:
                            selectedDomains.contains(lifeDomains[i]['id']),
                        onTap: () => onDomainToggle(lifeDomains[i]['id']))),
                SizedBox(width: 4.w),
                if (i + 1 < lifeDomains.length)
                  Expanded(
                      child: LifeDomainCardWidget(
                          title: lifeDomains[i + 1]['title'] as String,
                          iconName: lifeDomains[i + 1]['icon'] as String,
                          isSelected: selectedDomains
                              .contains(lifeDomains[i + 1]['id']),
                          onTap: () =>
                              onDomainToggle(lifeDomains[i + 1]['id'])))
                else
                  Expanded(child: SizedBox()),
              ]),
              if (i + 2 < lifeDomains.length) SizedBox(height: 3.h),
            ],
          ])),

          SizedBox(height: 4.h),

          // Selection counter
          if (selectedDomains.isNotEmpty)
            Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(20)),
                child: Text(
                    '${selectedDomains.length} domaine${selectedDomains.length > 1 ? 's' : ''} sélectionné${selectedDomains.length > 1 ? 's' : ''}',
                    style: TextStyle(
                        fontSize: 14.sp, fontWeight: FontWeight.w600))),
        ]));
  }
}
