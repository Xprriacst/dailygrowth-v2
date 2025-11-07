import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import '../services/web_notification_service.dart';

class NotificationPermissionDialog extends StatelessWidget {
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;

  const NotificationPermissionDialog({
    Key? key,
    this.onPermissionGranted,
    this.onPermissionDenied,
  }) : super(key: key);

  static Future<void> showIfNeeded(
    BuildContext context, {
    VoidCallback? onPermissionGranted,
    VoidCallback? onPermissionDenied,
  }) async {
    final webNotificationService = WebNotificationService();
    final currentPermission = webNotificationService.permissionStatus;
    
    // Afficher la popup seulement si les permissions sont "default" (pas encore demandées)
    if (currentPermission == 'default') {
      return showDialog<void>(
        context: context,
        barrierDismissible: false, // L'utilisateur doit faire un choix
        builder: (BuildContext context) {
          return NotificationPermissionDialog(
            onPermissionGranted: onPermissionGranted,
            onPermissionDenied: onPermissionDenied,
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(4.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône de notification
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'notification',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 40,
              ),
            ),
            
            SizedBox(height: 3.h),
            
            // Titre
            Text(
              'Restez motivé avec ChallengeMe !',
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
            
            SizedBox(height: 2.h),
            
            // Description
            Text(
              'Recevez vos défis quotidiens et célébrez vos réussites directement sur votre appareil. Les notifications vous aideront à rester sur la bonne voie !',
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            
            SizedBox(height: 1.h),
            
            // Avantages
            _buildBenefit('🎯', 'Défis quotidiens personnalisés'),
            _buildBenefit('🏆', 'Célébration de vos réussites'),
            _buildBenefit('📱', 'Rappels au bon moment'),
            
            SizedBox(height: 4.h),
            
            // Boutons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _handleDeny(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3.w),
                      ),
                    ),
                    child: Text(
                      'Plus tard',
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: 3.w),
                
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _handleAllow(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3.w),
                      ),
                    ),
                    child: Text(
                      'Autoriser',
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 1.h),
            
            // Note discrète
            Text(
              'Vous pouvez modifier ces préférences à tout moment dans les paramètres.',
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit(String emoji, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 16.sp)),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              text,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAllow(BuildContext context) async {
    HapticFeedback.lightImpact();
    
    try {
      final permission = await WebNotificationService().requestPermission();
      
      Navigator.of(context).pop();
      
      if (permission == 'granted') {
        onPermissionGranted?.call();
        _showSuccessSnackBar(context);
      } else {
        onPermissionDenied?.call();
        _showDeniedSnackBar(context);
      }
    } catch (e) {
      Navigator.of(context).pop();
      onPermissionDenied?.call();
      _showErrorSnackBar(context, e.toString());
    }
  }

  void _handleDeny(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    onPermissionDenied?.call();
    _showLaterSnackBar(context);
  }

  void _showSuccessSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ Notifications activées ! Vous recevrez vos défis quotidiens.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.w)),
      ),
    );
  }

  void _showDeniedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('❌ Notifications refusées. Vous pouvez les activer plus tard dans les paramètres.'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.w)),
      ),
    );
  }

  void _showLaterSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('💭 Pas de problème ! Vous pouvez activer les notifications plus tard.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.w)),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Erreur lors de la demande: $error'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.w)),
      ),
    );
  }
}