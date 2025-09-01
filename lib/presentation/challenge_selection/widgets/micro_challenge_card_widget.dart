import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MicroChallengeCard extends StatefulWidget {
  final int numero;
  final String nom;
  final String mission;
  final String pourquoi;
  final String? bonus;
  final String dureeEstimee;
  final VoidCallback? onCompleted;

  const MicroChallengeCard({
    Key? key,
    required this.numero,
    required this.nom,
    required this.mission,
    required this.pourquoi,
    this.bonus,
    required this.dureeEstimee,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<MicroChallengeCard> createState() => _MicroChallengeCardState();
}

class _MicroChallengeCardState extends State<MicroChallengeCard>
    with TickerProviderStateMixin {
  bool _isCompleted = false;
  bool _isExpanded = false;
  late AnimationController _completionController;
  late AnimationController _expansionController;
  late Animation<double> _completionAnimation;
  late Animation<double> _expansionAnimation;

  @override
  void initState() {
    super.initState();
    _completionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _expansionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _completionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _completionController, curve: Curves.elasticOut),
    );
    _expansionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _expansionController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _completionController.dispose();
    _expansionController.dispose();
    super.dispose();
  }

  void _toggleCompletion() {
    setState(() {
      _isCompleted = !_isCompleted;
    });

    if (_isCompleted) {
      _completionController.forward();
      HapticFeedback.heavyImpact();
      widget.onCompleted?.call();
    } else {
      _completionController.reverse();
      HapticFeedback.lightImpact();
    }
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _expansionController.forward();
    } else {
      _expansionController.reverse();
    }

    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_completionAnimation, _expansionAnimation]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: _isCompleted 
                ? Colors.green.withValues(alpha: 0.1)
                : AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isCompleted 
                  ? Colors.green.withValues(alpha: 0.3)
                  : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
              width: _isCompleted ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isCompleted 
                    ? Colors.green.withValues(alpha: 0.2)
                    : AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: _isCompleted ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header du défi
              InkWell(
                onTap: _toggleExpansion,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Row(
                    children: [
                      // Numéro du défi
                      Flexible(
                        flex: 0,
                        child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          color: _isCompleted 
                              ? Colors.green
                              : AppTheme.lightTheme.colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isCompleted ? Colors.green : AppTheme.lightTheme.colorScheme.primary)
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isCompleted
                              ? ScaleTransition(
                                  scale: _completionAnimation,
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 6.w,
                                  ),
                                )
                              : Text(
                                  '${widget.numero}',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        ),
                      ),

                      SizedBox(width: 4.w),

                      // Titre et durée
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.nom,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: _isCompleted 
                                    ? Colors.green[800]
                                    : AppTheme.lightTheme.colorScheme.onSurface,
                                decoration: _isCompleted 
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            Wrap(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 4.w,
                                  color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  '${widget.dureeEstimee} min',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Bouton d'expansion
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                          size: 6.w,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Contenu étendu
              SizeTransition(
                sizeFactor: _expansionAnimation,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(
                        color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
                        height: 2.h,
                      ),

                      // Mission
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🎯 Mission',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.lightTheme.colorScheme.primary,
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              widget.mission,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppTheme.lightTheme.colorScheme.onSurface,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 2.h),

                      // Pourquoi
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '💡 Pourquoi ?',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              widget.pourquoi,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppTheme.lightTheme.colorScheme.onSurface,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bonus (si présent)
                      if (widget.bonus != null) ...[
                        SizedBox(height: 2.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '⭐ Bonus',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                widget.bonus!,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppTheme.lightTheme.colorScheme.onSurface,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: 3.h),

                      // Bouton de completion
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _toggleCompletion,
                          icon: Icon(
                            _isCompleted ? Icons.undo : Icons.check_circle,
                            size: 5.w,
                          ),
                          label: Text(
                            _isCompleted ? 'Marquer comme non fait' : 'Marquer comme fait',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isCompleted 
                                ? Colors.grey[300]
                                : Colors.green,
                            foregroundColor: _isCompleted 
                                ? Colors.grey[700]
                                : Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
