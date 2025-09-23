import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class OnboardingPageWidget extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String description;
  final bool isLastPage;
  final bool isPWATutorial;
  final int? step;

  const OnboardingPageWidget({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.description,
    this.isLastPage = false,
    this.isPWATutorial = false,
    this.step,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 8.w : 6.w, vertical: kIsWeb ? 6.h : 4.h),
        child: Column(
          children: [
            if (isPWATutorial && step != null)
              Container(
                margin: EdgeInsets.only(bottom: kIsWeb ? 3.h : 2.h),
                padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 6.w : 4.w, vertical: kIsWeb ? 2.h : 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Tutoriel PWA – Étape $step/3',
                  style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: kIsWeb ? 40.h : 35.h, // Plus de hauteur sur web
                  minHeight: kIsWeb ? 30.h : 25.h, // Plus de hauteur minimum sur web
                ),
                child: CustomImageWidget(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(height: kIsWeb ? 6.h : 4.h), // Plus d'espace sur web
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style:
                        AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: kIsWeb ? 3.h : 2.h), // Plus d'espace sur web
                  Flexible(
                    child: Text(
                      description,
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
