import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ChallengeCardWidget extends StatelessWidget {
  final Map<String, dynamic> challenge;
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final VoidCallback? onFavorite;
  final VoidCallback? onRetry;

  const ChallengeCardWidget({
    Key? key,
    required this.challenge,
    this.onTap,
    this.onShare,
    this.onFavorite,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = (challenge['status'] as String) == 'completed';
    final bool isSkipped = (challenge['status'] as String) == 'skipped';
    final String domain = challenge['domain'] as String;
    final String challengeText = challenge['text'] as String;
    final DateTime completionDate = challenge['completionDate'] as DateTime;

    return Dismissible(
      key: Key(challenge['id'].toString()),
      direction: DismissDirection.startToEnd,
      background: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color:
              AppTheme.lightTheme.colorScheme.tertiary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(width: 6.w),
            CustomIconWidget(
              iconName: 'share',
              color: AppTheme.lightTheme.colorScheme.tertiary,
              size: 20,
            ),
            SizedBox(width: 4.w),
            CustomIconWidget(
              iconName: 'favorite_border',
              color: AppTheme.lightTheme.colorScheme.tertiary,
              size: 20,
            ),
            SizedBox(width: 4.w),
            CustomIconWidget(
              iconName: 'refresh',
              color: AppTheme.lightTheme.colorScheme.tertiary,
              size: 20,
            ),
          ],
        ),
      ),
      onDismissed: (direction) {
        // Handle swipe actions
      },
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCompleted
                  ? AppTheme.lightTheme.colorScheme.tertiary
                      .withValues(alpha: 0.3)
                  : AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.lightTheme.colorScheme.shadow
                    .withValues(alpha: 0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: _getDomainColor(domain).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: _getDomainIcon(domain),
                      color: _getDomainColor(domain),
                      size: 16,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getDomainLabel(domain),
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: _getDomainColor(domain),
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        Text(
                          _formatDate(completionDate),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(context, isCompleted, isSkipped),
                ],
              ),
              SizedBox(height: 3.h),
              Text(
                challengeText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      height: 1.4,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
      BuildContext context, bool isCompleted, bool isSkipped) {
    if (isCompleted) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
        decoration: BoxDecoration(
          color:
              AppTheme.lightTheme.colorScheme.tertiary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.lightTheme.colorScheme.tertiary,
              size: 14,
            ),
            SizedBox(width: 1.w),
            Text(
              'Terminé',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.tertiary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      );
    } else if (isSkipped) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: 'skip_next',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 14,
            ),
            SizedBox(width: 1.w),
            Text(
              'Ignoré',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      );
    }
    return SizedBox.shrink();
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'share',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 20,
              ),
              title: Text('Partager'),
              onTap: () {
                Navigator.pop(context);
                onShare?.call();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'favorite_border',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 20,
              ),
              title: Text('Ajouter aux favoris'),
              onTap: () {
                Navigator.pop(context);
                onFavorite?.call();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'refresh',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 20,
              ),
              title: Text('Refaire le défi'),
              onTap: () {
                Navigator.pop(context);
                onRetry?.call();
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  String _getDomainIcon(String domain) {
    switch (domain.toLowerCase()) {
      case 'santé':
        return 'favorite';
      case 'relations':
        return 'people';
      case 'carrière':
        return 'work';
      case 'créativité':
        return 'palette';
      case 'finances':
        return 'account_balance_wallet';
      case 'spiritualité':
        return 'self_improvement';
      default:
        return 'star';
    }
  }

  Color _getDomainColor(String domain) {
    switch (domain.toLowerCase()) {
      case 'santé':
        return Color(0xFF6B8E5A);
      case 'relations':
        return Color(0xFF7B9BB0);
      case 'carrière':
        return Color(0xFF2D5A87);
      case 'créativité':
        return Color(0xFFE8A87C);
      case 'finances':
        return Color(0xFFD4A574);
      case 'spiritualité':
        return Color(0xFF9B7CB8);
      default:
        return AppTheme.lightTheme.colorScheme.primary;
    }
  }

  String _getDomainLabel(String domain) {
    return domain.substring(0, 1).toUpperCase() + domain.substring(1);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return "Aujourd'hui";
    } else if (difference == 1) {
      return "Hier";
    } else if (difference < 7) {
      return "Il y a $difference jours";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }
}
