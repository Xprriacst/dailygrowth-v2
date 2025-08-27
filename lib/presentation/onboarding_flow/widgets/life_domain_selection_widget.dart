import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/app_export.dart';
import '../../../models/challenge_problematique.dart';
import '../../../services/n8n_challenge_service.dart';
import '../../../services/user_service.dart';
import '../../challenge_selection/widgets/problematique_category_widget.dart';
import '../../challenge_selection/widgets/micro_challenge_card_widget.dart';

class LifeDomainSelectionWidget extends StatefulWidget {
  final List<String> selectedDomains;
  final Function(String) onDomainToggle;

  const LifeDomainSelectionWidget({
    Key? key,
    required this.selectedDomains,
    required this.onDomainToggle,
  }) : super(key: key);

  @override
  State<LifeDomainSelectionWidget> createState() => _LifeDomainSelectionWidgetState();
}

class _LifeDomainSelectionWidgetState extends State<LifeDomainSelectionWidget>
    with TickerProviderStateMixin {
  
  final N8nChallengeService _n8nService = N8nChallengeService();
  final UserService _userService = UserService();
  
  ChallengeProblematique? _selectedProblematique;
  Map<String, dynamic>? _generatedChallenges;
  bool _isGenerating = false;
  String? _errorMessage;
  
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _generateChallenges(ChallengeProblematique problematique) async {
    setState(() {
      _selectedProblematique = problematique;
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

      debugPrint('🎯 Generating challenges for: ${problematique.description}');
      debugPrint('📊 User completed challenges: $nombreDefisReleves');

      final result = await _n8nService.generateMicroChallengesWithFallback(
        problematique: problematique.description,
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
      _selectedProblematique = null;
      _generatedChallenges = null;
      _errorMessage = null;
    });
    _animationController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (_selectedProblematique == null) ...[
            Text(
              'Je veux...',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 4.h),
          ],

          // Sélection des problématiques par catégorie
          if (_selectedProblematique == null) ...[
            ...ChallengeProblematique.allCategories.map((category) {
              final problematiques = ChallengeProblematique.getByCategory(category);
              return Column(
                children: [
                  ProblematiqueCategory(
                    title: category,
                    problematiques: problematiques,
                    onProblematiqueTap: _generateChallenges,
                  ),
                  SizedBox(height: 3.h),
                ],
              );
            }).toList(),
          ],

          // État de génération
          if (_isGenerating) ...[
            SizedBox(height: 4.h),
            Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Génération de vos micro-défis...',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Problématique: ${_selectedProblematique?.title}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],

          // Résultats générés
          if (_generatedChallenges != null) ...[
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header des résultats
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _selectedProblematique?.emoji ?? '🎯',
                              style: TextStyle(fontSize: 24.sp),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Text(
                                _selectedProblematique?.title ?? 'Objectif sélectionné',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.lightTheme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Niveau détecté: ${_generatedChallenges!['niveau_detecte'] ?? 'Non défini'}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_generatedChallenges!['source'] == 'fallback_local') ...[
                          SizedBox(height: 1.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '⚠️ Défis générés localement (service n8n indisponible)',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.orange[800],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Liste des micro-défis
                  Text(
                    'Vos micro-défis personnalisés',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // Cartes des défis
                  ...(_generatedChallenges!['defis'] as List).map((defi) {
                    return Column(
                      children: [
                        MicroChallengeCard(
                          numero: defi['numero'] ?? 0,
                          nom: defi['nom'] ?? 'Défi sans nom',
                          mission: defi['mission'] ?? 'Mission non définie',
                          pourquoi: defi['pourquoi'] ?? 'Raison non précisée',
                          bonus: defi['bonus'],
                          dureeEstimee: defi['duree_estimee'] ?? '15',
                          onCompleted: () {
                            HapticFeedback.lightImpact();
                          },
                        ),
                        SizedBox(height: 2.h),
                      ],
                    );
                  }).toList(),

                  SizedBox(height: 4.h),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _resetSelection,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Choisir un autre objectif'),
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
                          onPressed: () {
                            // Simuler la sélection d'un domaine pour continuer l'onboarding
                            if (widget.selectedDomains.isEmpty) {
                              widget.onDomainToggle('sante'); // Sélectionner un domaine par défaut
                            }
                          },
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
