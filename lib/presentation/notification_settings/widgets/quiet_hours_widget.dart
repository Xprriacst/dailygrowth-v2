import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import './time_picker_widget.dart';

class QuietHoursWidget extends StatelessWidget {
  final bool isEnabled;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<TimeOfDay> onStartTimeChanged;
  final ValueChanged<TimeOfDay> onEndTimeChanged;

  const QuietHoursWidget({
    Key? key,
    required this.isEnabled,
    required this.startTime,
    required this.endTime,
    required this.onEnabledChanged,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Heures de silence',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Désactivez les notifications pendant certaines heures',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 3.w),
              Switch(
                value: isEnabled,
                onChanged: onEnabledChanged,
                activeColor: AppTheme.lightTheme.colorScheme.primary,
                inactiveThumbColor: AppTheme.lightTheme.colorScheme.outline,
                inactiveTrackColor: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
              ),
            ],
          ),
          if (isEnabled) ...[
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: TimePickerWidget(
                    selectedTime: startTime,
                    onTimeChanged: onStartTimeChanged,
                    label: 'Début',
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: TimePickerWidget(
                    selectedTime: endTime,
                    onTimeChanged: onEndTimeChanged,
                    label: 'Fin',
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2.w),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info_outline',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Les notifications seront silencieuses de ${_formatTime(startTime)} à ${_formatTime(endTime)}',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
