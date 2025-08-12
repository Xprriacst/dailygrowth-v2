import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class NavigationControlsWidget extends StatelessWidget {
  final bool isLastPage;
  final bool isLifeDomainPage;
  final bool canProceed;
  final bool isProcessing;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const NavigationControlsWidget({
    Key? key,
    required this.isLastPage,
    required this.isLifeDomainPage,
    required this.canProceed,
    required this.isProcessing,
    required this.onNext,
    required this.onSkip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Skip button
          TextButton(
            onPressed: isProcessing ? null : onSkip,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              foregroundColor:
                  AppTheme.lightTheme.colorScheme.onSurface.withAlpha(153),
              disabledForegroundColor:
                  AppTheme.lightTheme.colorScheme.onSurface.withAlpha(102),
            ),
            child: isProcessing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.lightTheme.colorScheme.onSurface
                            .withAlpha(153),
                      ),
                    ),
                  )
                : Text(
                    'Passer',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),

          // Next/Finish button
          ElevatedButton(
            onPressed: (isLifeDomainPage && !canProceed) || isProcessing
                ? null
                : onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              disabledBackgroundColor: AppTheme.lightTheme.colorScheme.outline,
              disabledForegroundColor:
                  AppTheme.lightTheme.colorScheme.onSurface.withAlpha(153),
            ),
            child: isProcessing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    isLastPage ? 'Commencer' : 'Suivant',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
