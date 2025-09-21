import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import './widgets/improved_life_domain_selection_widget.dart';
import './widgets/navigation_controls_widget.dart';
import './widgets/onboarding_page_widget.dart';
import './widgets/page_indicator_widget.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({Key? key}) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  final _authService = AuthService();

  int _currentPage = 0;
  List<String> _selectedLifeDomains = [];
  bool _isProcessing = false;

  // Registration form controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();

  final List<Map<String, dynamic>> _onboardingPages = [
    {
      "imageUrl":
          "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "title": "Bienvenue dans DailyGrowth",
      "description":
          "Votre compagnon quotidien pour le développement personnel avec des défis personnalisés et de l'inspiration IA.",
    },
    {
      "imageUrl":
          "https://images.pexels.com/photos/3184291/pexels-photo-3184291.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
      "title": "Défis Quotidiens Personnalisés",
      "description":
          "Recevez chaque jour des micro-défis adaptés à vos objectifs et domaines de vie choisis.",
    },
    {
      "imageUrl":
          "https://cdn.pixabay.com/photo/2017/08/30/01/05/milky-way-2695569_1280.jpg",
      "title": "Suivi de Progrès Gamifié",
      "description":
          "Gagnez des badges, suivez vos séries et célébrez vos réussites avec notre système de récompenses.",
    },
    // PWA Installation Tutorial Pages
    {
      "imageUrl": "assets/images/Image WhatsApp Sept 15 2025.jpeg",
      "title": "📲 Installer l'Application",
      "description":
          "Pour une expérience optimale, installez DailyGrowth sur votre écran d'accueil !",
      "isPWATutorial": true,
      "step": 1,
    },
    {
      "imageUrl": "assets/images/Image WhatsApp Sept 16 2025.jpeg", 
      "title": "📤 Étape 1 : Partager",
      "description":
          "Appuyez sur le bouton de partage dans votre navigateur Safari.",
      "isPWATutorial": true,
      "step": 2,
    },
    {
      "imageUrl": "assets/images/Image WhatsApp Sept 17 2025.jpeg",
      "title": "🏠 Étape 2 : Ajouter à l'écran",
      "description":
          "Sélectionnez 'Sur l'écran d'accueil' pour terminer l'installation.",
      "isPWATutorial": true,
      "step": 3,
    },
  ];

  // Getter pour filtrer les pages selon la plateforme
  List<Map<String, dynamic>> get _filteredOnboardingPages {
    if (kIsWeb) {
      // Sur Web, inclure toutes les pages (y compris PWA tutorial)
      return _onboardingPages;
    } else {
      // Sur mobile natif, exclure les pages PWA tutorial
      return _onboardingPages.where((page) => page["isPWATutorial"] != true).toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      await _authService.initialize();
    } catch (e) {
      debugPrint('Auth initialization error: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Haptic feedback
      HapticFeedback.lightImpact();

      if (_currentPage < _filteredOnboardingPages.length - 1) {
        // Navigate to next onboarding page
        await _pageController.nextPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else if (_currentPage == _filteredOnboardingPages.length - 1) {
        // Navigate to life domain selection page
        await _pageController.nextPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // We're on the life domain page, complete onboarding
        if (_selectedLifeDomains.isEmpty) {
          // Show a message to select at least one domain
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Veuillez sélectionner au moins un domaine de vie'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }
        await _completeOnboarding();
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _skipOnboarding() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Haptic feedback
      HapticFeedback.lightImpact();

      // Set default preferences for skipped onboarding
      _selectedLifeDomains = ['sante', 'developpement'];

      // Save preferences and navigate to home dashboard
      await _saveOnboardingPreferences();
      _navigateToHomeDashboard();
    } catch (e) {
      debugPrint('Skip onboarding error: $e');
      _navigateToHomeDashboard();
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      // Show registration form if not already registered
      if (_emailController.text.isEmpty) {
        final shouldContinue = await _showRegistrationForm();
        if (!shouldContinue) return;
      }

      // Try to register with Supabase
      if (_emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          _fullNameController.text.isNotEmpty) {
        try {
          final response = await _authService.signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            selectedLifeDomains: _selectedLifeDomains,
          );

          // Check if registration was successful
          if (response.user != null) {
            // Show email confirmation dialog
            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.mark_email_unread, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Confirmez votre email'),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Votre compte a été créé avec succès !',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 16),
                        Text('📧 Un email de confirmation a été envoyé à :'),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _emailController.text.trim(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text('⚠️ Vous devez confirmer votre email avant de pouvoir vous connecter.'),
                        SizedBox(height: 8),
                        Text(
                          'Vérifiez votre boîte mail (et les spams) puis cliquez sur le lien de confirmation.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Rediriger vers l'écran de connexion
                          Navigator.of(context).pushReplacementNamed('/login-screen');
                        },
                        child: Text('Aller à la connexion'),
                      ),
                    ],
                  );
                },
              );
            }
            return;
          } else {
            throw Exception('User creation failed');
          }
        } catch (e) {
          debugPrint('Registration error: $e');

          // Show error to user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de l\'inscription: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      // Fallback - save preferences locally and continue
      await _saveOnboardingPreferences();
      _navigateToHomeDashboard();
    } catch (e) {
      debugPrint('Complete onboarding error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la finalisation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showRegistrationForm() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Créer votre compte'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Nom complet',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
              Navigator.pushReplacementNamed(context, AppRoutes.loginScreen);
            },
            child: Text('Déjà un compte ?'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_emailController.text.isNotEmpty &&
                  _passwordController.text.isNotEmpty &&
                  _fullNameController.text.isNotEmpty) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Veuillez remplir tous les champs'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Créer le compte'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _saveOnboardingPreferences() async {
    try {
      // Save to SharedPreferences for offline access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('selected_life_domains', _selectedLifeDomains);
      await prefs.setBool('onboarding_completed', true);

      debugPrint('Onboarding preferences saved locally');
      debugPrint('Selected life domains: $_selectedLifeDomains');
      debugPrint('User registered with email: ${_emailController.text}');
      debugPrint('Full name: ${_fullNameController.text}');
    } catch (e) {
      debugPrint('Error saving onboarding preferences: $e');
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _onLifeDomainToggle(String domainId) {
    setState(() {
      if (_selectedLifeDomains.contains(domainId)) {
        _selectedLifeDomains.remove(domainId);
      } else {
        _selectedLifeDomains.add(domainId);
      }
    });

    // Haptic feedback
    HapticFeedback.selectionClick();
  }

  bool get _canProceedFromLifeDomains => _selectedLifeDomains.isNotEmpty;

  bool get _isLifeDomainPage => _currentPage == _filteredOnboardingPages.length;

  bool get _isLastPage => _currentPage == _filteredOnboardingPages.length;

  void _navigateToHomeDashboard() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.homeDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages =
        _filteredOnboardingPages.length + 1; // +1 for life domain selection

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: totalPages,
              itemBuilder: (context, index) {
                if (index < _filteredOnboardingPages.length) {
                  final pageData = _filteredOnboardingPages[index];
                  return OnboardingPageWidget(
                    imageUrl: pageData["imageUrl"] as String,
                    title: pageData["title"] as String,
                    description: pageData["description"] as String,
                    isLastPage: false,
                    isPWATutorial: pageData["isPWATutorial"] as bool? ?? false,
                    step: pageData["step"] as int?,
                  );
                } else {
                  // Life domain selection page
                  return ImprovedLifeDomainSelectionWidget(
                    selectedDomains: _selectedLifeDomains,
                    onDomainToggle: _onLifeDomainToggle,
                  );
                }
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Column(
              children: [
                if (!_isLifeDomainPage)
                  PageIndicatorWidget(
                    currentPage: _currentPage,
                    totalPages: _filteredOnboardingPages.length,
                  ),
                SizedBox(height: 2.h),
                NavigationControlsWidget(
                  isLastPage: _isLastPage,
                  isLifeDomainPage: _isLifeDomainPage,
                  canProceed: _canProceedFromLifeDomains,
                  isProcessing: _isProcessing,
                  onNext: _nextPage,
                  onSkip: _skipOnboarding,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
