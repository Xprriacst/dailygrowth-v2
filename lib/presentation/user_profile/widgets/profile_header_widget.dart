import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final String userName;
  final String joinDate;
  final String? profileImageUrl;
  final VoidCallback onAvatarTap;
  final Map<String, dynamic>? userStats;

  const ProfileHeaderWidget({
    Key? key,
    required this.userName,
    required this.joinDate,
    this.profileImageUrl,
    required this.onAvatarTap,
    this.userStats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
              AppTheme.lightTheme.colorScheme.primary,
              AppTheme.lightTheme.colorScheme.secondary,
            ])),
        child: Column(children: [
          // Profile picture and basic info
          Row(children: [
            GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                    width: 20.w,
                    height: 20.w,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppTheme.lightTheme.colorScheme.onPrimary,
                            width: 2)),
                    child: ClipOval(
                        child: profileImageUrl != null
                            ? CustomImageWidget(
                                imageUrl: profileImageUrl!,
                                width: 20.w, height: 20.w, fit: BoxFit.cover)
                            : Container(
                                color: AppTheme.lightTheme.colorScheme.onPrimary
                                    .withAlpha(51),
                                child: Center(
                                    child: CustomIconWidget(
                                        iconName: 'person',
                                        color: AppTheme
                                            .lightTheme.colorScheme.onPrimary,
                                        size: 8.w)))))),
            SizedBox(width: 4.w),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(userName,
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: 1.h),
                  Text('Membre depuis $joinDate',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onPrimary
                              .withAlpha(204))),
                ])),
          ]),

          // User stats if available
          if (userStats != null) ...[
            SizedBox(height: 4.h),
            Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                    color:
                        AppTheme.lightTheme.colorScheme.onPrimary.withAlpha(38),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Compteur de série masqué
                      // _buildStatItem(
                      //     'Série',
                      //     '${userStats!['streak_count'] ?? 0}',
                      //     'local_fire_department'),
                      // _buildStatDivider(),
                      _buildStatItem('Points',
                          '${userStats!['completed_challenges'] ?? 0}', 'star'),
                      _buildStatDivider(),
                      _buildStatItem(
                          'Défis',
                          '${userStats!['completed_challenges'] ?? 0}',
                          'check_circle'),
                    ])),
          ],
        ]));
  }

  Widget _buildStatItem(String label, String value, String iconName) {
    return Column(children: [
      CustomIconWidget(
          iconName: iconName,
          color: AppTheme.lightTheme.colorScheme.onPrimary,
          size: 6.w),
      SizedBox(height: 1.h),
      Text(value,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700)),
      Text(label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onPrimary.withAlpha(204))),
    ]);
  }

  Widget _buildStatDivider() {
    return Container(
        height: 6.h,
        width: 1,
        color: AppTheme.lightTheme.colorScheme.onPrimary.withAlpha(77));
  }
}