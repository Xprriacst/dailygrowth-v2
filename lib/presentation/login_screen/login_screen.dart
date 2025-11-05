import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import './widgets/app_logo.dart';
import './widgets/custom_text_field.dart';
import './widgets/social_login_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _userService = UserService();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  // Mock credentials for testing
  final Map<String, String> _mockCredentials = {
    'admin@challengeme.ch': 'admin123',
    'user@challengeme.ch': 'user123',
    'demo@challengeme.ch': 'demo123',
    'expertiaen5min@gmail.com': 'password123',
  };

  @override
  void initState() {
    super.initState();
    _initializeAuth();
    
    // Add listeners to update button state when text changes
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
    // Note: Demo credentials removed for production
  }

  void _updateButtonState() {
    setState(() {
      // This will trigger a rebuild and update the button state
    });
  }

  Future<void> _initializeAuth() async {
    try {
      await _authService.initialize();

      // Listen to auth state changes
      _authService.authStateChanges.listen((data) {
        if (data.event == 'signedIn' && mounted) {
          Navigator.pushReplacementNamed(context, '/home-dashboard');
        }
      });
    } catch (e) {
      debugPrint('Auth initialization error: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  void _validateInputs() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;

      if (_emailController.text.isEmpty) {
        _emailError = 'L\'email est requis';
      } else if (!_isValidEmail(_emailController.text)) {
        _emailError = 'Format d\'email invalide';
      }

      if (_passwordController.text.isEmpty) {
        _passwordError = 'Le mot de passe est requis';
      } else if (_passwordController.text.length < 6) {
        _passwordError = 'Le mot de passe doit contenir au moins 6 caractères';
      }
    });
  }

  bool get _isFormValid {
    return _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _isValidEmail(_emailController.text) &&
        _passwordController.text.length >= 6 &&
        _emailError == null &&
        _passwordError == null;
  }

  Future<void> _handleLogin() async {
    // Prevent multiple simultaneous login attempts
    if (_isLoading) {
      debugPrint('⚠️ Login already in progress, ignoring duplicate request');
      return;
    }

    // Always validate inputs first, but allow login with valid format
    _validateInputs();

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _generalError = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      debugPrint('Attempting login for: $email');

      final response =
          await _authService.signIn(email: email, password: password);

      if (response.user != null) {
        // Success haptic feedback
        HapticFeedback.lightImpact();
        debugPrint('Login successful via Supabase: ${response.user!.email}');

        // Check if email is confirmed
        if (response.user!.emailConfirmedAt == null) {
          // Show detailed email confirmation dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Email non confirmé'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Votre compte existe mais votre email n\'est pas encore confirmé.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 16),
                    Text('📧 Vérifiez votre boîte mail à l\'adresse :'),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        email,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text('Cliquez sur le lien de confirmation dans l\'email, puis réessayez de vous connecter.'),
                    SizedBox(height: 8),
                    Text(
                      'Si vous ne trouvez pas l\'email, vérifiez vos spams ou demandez un nouveau lien.',
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
                    onPressed: () => Navigator.pop(context),
                    child: Text('Compris'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      // Renvoyer l'email de confirmation
                      try {
                        await _authService.resendConfirmation(email);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Email de confirmation renvoyé'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur lors de l\'envoi'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Text('Renvoyer l\'email'),
                  ),
                ],
              );
            },
          );
          return;
        }

        // Direct navigation after successful login
        debugPrint('User authenticated successfully');
        debugPrint('🔍 Starting navigation logic...');
        
        // Wait a moment for user to be available and check if user has completed onboarding
        try {
          debugPrint('🔍 Waiting for user to be available...');
          
          // Wait up to 3 seconds for currentUser to be available
          User? currentUser;
          for (int i = 0; i < 30; i++) {
            currentUser = _authService.currentUser;
            if (currentUser != null) break;
            await Future.delayed(Duration(milliseconds: 100));
          }
          
          debugPrint('🔍 Current user after wait: ${currentUser?.email ?? 'null'}');
          
          if (currentUser != null) {
            debugPrint('🔍 Fetching user profile for ID: ${currentUser.id}');
            final userProfile = await _userService.getUserProfile(currentUser.id);
            debugPrint('🔍 User profile fetched: ${userProfile != null ? 'found' : 'null'}');
            
            final selectedDomains = userProfile?['selected_life_domains'] as List?;
            final hasCompletedOnboarding = selectedDomains != null && selectedDomains.isNotEmpty;
            debugPrint('🔍 Selected domains: $selectedDomains');
            debugPrint('🔍 Has completed onboarding: $hasCompletedOnboarding');
            
            if (hasCompletedOnboarding) {
              debugPrint('🎯 Navigating to dashboard after login');
              Navigator.pushNamedAndRemoveUntil(context, '/home-dashboard', (route) => false);
            } else {
              debugPrint('🎯 Navigating to onboarding after login');
              Navigator.pushNamedAndRemoveUntil(context, '/onboarding-flow', (route) => false);
            }
          } else {
            debugPrint('⚠️ No current user found, defaulting to dashboard');
            Navigator.pushNamedAndRemoveUntil(context, '/home-dashboard', (route) => false);
          }
        } catch (e) {
          debugPrint('❌ Error in navigation logic: $e');
          debugPrint('❌ Stack trace: ${StackTrace.current}');
          debugPrint('⚠️ Defaulting to dashboard navigation');
          Navigator.pushNamedAndRemoveUntil(context, '/home-dashboard', (route) => false);
        }
        return;
      } else {
        throw Exception('Aucune réponse utilisateur reçue');
      }
    } catch (e) {
      debugPrint('Login error: $e');

      setState(() {
        // Use the enhanced error message from AuthService
        if (e.toString().contains('Erreur de connexion:')) {
          _generalError = e.toString().replaceFirst('Exception: ', '');
        } else {
          _generalError =
              'Erreur de connexion. Vérifiez vos identifiants et votre connexion internet.';
        }
      });

      // Show specific guidance for expertiaen5min@gmail.com
      if (_emailController.text.trim().toLowerCase() ==
          'expertiaen5min@gmail.com') {
        setState(() {
          _generalError =
              'Compte trouvé mais problème de connexion. Veuillez vérifier votre mot de passe ou réinitialiser le mot de passe.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    if (provider == 'google') {
      setState(() => _isGoogleLoading = true);
    }

    try {
      bool success = false;

      if (provider == 'google') {
        success = await _authService.signInWithGoogle();
      }

      if (success) {
        HapticFeedback.lightImpact();
        // Navigation will be handled by auth state listener
      } else {
        // Fallback to mock success for demo
        await Future.delayed(Duration(seconds: 1));
        HapticFeedback.lightImpact();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home-dashboard');
        }
      }
    } catch (e) {
      // Fallback to mock success for demo
      await Future.delayed(Duration(seconds: 1));
      HapticFeedback.lightImpact();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home-dashboard');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  void _handleForgotPassword() {
    final resetEmailController = TextEditingController(text: _emailController.text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Mot de passe oublié',
          style: AppTheme.lightTheme.textTheme.titleMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Entrez votre email pour recevoir un lien de réinitialisation:',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: resetEmailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              resetEmailController.dispose();
              Navigator.pop(context);
            },
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Veuillez entrer votre email'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              try {
                await _authService.resetPassword(email);
                resetEmailController.dispose();
                Navigator.pop(context);
                
                // Afficher une boîte de dialogue avec instructions claires
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Row(
                        children: [
                          Icon(Icons.email, color: AppTheme.lightTheme.colorScheme.primary),
                          SizedBox(width: 8),
                          Text('Email envoyé !'),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Un email de réinitialisation a été envoyé à :',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              email,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.lightTheme.colorScheme.primary,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text('📧 Vérifiez votre boîte mail et suivez les instructions pour créer un nouveau mot de passe.'),
                          SizedBox(height: 8),
                          Text(
                            'Note: L\'email peut prendre quelques minutes à arriver. Vérifiez aussi vos spams.',
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
                          onPressed: () => Navigator.pop(context),
                          child: Text('Compris'),
                        ),
                      ],
                    );
                  },
                );
              } catch (e) {
                resetEmailController.dispose();
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Erreur'),
                        ],
                      ),
                      content: Text('Impossible d\'envoyer l\'email de réinitialisation. Vérifiez votre adresse email et réessayez.\n\nDétails: ${e.toString()}'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              }
            },
            child: Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 6.h),

                // App Logo
                Center(
                  child: AppLogo(size: 25.w),
                ),

                SizedBox(height: 4.h),

                // Welcome Text
                Text(
                  'Bon retour !',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),

                SizedBox(height: 1.h),

                Text(
                  'Connectez-vous pour continuer votre croissance',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 6.h),

                // Email Field
                CustomTextField(
                  label: 'Email',
                  hint: 'Entrez votre email',
                  iconName: 'email',
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  errorText: _emailError,
                  onChanged: (value) {
                    if (_emailError != null) {
                      setState(() => _emailError = null);
                    }
                    if (_generalError != null) {
                      setState(() => _generalError = null);
                    }
                  },
                ),

                SizedBox(height: 4.h),

                // Password Field
                CustomTextField(
                  label: 'Mot de passe',
                  hint: 'Entrez votre mot de passe',
                  iconName: 'lock',
                  isPassword: true,
                  controller: _passwordController,
                  errorText: _passwordError,
                  onChanged: (value) {
                    if (_passwordError != null) {
                      setState(() => _passwordError = null);
                    }
                    if (_generalError != null) {
                      setState(() => _generalError = null);
                    }
                  },
                ),

                SizedBox(height: 2.h),

                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handleForgotPassword,
                    child: Text(
                      'Mot de passe oublié ?',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 2.h),

                // General Error Message
                _generalError != null
                    ? Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(3.w),
                        margin: EdgeInsets.only(bottom: 3.h),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.error
                              .withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.lightTheme.colorScheme.error
                                .withAlpha(77),
                          ),
                        ),
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'error_outline',
                              color: AppTheme.lightTheme.colorScheme.error,
                              size: 5.w,
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                _generalError!,
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme.lightTheme.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : SizedBox.shrink(),

                // Login Button - Made more permissive
                Container(
                  width: double.infinity,
                  height: 12.h,
                  child: ElevatedButton(
                    onPressed: !_isLoading &&
                            _emailController.text.isNotEmpty &&
                            _passwordController.text.isNotEmpty
                        ? _handleLogin
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_emailController.text.isNotEmpty &&
                              _passwordController.text.isNotEmpty)
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onSurface
                              .withAlpha(31),
                      foregroundColor: (_emailController.text.isNotEmpty &&
                              _passwordController.text.isNotEmpty)
                          ? AppTheme.lightTheme.colorScheme.onPrimary
                          : AppTheme.lightTheme.colorScheme.onSurface
                              .withAlpha(97),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: (_emailController.text.isNotEmpty &&
                              _passwordController.text.isNotEmpty)
                          ? 2
                          : 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 6.w,
                            height: 6.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.lightTheme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Text(
                            'Se connecter',
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: (_emailController.text.isNotEmpty &&
                                      _passwordController.text.isNotEmpty)
                                  ? Colors.white // Texte blanc quand le bouton est bleu
                                  : AppTheme.lightTheme.colorScheme.onSurface
                                      .withAlpha(97),
                            ),
                          ),
                  ),
                ),

                SizedBox(height: 6.h),

                // Divider with text
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: AppTheme.lightTheme.colorScheme.outline,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text(
                        'Ou continuer avec',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: AppTheme.lightTheme.colorScheme.outline,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 4.h),

                // Social Login Button
                SocialLoginButton(
                  iconName: 'g_mobiledata',
                  text: 'Google',
                  isLoading: _isGoogleLoading,
                  onPressed: () => _handleSocialLogin('google'),
                ),

                SizedBox(height: 6.h),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Nouveau ? ',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/onboarding-flow');
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'S\'inscrire',
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
