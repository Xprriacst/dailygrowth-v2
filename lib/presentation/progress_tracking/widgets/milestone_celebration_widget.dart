import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';

class MilestoneCelebrationWidget extends StatefulWidget {
  final Map<String, dynamic> milestone;
  final VoidCallback onDismiss;

  const MilestoneCelebrationWidget({
    Key? key,
    required this.milestone,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<MilestoneCelebrationWidget> createState() =>
      _MilestoneCelebrationWidgetState();
}

class _MilestoneCelebrationWidgetState extends State<MilestoneCelebrationWidget>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _confettiController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeIn,
    ));

    // Trigger haptic feedback
    HapticFeedback.heavyImpact();

    // Start animations
    _scaleController.forward();
    _confettiController.repeat();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.8),
      child: Stack(
        children: [
          // Confetti animation
          ...List.generate(20, (index) => _buildConfettiParticle(index)),

          // Main celebration content
          Center(
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: 80.w,
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Celebration icon
                          Container(
                            width: 20.w,
                            height: 20.w,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.yellow[400]!,
                                  Colors.orange[400]!,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.yellow.withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CustomIconWidget(
                              iconName: widget.milestone['icon'] as String,
                              color: Colors.white,
                              size: 10.w,
                            ),
                          ),

                          SizedBox(height: 3.h),

                          // Celebration title
                          Text(
                            'Félicitations !',
                            style: GoogleFonts.inter(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.lightTheme.colorScheme.primary,
                            ),
                          ),

                          SizedBox(height: 1.h),

                          // Milestone description
                          Text(
                            widget.milestone['title'] as String,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.lightTheme.colorScheme.onSurface,
                            ),
                          ),

                          SizedBox(height: 1.h),

                          Text(
                            widget.milestone['description'] as String,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.lightTheme.colorScheme.onSurface
                                  .withOpacity(0.8),
                            ),
                          ),

                          SizedBox(height: 4.h),

                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _shareProgress,
                                  icon: CustomIconWidget(
                                    iconName: 'share',
                                    color:
                                        AppTheme.lightTheme.colorScheme.primary,
                                    size: 4.w,
                                  ),
                                  label: Text('Partager'),
                                  style: OutlinedButton.styleFrom(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 2.h),
                                  ),
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: widget.onDismiss,
                                  child: Text('Continuer'),
                                  style: ElevatedButton.styleFrom(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 2.h),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfettiParticle(int index) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ];

    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) {
        final progress = _confettiController.value;
        final startX = (index % 5) * 20.w;
        final startY = -10.h;
        final endY = 110.h;
        final currentY = startY + (endY - startY) * progress;
        final rotation = progress * 4 * 3.14159;

        return Positioned(
          left: startX + (index % 3 - 1) * 10.w * progress,
          top: currentY,
          child: Transform.rotate(
            angle: rotation,
            child: Container(
              width: 2.w,
              height: 4.w,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                borderRadius: BorderRadius.circular(1.w),
              ),
            ),
          ),
        );
      },
    );
  }

  void _shareProgress() {
    // Implement native sharing functionality
    final shareText =
        'Je viens de débloquer "${widget.milestone['title']}" dans DailyGrowth ! 🎉';

    // For now, show a toast message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fonctionnalité de partage bientôt disponible !'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      ),
    );
  }
}