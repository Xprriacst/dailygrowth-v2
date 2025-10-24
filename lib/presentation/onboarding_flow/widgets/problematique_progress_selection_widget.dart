import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/app_export.dart';
import '../../../models/challenge_problematique.dart';
import '../../../services/user_service.dart';

/// Widget pour afficher et sélectionner les problématiques avec leur progression
class ProblematiqueProgressSelectionWidget extends StatefulWidget {
  final List<String> selectedDomains;
  final Function(String) onDomainToggle;

  const ProblematiqueProgressSelectionWidget({
    Key? key,
    required this.selectedDomains,
    required this.onDomainToggle,
  }) : super(key: key);

  @override
  State<ProblematiqueProgressSelectionWidget> createState() => _ProblematiqueProgressSelectionWidgetState();
}

class _ProblematiqueProgressSelectionWidgetState extends State<ProblematiqueProgressSelectionWidget>
    with TickerProviderStateMixin {
  
  final UserService _userService = UserService();
  
  List<ChallengeProblematique> _selectedProblematiques = [];
  Map<String, int> _progressByProblematique = {}; // Nombre de défis complétés par problématique
  bool _isLoading = true;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _loadUserProgress();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Charge la progression de l'utilisateur pour chaque problématique
  Future<void> _loadUserProgress() async {
    setState(() => _isLoading = true);
    
    try {
      await _userService.initialize();
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      if (currentUser != null) {
        // Récupérer les problématiques sélectionnées
        final profile = await _userService.getUserProfile(currentUser.id);
        final selectedProblematiquesData = profile?['selected_problematiques'] as List<dynamic>?;
        
        if (selectedProblematiquesData != null && selectedProblematiquesData.isNotEmpty) {
          final selectedDescriptions = selectedProblematiquesData.cast<String>();
          
          // Mapper les descriptions aux objets ChallengeProblematique
          _selectedProblematiques = ChallengeProblematique.allProblematiques
              .where((p) => selectedDescriptions.contains(p.description))
              .toList();

          // Récupérer la progression pour chaque problématique en une seule requête
          final progressMap = await _userService.getProgressByProblematique(currentUser.id);

          _progressByProblematique = {
            for (final entry in progressMap.entries)
              if ((entry.value['completed'] ?? 0) > 0 && selectedDescriptions.contains(entry.key))
                entry.key: (entry.value['completed'] ?? 0) as int,
          };
        }
      }
      
      _animationController.forward();
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement de la progression: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleProblematique(ChallengeProblematique problematique) {
    setState(() {
      if (_selectedProblematiques.contains(problematique)) {
        _selectedProblematiques.remove(problematique);
      } else {
        _selectedProblematiques.add(problematique);
      }
    });

    HapticFeedback.selectionClick();
    _saveSelectedProblematiques();
  }

  Future<void> _saveSelectedProblematiques() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedDescriptions = _selectedProblematiques.map((p) => p.description).toList();
      
      await prefs.setStringList('selected_problematiques', selectedDescriptions);
      
      // Sauvegarder dans Supabase
      await _userService.initialize();
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      if (currentUser != null) {
        await _userService.updateUserProfile(
          userId: currentUser.id,
          selectedProblematiques: selectedDescriptions,
        );
      }
      
      debugPrint('✅ Problématiques sauvegardées: ${selectedDescriptions.join(", ")}');
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde: $e');
    }
  }

  Widget _buildProblematiqueProgressCard(ChallengeProblematique problematique) {
    final isSelected = _selectedProblematiques.contains(problematique);
    final completedCount = _progressByProblematique[problematique.description] ?? 0;
    final progressPercentage = (completedCount / 50 * 100).clamp(0, 100).toInt();
    final hasProgress = completedCount > 0;
    
    return GestureDetector(
      onTap: () => _toggleProblematique(problematique),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 2.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1)
              : AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? AppTheme.lightTheme.colorScheme.primary.withOpacity(0.2)
                  : AppTheme.lightTheme.colorScheme.shadow.withOpacity(0.08),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne 1: Emoji + Titre + Checkmark
            Row(
              children: [
                // Emoji
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppTheme.lightTheme.colorScheme.primary.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    problematique.emoji,
                    style: TextStyle(fontSize: 20.sp),
                  ),
                ),
                SizedBox(width: 3.w),
                
                // Titre
                Expanded(
                  child: Text(
                    problematique.title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected 
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onSurface,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Icône de sélection
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected 
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.outline,
                  size: 20.sp,
                ),
              ],
            ),
            
            // Ligne 2: Barre de progression (seulement si progression > 0)
            if (hasProgress) ...[
              SizedBox(height: 2.h),
              
              // Texte progression
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$completedCount/50 défis complétés',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$progressPercentage%',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 1.h),
              
              // Barre de progression
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progressPercentage / 100,
                  minHeight: 8,
                  backgroundColor: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String category, List<ChallengeProblematique> problematiques) {
    // Filtrer pour n'afficher que les problématiques avec progression
    final problematiquesWithProgress = problematiques.where((p) {
      final count = _progressByProblematique[p.description] ?? 0;
      return count > 0;
    }).toList();
    
    // Ne pas afficher la catégorie si aucune problématique avec progression
    if (problematiquesWithProgress.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de la catégorie
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          margin: EdgeInsets.only(bottom: 2.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1),
                AppTheme.lightTheme.colorScheme.primary.withOpacity(0.05),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(1.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 3.w),
              Text(
                category,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        
        // Liste des problématiques avec progression
        ...problematiquesWithProgress.map((p) => _buildProblematiqueProgressCard(p)).toList(),
        
        SizedBox(height: 3.h),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Mental & émotionnel':
        return Icons.psychology;
      case 'Relations & communication':
        return Icons.people;
      case 'Argent & carrière':
        return Icons.work;
      case 'Santé & habitudes de vie':
        return Icons.favorite;
      case 'Productivité & concentration':
        return Icons.schedule;
      case 'Confiance & identité':
        return Icons.self_improvement;
      default:
        return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(8.h),
          child: CircularProgressIndicator(
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
        ),
      );
    }
    
    if (_progressByProblematique.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 48.sp,
                color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.5),
              ),
              SizedBox(height: 2.h),
              Text(
                'Aucune progression pour le moment',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Complétez des défis pour voir votre progression',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              margin: EdgeInsets.only(bottom: 4.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1),
                    AppTheme.lightTheme.colorScheme.secondary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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
                          color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.trending_up,
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          'Votre progression',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightTheme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Suivez votre avancement pour chaque problématique. Objectif : 50 défis complétés par problématique.',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            // Sections par catégorie
            ...ChallengeProblematique.allCategories.map((category) {
              final problematiques = ChallengeProblematique.getByCategory(category);
              return _buildCategorySection(category, problematiques);
            }).toList(),
            
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }
}
