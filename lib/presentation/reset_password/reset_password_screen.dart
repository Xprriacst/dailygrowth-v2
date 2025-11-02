import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? token;
  final String? type;

  const ResetPasswordScreen({
    Key? key,
    this.token,
    this.type,
  }) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _handlePasswordRecovery();
  }

  Future<void> _handlePasswordRecovery() async {
    // Supabase gère automatiquement les hash fragments (#access_token=...)
    // On attend que la session soit établie
    await Future.delayed(const Duration(milliseconds: 1000));
    
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      debugPrint('✅ Session de récupération établie pour: ${session.user.email}');
      Fluttertoast.showToast(
        msg: "Vous pouvez maintenant définir votre nouveau mot de passe",
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
      );
    } else {
      debugPrint('⚠️ Aucune session trouvée - vérifiez le lien de réinitialisation');
      // Ne pas afficher d'erreur ici car l'utilisateur peut arriver directement sur la page
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      Fluttertoast.showToast(
        msg: "Les mots de passe ne correspondent pas",
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.updatePassword(newPassword: _passwordController.text);
      
      Fluttertoast.showToast(
        msg: "Mot de passe mis à jour avec succès !",
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      // Rediriger vers l'écran de connexion
      Navigator.of(context).pushReplacementNamed(AppRoutes.loginScreen);
      
    } catch (error) {
      Fluttertoast.showToast(
        msg: "Erreur: ${error.toString()}",
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Nouveau mot de passe',
          style: AppTheme.headingStyle,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.loginScreen),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 4.h),
                
                // Titre et description
                Text(
                  'Définir un nouveau mot de passe',
                  style: AppTheme.headingStyle.copyWith(fontSize: 20.sp),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 2.h),
                
                Text(
                  'Choisissez un mot de passe sécurisé pour votre compte ChallengeMe.',
                  style: AppTheme.bodyStyle,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),

                // Champ mot de passe
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    hintText: 'Entrez votre nouveau mot de passe',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un mot de passe';
                    }
                    if (value.length < 8) {
                      return 'Le mot de passe doit contenir au moins 8 caractères';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 3.h),

                // Champ confirmation mot de passe
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    hintText: 'Confirmez votre nouveau mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez confirmer votre mot de passe';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 4.h),

                // Bouton de mise à jour
                ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Mettre à jour le mot de passe',
                          style: AppTheme.buttonTextStyle,
                        ),
                ),
                SizedBox(height: 3.h),

                // Lien retour connexion
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.loginScreen),
                  child: Text(
                    'Retour à la connexion',
                    style: AppTheme.linkStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
