import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/web_notification_service.dart';
import './widgets/notification_toggle_widget.dart';
import './widgets/permission_status_widget.dart';
import './widgets/quiet_hours_widget.dart';
import './widgets/section_header_widget.dart';
import './widgets/time_picker_widget.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({Key? key}) : super(key: key);

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  // Notification permissions
  bool _notificationPermissionGranted = true;

  // Daily challenge settings
  bool _dailyChallengeEnabled = true;
  TimeOfDay _dailyChallengeTime = const TimeOfDay(hour: 9, minute: 0);

  // Achievement notifications
  bool _achievementNotificationsEnabled = true;

  // Weekly summary
  bool _weeklySummaryEnabled = true;

  // Email fallback
  bool _emailFallbackEnabled = false;

  // Quiet hours
  bool _quietHoursEnabled = false;
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 8, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2.h),

              // Permission status
              PermissionStatusWidget(
                isGranted: _notificationPermissionGranted,
                onRequestPermission: _requestNotificationPermission,
              ),

              // Daily Challenge Section
              SectionHeaderWidget(
                title: 'Défi quotidien',
                subtitle: 'Recevez votre défi personnalisé chaque jour',
              ),

              NotificationToggleWidget(
                title: 'Rappel quotidien',
                description:
                    'Notification pour votre défi quotidien avec contenu personnalisé',
                value: _dailyChallengeEnabled,
                onChanged: (value) {
                  HapticFeedback.lightImpact();
                  setState(() => _dailyChallengeEnabled = value);
                },
              ),

              if (_dailyChallengeEnabled) ...[
                SizedBox(height: 1.h),
                TimePickerWidget(
                  selectedTime: _dailyChallengeTime,
                  onTimeChanged: (time) {
                    HapticFeedback.selectionClick();
                    setState(() => _dailyChallengeTime = time);
                  },
                  label: 'Heure du rappel quotidien',
                ),
              ],

              // Achievement Section
              SectionHeaderWidget(
                title: 'Réussites',
                subtitle: 'Célébrez vos accomplissements et jalons',
              ),

              NotificationToggleWidget(
                title: 'Notifications de réussite',
                description:
                    'Recevez des félicitations pour vos badges et jalons atteints',
                value: _achievementNotificationsEnabled,
                onChanged: (value) {
                  HapticFeedback.lightImpact();
                  setState(() => _achievementNotificationsEnabled = value);
                },
              ),

              // Weekly Summary Section
              SectionHeaderWidget(
                title: 'Résumé hebdomadaire',
                subtitle: 'Suivez vos progrès chaque semaine',
              ),

              NotificationToggleWidget(
                title: 'Résumé des progrès',
                description:
                    'Recevez un récapitulatif de vos progrès chaque dimanche',
                value: _weeklySummaryEnabled,
                onChanged: (value) {
                  HapticFeedback.lightImpact();
                  setState(() => _weeklySummaryEnabled = value);
                },
              ),

              // Quiet Hours Section
              SectionHeaderWidget(
                title: 'Ne pas déranger',
                subtitle: 'Définissez des heures de silence',
              ),

              QuietHoursWidget(
                isEnabled: _quietHoursEnabled,
                startTime: _quietHoursStart,
                endTime: _quietHoursEnd,
                onEnabledChanged: (value) {
                  HapticFeedback.lightImpact();
                  setState(() => _quietHoursEnabled = value);
                },
                onStartTimeChanged: (time) {
                  HapticFeedback.selectionClick();
                  setState(() => _quietHoursStart = time);
                },
                onEndTimeChanged: (time) {
                  HapticFeedback.selectionClick();
                  setState(() => _quietHoursEnd = time);
                },
              ),

              // Email Fallback Section
              SectionHeaderWidget(
                title: 'Sauvegarde email',
                subtitle: 'Alternative en cas d\'échec des notifications push',
              ),

              NotificationToggleWidget(
                title: 'Notifications par email',
                description:
                    'Recevez les notifications importantes par email si les notifications push échouent',
                value: _emailFallbackEnabled,
                onChanged: (value) {
                  HapticFeedback.lightImpact();
                  setState(() => _emailFallbackEnabled = value);
                },
              ),

              // Test and Reset Section
              SectionHeaderWidget(
                title: 'Options avancées',
              ),

              _buildActionButtons(),

              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
        icon: CustomIconWidget(
          iconName: 'arrow_back_ios',
          color: AppTheme.lightTheme.colorScheme.onSurface,
          size: 20,
        ),
      ),
      title: Text(
        'Notifications',
        style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppTheme.lightTheme.colorScheme.onSurface,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Test notification button
        Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(vertical: 1.h),
          child: ElevatedButton.icon(
            onPressed: _sendTestNotification,
            icon: CustomIconWidget(
              iconName: 'notifications_active',
              color: Colors.white,
              size: 18,
            ),
            label: Text(
              'Tester les notifications',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              padding: EdgeInsets.symmetric(vertical: 3.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3.w),
              ),
            ),
          ),
        ),

        // Reset to defaults button
        Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(vertical: 1.h),
          child: OutlinedButton.icon(
            onPressed: _resetToDefaults,
            icon: CustomIconWidget(
              iconName: 'refresh',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 18,
            ),
            label: Text(
              'Restaurer les paramètres par défaut',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 3.h),
              side: BorderSide(
                color: AppTheme.lightTheme.colorScheme.primary,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3.w),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _requestNotificationPermission() async {
    // VRAIE demande de permission (pas simulation)
    HapticFeedback.mediumImpact();

    try {
      final permission = await WebNotificationService().requestPermission();
      
      if (permission == 'granted') {
        _showSnackBar('✅ Notifications autorisées !');
        setState(() {
          _notificationPermissionGranted = true;
        });
      } else {
        _showSnackBar('❌ Permission refusée');
        setState(() {
          _notificationPermissionGranted = false;
        });
      }
    } catch (e) {
      _showSnackBar('❌ Erreur: $e');
    }

    // Fallback dialogue si pas web
    /*
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.w),
        ),
        title: Text(
          'Autoriser les notifications',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        content: Text(
          'DailyGrowth souhaite vous envoyer des notifications pour vos défis quotidiens et vos réussites.',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Ne pas autoriser',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _notificationPermissionGranted = true);
              Navigator.pop(context);
              HapticFeedback.lightImpact();
            },
            child: Text(
              'Autoriser',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    */
  }

  void _sendTestNotification() {
    HapticFeedback.mediumImpact();

    if (!_notificationPermissionGranted) {
      _showSnackBar('Veuillez d\'abord autoriser les notifications',
          isError: true);
      return;
    }

    _showSnackBar(
        'Notification de test envoyée ! Vérifiez votre barre de notifications.');
  }

  void _resetToDefaults() {
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.w),
        ),
        title: Text(
          'Restaurer les paramètres',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir restaurer tous les paramètres de notification par défaut ?',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _dailyChallengeEnabled = true;
                _dailyChallengeTime = const TimeOfDay(hour: 9, minute: 0);
                _achievementNotificationsEnabled = true;
                _weeklySummaryEnabled = true;
                _emailFallbackEnabled = false;
                _quietHoursEnabled = false;
                _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
                _quietHoursEnd = const TimeOfDay(hour: 8, minute: 0);
              });
              Navigator.pop(context);
              HapticFeedback.lightImpact();
              _showSnackBar('Paramètres restaurés avec succès');
            },
            child: Text(
              'Restaurer',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: isError ? 'error_outline' : 'check_circle_outline',
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                message,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? AppTheme.lightTheme.colorScheme.error
            : AppTheme.lightTheme.colorScheme.tertiary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3.w),
        ),
        margin: EdgeInsets.all(4.w),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
