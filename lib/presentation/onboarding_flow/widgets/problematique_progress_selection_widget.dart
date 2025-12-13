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
  
  static const Map<String, int> _demoProgressSample = {
    'devenir plus charismatique et développer mon réseau': 18,
    'apprendre à lacher-prise, arreter de vouloir tout maitriser': 9,
    'Diversifier mes sources de revenus': 12,
  };

  Set<String> _selectedProblematiqueDescriptions = {};
  Map<String, int> _progressByProblematique = {}; // Nombre de défis complétés par problématique
  bool _usingDemoData = false;
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
          // Limiter à une seule problématique : prendre uniquement la première
          final firstProblematique = selectedProblematiquesData.first as String;
          _selectedProblematiqueDescriptions = {firstProblematique};

          // Si plusieurs problématiques étaient sélectionnées, nettoyer la base de données
          if (selectedProblematiquesData.length > 1) {
            await _userService.updateUserProfile(
              userId: currentUser.id,
              selectedProblematiques: [firstProblematique],
            );
            debugPrint('🧹 Nettoyage: ${selectedProblematiquesData.length} problématiques réduites à 1');
          }
        }

        // Récupérer la progression pour chaque problématique en une seule requête
        final progressMap = await _userService.getProgressByProblematique(currentUser.id);

        final Map<String, int> progressCounts = {};
        for (final entry in progressMap.entries) {
          final completedRaw = entry.value['completed'] ?? 0;
          final completed = completedRaw is int ? completedRaw : int.tryParse('$completedRaw') ?? 0;
          progressCounts[entry.key] = completed;
        }

        if (progressCounts.isEmpty) {
          // Utiliser des données de démonstration pour l'aperçu visuel
          progressCounts.addAll(_demoProgressSample);
          _usingDemoData = true;
        } else {
          _usingDemoData = false;
        }

        // S'assurer que toutes les problématiques sont présentes (au moins 0)
        for (final problematique in ChallengeProblematique.allProblematiques) {
          progressCounts.putIfAbsent(problematique.description, () => 0);
        }

        _progressByProblematique = progressCounts;
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement de la progression: $e');
    } finally {
      if (!mounted) return;

      if (_animationController.status == AnimationStatus.dismissed) {
        _animationController.forward();
      }

      setState(() => _isLoading = false);
    }
  }

  void _toggleProblematique(ChallengeProblematique problematique) {
    final description = problematique.description;
    final wasSelected = _selectedProblematiqueDescriptions.contains(description);

    setState(() {
      // Limiter à une seule problématique sélectionnée
      if (wasSelected) {
        // Déselectionner la problématique actuelle
        _selectedProblematiqueDescriptions.remove(description);
      } else {
        // Remplacer la sélection actuelle par la nouvelle
        _selectedProblematiqueDescriptions.clear();
        _selectedProblematiqueDescriptions.add(description);
      }
    });

    HapticFeedback.selectionClick();
    // Passer un flag pour indiquer si on doit afficher la popup (seulement si on sélectionne, pas si on déselectionne)
    _saveSelectedProblematiques(showPopup: !wasSelected);
  }

  Future<void> _saveSelectedProblematiques({bool showPopup = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedDescriptions = _selectedProblematiqueDescriptions.toList();

      await prefs.setStringList('selected_problematiques', selectedDescriptions);

      // Sauvegarder dans Supabase
      await _userService.initialize();
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser != null) {
        await _userService.updateUserProfile(
          userId: currentUser.id,
          selectedProblematiques: selectedDescriptions,
        );

        // Afficher la popup de confirmation uniquement si une problématique a été sélectionnée
        if (showPopup && selectedDescriptions.isNotEmpty) {
          _showConfirmationDialog();
        }
      }

      debugPrint('✅ Problématiques sauvegardées: ${selectedDescriptions.join(", ")}');
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde: $e');
    }
  }

  void _showConfirmationDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
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
                // Icône de succès
                Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 12.w,
                  ),
                ),
                SizedBox(height: 3.h),

                // Titre
                Text(
                  'Changement pris en compte',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 2.h),

                // Message
                Text(
                  'Votre nouvelle problématique sera effective à partir de demain.',
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),

                // Bouton OK
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                      foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'OK',
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProblematiqueProgressCard(ChallengeProblematique problematique) {
    final isSelected = _selectedProblematiqueDescriptions.contains(problematique.description);
    final completedCount = _progressByProblematique[problematique.description] ?? 0;
    final progressPercentage = (completedCount / 30 * 100).clamp(0, 100).toInt(); // 30 défis par problématique

    // Toujours activer pour permettre le changement de problématique
    const isEnabled = true;

    return GestureDetector(
      onTap: isEnabled ? () => _toggleProblematique(problematique) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 2.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1)
              : isEnabled
                  ? AppTheme.lightTheme.colorScheme.surface
                  : AppTheme.lightTheme.colorScheme.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.lightTheme.colorScheme.primary
                : isEnabled
                    ? AppTheme.lightTheme.colorScheme.outline.withOpacity(0.2)
                    : AppTheme.lightTheme.colorScheme.outline.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.lightTheme.colorScheme.primary.withOpacity(0.2)
                  : isEnabled
                      ? AppTheme.lightTheme.colorScheme.shadow.withOpacity(0.08)
                      : Colors.transparent,
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
                  child: Opacity(
                    opacity: isEnabled ? 1.0 : 0.4,
                    child: Text(
                      problematique.emoji,
                      style: TextStyle(fontSize: 20.sp),
                    ),
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
                          : isEnabled
                              ? AppTheme.lightTheme.colorScheme.onSurface
                              : AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.4),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Icône de sélection
                Opacity(
                  opacity: isEnabled ? 1.0 : 0.4,
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.outline,
                    size: 20.sp,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 2.h),

            // Texte progression
            Opacity(
              opacity: isEnabled ? 1.0 : 0.4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$completedCount défis complétés',
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
            ),

            SizedBox(height: 1.h),

            // Barre de progression
            Opacity(
              opacity: isEnabled ? 1.0 : 0.4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progressPercentage / 100,
                  minHeight: 8,
                  backgroundColor: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String category, List<ChallengeProblematique> problematiques) {
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
        
        // Liste des problématiques avec progression (ou 0%)
        ...problematiques.map((p) => _buildProblematiqueProgressCard(p)).toList(),
        
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
                    'Suivez votre avancement pour chaque problématique. Le changement de problématique sera effectif le lendemain.',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),
                  if (_usingDemoData) ...[
                    SizedBox(height: 1.5.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.secondary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 16.sp,
                            color: AppTheme.lightTheme.colorScheme.secondary,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              'Aperçu visuel avec données de démonstration (aucun défi complété pour le moment).',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
