import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class WeeklyProgressWidget extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyData;
  final double weeklyCompletionRate;

  const WeeklyProgressWidget({
    Key? key,
    required this.weeklyData,
    required this.weeklyCompletionRate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CustomIconWidget(
                iconName: 'trending_up',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Progrès de la semaine',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(weeklyCompletionRate * 100).toInt()}%',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Progress bar
          Container(
            height: 1.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: weeklyCompletionRate,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.lightTheme.colorScheme.primary,
                      AppTheme.lightTheme.colorScheme.tertiary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // Weekly calendar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: weeklyData.map((day) => _buildDayIndicator(day)).toList(),
          ),

          SizedBox(height: 2.h),

          // Motivational message
          Center(
            child: Text(
              _getMotivationalMessage(weeklyCompletionRate),
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayIndicator(Map<String, dynamic> day) {
    final bool isCompleted = day['completed'] as bool? ?? false;
    final bool isToday = day['isToday'] as bool? ?? false;
    final String dayName = day['day'] as String? ?? '';

    return Column(
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppTheme.lightTheme.colorScheme.tertiary
                : isToday
                    ? AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.2)
                    : AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.1),
            border: isToday
                ? Border.all(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: isCompleted
              ? CustomIconWidget(
                  iconName: 'check',
                  color: Colors.white,
                  size: 5.w,
                )
              : isToday
                  ? CustomIconWidget(
                      iconName: 'today',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 5.w,
                    )
                  : null,
        ),
        SizedBox(height: 1.h),
        Text(
          dayName,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: isToday
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  String _getMotivationalMessage(double completionRate) {
    if (completionRate >= 0.8) {
      return 'Excellent travail ! Vous êtes sur la bonne voie ! 🎉';
    } else if (completionRate >= 0.5) {
      return 'Bon progrès ! Continuez comme ça ! 💪';
    } else if (completionRate >= 0.2) {
      return 'Chaque petit pas compte. Vous pouvez le faire ! 🌱';
    } else {
      return 'Un nouveau jour, une nouvelle opportunité ! ✨';
    }
  }
}
