import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';
import '../../../services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProblematiqueProgressWidget extends StatefulWidget {
  const ProblematiqueProgressWidget({Key? key}) : super(key: key);

  @override
  State<ProblematiqueProgressWidget> createState() =>
      _ProblematiqueProgressWidgetState();
}

class _ProblematiqueProgressWidgetState
    extends State<ProblematiqueProgressWidget> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  Map<String, Map<String, dynamic>> _progressData = {};

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    try {
      setState(() => _isLoading = true);

      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      final progress = await _userService.getProgressByProblematique(currentUser.id);
      
      setState(() {
        _progressData = progress;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('⚠️ Erreur chargement progression: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(2.h),
          child: CircularProgressIndicator(
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
        ),
      );
    }

    if (_progressData.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        padding: EdgeInsets.all(3.h),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.track_changes,
              size: 10.w,
              color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.5),
            ),
            SizedBox(height: 2.h),
            Text(
              'Progression par Problématique',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Complète des défis pour voir ta progression !',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 2.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progression par Problématique',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    size: 5.w,
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                  onPressed: _loadProgressData,
                  tooltip: 'Rafraîchir',
                ),
              ],
            ),
          ),
          ..._progressData.entries.map((entry) {
            final problematique = entry.key;
            final data = entry.value;
            final completed = data['completed'] as int;
            final total = data['total'] as int;
            final percentage = data['percentage'] as int;
            final remaining = data['remaining'] as int;

            return Container(
              margin: EdgeInsets.only(bottom: 2.h),
              padding: EdgeInsets.all(3.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Problématique name
                  Row(
                    children: [
                      Icon(
                        Icons.flag_circle,
                        size: 5.w,
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          problematique,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.lightTheme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.lightTheme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 1.h,
                      backgroundColor: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$completed/$total défis complétés',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        '$remaining restants',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
