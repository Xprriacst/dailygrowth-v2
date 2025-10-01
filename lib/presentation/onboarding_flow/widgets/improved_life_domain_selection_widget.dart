import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/app_export.dart';
import '../../../models/challenge_problematique.dart';
import '../../../services/n8n_challenge_service.dart';
import '../../../services/user_service.dart';

class ImprovedLifeDomainSelectionWidget extends StatefulWidget {
  final List<String> selectedDomains;
  final Function(String) onDomainToggle;

  const ImprovedLifeDomainSelectionWidget({
    Key? key,
    required this.selectedDomains,
    required this.onDomainToggle,
  }) : super(key: key);

  @override
  State<ImprovedLifeDomainSelectionWidget> createState() => _ImprovedLifeDomainSelectionWidgetState();
}

class _ImprovedLifeDomainSelectionWidgetState extends State<ImprovedLifeDomainSelectionWidget>
    with TickerProviderStateMixin {
  
  final N8nChallengeService _n8nService = N8nChallengeService();
  final UserService _userService = UserService();
  
  List<ChallengeProblematique> _selectedProblematiques = [];
  Map<String, dynamic>? _generatedChallenges;
  bool _isGenerating = false;
  String? _errorMessage;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _selectionAnimationController;
  late Animation<double> _selectionAnimation;

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
    
    _selectionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _selectionAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _selectionAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _selectionAnimationController.dispose();
    super.dispose();
  }

  void _toggleProblematique(ChallengeProblematique problematique) {
    setState(() {
      if (_selectedProblematiques.contains(problematique)) {
        _selectedProblematiques.remove(problematique);
      } else {
        // Nouvelle logique: ne permettre qu'une seule problématique
        _selectedProblematiques.clear();
        _selectedProblematiques.add(problematique);
      }
    });

    // Haptic feedback
    HapticFeedback.selectionClick();
    
    // Animation de sélection
    _selectionAnimationController.forward().then((_) {
      _selectionAnimationController.reverse();
    });

    // Automatiquement sauvegarder et activer le domaine pour permettre de continuer
    if (_selectedProblematiques.isNotEmpty) {
      _saveSelectedProblematiques();
      // Simuler la sélection d'un domaine pour activer le bouton "Commencer"
      if (widget.selectedDomains.isEmpty) {
        widget.onDomainToggle('developpement');
      }
    } else {
      // Si aucune problématique sélectionnée, désactiver
      if (widget.selectedDomains.contains('developpement')) {
        widget.onDomainToggle('developpement'); // Toggle pour désélectionner
      }
    }
  }

  Future<void> _generateChallenges() async {
    if (_selectedProblematiques.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner une problématique'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedChallenges = null;
    });

    // Haptic feedback
    HapticFeedback.lightImpact();

    try {
      // Récupérer le profil utilisateur pour connaître son niveau
      await _userService.initialize();
      final currentUser = Supabase.instance.client.auth.currentUser;
      final userId = currentUser?.id;
      
      Map<String, dynamic>? userProfile;
      int nombreDefisReleves = 0;
      
      if (userId != null) {
        try {
          userProfile = await _userService.getUserProfile(userId);
          nombreDefisReleves = userProfile?['completed_challenges_count'] ?? 0;
        } catch (e) {
          debugPrint('⚠️ Could not fetch user profile: $e');
          // Continue with default values
        }
      }

      // Utiliser la première problématique sélectionnée pour la génération
      final primaryProblematique = _selectedProblematiques.first;
      debugPrint('🎯 Generating challenges for: ${primaryProblematique.description}');
      debugPrint('📊 User completed challenges: $nombreDefisReleves');
      debugPrint('📋 Selected problematiques: ${_selectedProblematiques.map((p) => p.title).join(", ")}');

      final result = await _n8nService.generateSingleMicroChallengeWithFallback(
        problematique: primaryProblematique.description,
        nombreDefisReleves: nombreDefisReleves,
        userId: userProfile?['id'],
      );

      setState(() {
        _generatedChallenges = result;
        _isGenerating = false;
      });

      // Animation d'apparition
      _animationController.forward();

    } catch (e) {
      debugPrint('❌ Error generating challenges: $e');
      setState(() {
        _errorMessage = e.toString();
        _isGenerating = false;
      });
    }
  }

  void _resetSelection() {
    setState(() {
      _selectedProblematiques.clear();
      _generatedChallenges = null;
      _errorMessage = null;
    });
    _animationController.reset();
  }

  void _continueWithSelection() {
    if (_selectedProblematiques.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner une problématique'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Sauvegarder les problématiques sélectionnées
    _saveSelectedProblematiques();

    // Simuler la sélection d'un domaine pour continuer l'onboarding
    if (widget.selectedDomains.isEmpty) {
      widget.onDomainToggle('developpement'); // Sélectionner un domaine par défaut
    }
  }

  Future<void> _saveSelectedProblematiques() async {
    try {
      // Sauvegarder les problématiques sélectionnées dans les préférences locales
      final prefs = await SharedPreferences.getInstance();
      final selectedIds = _selectedProblematiques.map((p) => p.id).toList();
      final selectedDescriptions = _selectedProblematiques.map((p) => p.description).toList();
      
      await prefs.setStringList('selected_problematiques_ids', selectedIds);
      await prefs.setStringList('selected_problematiques', selectedDescriptions);
      
      // NOUVEAU: Sauvegarder aussi dans Supabase
      await _saveToSupabase(selectedDescriptions);
      
      debugPrint('✅ Problématiques sauvegardées localement et dans Supabase: ${selectedDescriptions.join(", ")}');
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde des problématiques: $e');
    }
  }

  Future<void> _saveToSupabase(List<String> selectedDescriptions) async {
    try {
      await _userService.initialize();
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      if (currentUser != null) {
        debugPrint('🔄 Tentative de sauvegarde Supabase pour user: ${currentUser.id}');
        debugPrint('📝 Problématiques à sauvegarder: $selectedDescriptions');
        
        await _userService.updateUserProfile(
          userId: currentUser.id,
          selectedProblematiques: selectedDescriptions,
        );
        debugPrint('✅ Problématiques synchronisées avec Supabase');
        
        // Vérification immédiate
        final profile = await _userService.getUserProfile(currentUser.id);
        debugPrint('🔍 Vérification post-sauvegarde: ${profile?["selected_problematiques"]}');
      } else {
        debugPrint('⚠️ Utilisateur non connecté, sauvegarde locale uniquement');
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la synchronisation Supabase: $e');
      // Continue même si la synchronisation échoue
    }
  }

  Widget _buildProblematiqueCard(ChallengeProblematique problematique) {
    final isSelected = _selectedProblematiques.contains(problematique);
    final isDisabled = _selectedProblematiques.isNotEmpty && !isSelected;
    
    return AnimatedBuilder(
      animation: _selectionAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isSelected ? _selectionAnimation.value : 1.0,
          child: GestureDetector(
            onTap: () => _toggleProblematique(problematique),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(bottom: 2.h),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.5.h),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.lightTheme.colorScheme.primary.withOpacity(0.15)
                    : isDisabled
                        ? AppTheme.lightTheme.colorScheme.surface.withOpacity(0.5)
                        : AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected 
                      ? AppTheme.lightTheme.colorScheme.primary
                      : isDisabled
                          ? AppTheme.lightTheme.colorScheme.outline.withOpacity(0.1)
                          : AppTheme.lightTheme.colorScheme.outline.withOpacity(0.2),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected 
                        ? AppTheme.lightTheme.colorScheme.primary.withOpacity(0.2)
                        : isDisabled
                            ? AppTheme.lightTheme.colorScheme.shadow.withOpacity(0.02)
                            : AppTheme.lightTheme.colorScheme.shadow.withOpacity(0.08),
                    blurRadius: isSelected ? 12 : 8,
                    offset: const Offset(0, 2),
                    spreadRadius: isSelected ? 1 : 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Emoji avec animation
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(isSelected ? 1.w : 0),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Opacity(
                      opacity: isDisabled ? 0.3 : 1.0,
                      child: Text(
                        problematique.emoji,
                        style: TextStyle(
                          fontSize: isSelected ? 20.sp : 18.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  
                  // Titre
                  Expanded(
                    child: Opacity(
                      opacity: isDisabled ? 0.3 : 1.0,
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
                  ),
                  
                  // Icône de sélection
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Opacity(
                      opacity: isDisabled ? 0.3 : 1.0,
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isSelected 
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.lightTheme.colorScheme.outline,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategorySection(String category, List<ChallengeProblematique> problematiques) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de la catégorie avec design amélioré
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
        
        // Liste des problématiques
        ...problematiques.map((problematique) => _buildProblematiqueCard(problematique)).toList(),
        
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
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header amélioré
          if (_generatedChallenges == null) ...[
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
                          Icons.psychology,
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          'Choisissez vos objectifs',
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
                    'Sélectionnez la problématique principale sur laquelle vous souhaitez travailler. Nous générerons des défis personnalisés pour vous aider à progresser.',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),
                  if (_selectedProblematiques.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '1 objectif sélectionné',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Sélection des problématiques par catégorie
          if (_generatedChallenges == null) ...[
            ...ChallengeProblematique.allCategories.map((category) {
              final problematiques = ChallengeProblematique.getByCategory(category);
              return _buildCategorySection(category, problematiques);
            }).toList(),
            
            // Message d'instruction quand aucune sélection
            if (_selectedProblematiques.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(3.w),
                margin: EdgeInsets.symmetric(vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.6),
                      size: 20.sp,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        'Sélectionnez une problématique pour continuer',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          // Résultats générés (conservé de l'ancienne version)
          if (_generatedChallenges != null) ...[
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _resetSelection,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Choisir d\'autres objectifs'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.lightTheme.colorScheme.surface,
                            foregroundColor: AppTheme.lightTheme.colorScheme.onSurface,
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _continueWithSelection,
                          icon: const Icon(Icons.check),
                          label: const Text('Continuer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                            foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 4.h),
        ],
      ),
    );
  }
}
