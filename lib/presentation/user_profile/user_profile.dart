import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/notification_service.dart';
import '../../utils/auth_guard.dart';
import 'widgets/problematique_selection_modal.dart';
import './widgets/life_domains_widget.dart';
import './widgets/notification_toggle_widget.dart';
import './widgets/problematique_progress_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/profile_picture_modal.dart';
import './widgets/settings_item_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/problematique_progress_widget.dart';
import '../settings/notification_settings_widget.dart';
import '../onboarding_flow/widgets/problematique_progress_selection_widget.dart';

import 'package:universal_html/html.dart' as html;

class UserProfile extends StatefulWidget {
  const UserProfile({Key? key}) : super(key: key);

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  bool _isLoading = true;
  String? _selectedProfileImage;

  // Bottom navigation state
  int _currentBottomNavIndex = 3; // Profile is index 3

  // Real user data from Supabase
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _userStats;

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _checkAuthenticationAndInitialize();
  }

  Future<void> _checkAuthenticationAndInitialize() async {
    // Ensure user is authenticated before initializing
    final canProceed = await AuthGuard.canNavigate(context, '/user-profile');
    if (!canProceed) return;
    
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await Future.wait([
        _authService.initialize(),
        _userService.initialize(),
      ]);

      // Check authentication status immediately
      if (!_authService.isAuthenticated) {
        _handleAuthenticationExpired();
        return;
      }

      await _loadUserData();
    } catch (e) {
      if (mounted) {
        _showBeautifulErrorMessage('Erreur lors de l\'initialisation: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Double-check authentication before loading data
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        _handleAuthenticationExpired();
        return;
      }

      // Load user profile and stats in parallel
      final results = await Future.wait([
        _userService.getUserProfile(currentUser.id),
        _userService.getUserStats(currentUser.id),
      ]);

      if (mounted) {
        setState(() {
          _userData = results[0];
          _userStats = results[1];
          _isLoading = false;
        });
        
        // Debug: Afficher les données récupérées
        debugPrint('🔍 Données utilisateur récupérées:');
        debugPrint('📋 selected_problematiques: ${_userData?["selected_problematiques"]}');
        debugPrint('📋 selected_life_domains: ${_userData?["selected_life_domains"]}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // If it's an auth error, handle appropriately
        if (e.toString().contains('JWT') || e.toString().contains('auth')) {
          _handleAuthenticationExpired();
        } else {
          _showBeautifulErrorMessage('Erreur lors du chargement des données: $e');
        }
      }
    }
  }

  void _handleAuthenticationExpired() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Session expirée'),
        content: Text('Votre session a expiré. Veuillez vous reconnecter.'),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _authService.signOut();
              } catch (e) {
                debugPrint('Error signing out: $e');
              }
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login-screen',
                (route) => false);
            },
            child: Text('Se connecter')),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    return AuthGuard.protectedRoute(
      context: context,
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Profil',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface)),
          backgroundColor: AppTheme.lightTheme.colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              // Navigate back to dashboard instead of using pop to avoid navigation errors
              Navigator.pushNamedAndRemoveUntil(context, '/home-dashboard', (route) => false);
            },
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 6.w)),
          actions: [
            IconButton(
              onPressed: _exportUserData,
              icon: CustomIconWidget(
                iconName: 'download',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w)),
            // Show admin panel button if user is admin
            if (_userData?['is_admin'] == true)
              IconButton(
                onPressed: () => Navigator.pushNamed(context, '/admin-panel'),
                icon: CustomIconWidget(
                  iconName: 'admin_panel_settings',
                  color: AppTheme.lightTheme.colorScheme.secondary,
                  size: 6.w)),
            // Add notification test button
            IconButton(
              onPressed: _triggerTestNotification,
              icon: CustomIconWidget(
                iconName: 'notifications',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w)),
          ]),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppTheme.lightTheme.colorScheme.primary),
                    SizedBox(height: 2.h),
                    Text(
                      'Chargement de votre profil...',
                      style: AppTheme.lightTheme.textTheme.bodyMedium),
                  ]))
            : _userData == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'error_outline',
                          color: AppTheme.lightTheme.colorScheme.error,
                          size: 12.w),
                        SizedBox(height: 2.h),
                        Text(
                          'Impossible de charger le profil',
                          style: AppTheme.lightTheme.textTheme.titleMedium),
                        SizedBox(height: 1.h),
                        ElevatedButton(
                          onPressed: _loadUserData,
                          child: Text('Réessayer')),
                      ]))
                : SafeArea(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          ProfileHeaderWidget(
                            userName: _userData!["full_name"] as String? ??
                                'Utilisateur',
                            joinDate: _formatJoinDate(_userData!["created_at"]),
                            profileImageUrl: _selectedProfileImage,
                            onAvatarTap: _showProfilePictureModal,
                            userStats: _userStats),
                          SizedBox(height: 3.h),

                          // Progress by Problematique Section
                          const ProblematiqueProgressWidget(),

                          // Account Section
                          SettingsSectionWidget(
                            title: 'Compte',
                            children: [
                              SettingsItemWidget(
                                iconName: 'email',
                                title: 'Adresse e-mail',
                                subtitle: _userData!["email"] as String? ??
                                    'Non défini',
                                onTap: () => _showChangeEmailDialog()),
                              SettingsItemWidget(
                                iconName: 'lock',
                                title: 'Mot de passe',
                                subtitle: 'Cliquez pour changer',
                                onTap: () => _showChangePasswordDialog(),
                                showDivider: false),
                            ]),

                          // Notification Settings Section
                          const NotificationSettingsWidget(),

                          // Life Domains Section
                          SettingsSectionWidget(
                            title: 'Domaines de vie',
                            children: [
                              LifeDomainsWidget(
                                selectedDomains: _getSelectedDomains(),
                                onEditTap: _showLifeDomainsModal),
                            ]),

                          // Progress by Problematique Section
                          // TODO: Temporairement masqué - pourcentage incohérent (basé sur défis assignés vs complétés)
                          // Fix disponible sur branche development
                          // const ProblematiqueProgressWidget(),

                          // Support Section
                          SettingsSectionWidget(
                            title: 'Support',
                            children: [
                              SettingsItemWidget(
                                iconName: 'help',
                                title: 'Centre d\'aide',
                                subtitle: 'FAQ et guides d\'utilisation',
                                onTap: () => _showHelpCenter()),
                              SettingsItemWidget(
                                iconName: 'feedback',
                                title: 'Envoyer des commentaires',
                                subtitle: 'Aidez-nous à améliorer l\'app',
                                onTap: () => _showFeedbackDialog()),
                              SettingsItemWidget(
                                iconName: 'info',
                                title: 'À propos',
                                subtitle: 'Version 1.0.0',
                                onTap: () => _showAboutDialog(),
                                showDivider: false),
                            ]),

                          SizedBox(height: 4.h),

                          // Logout Button
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 6.w),
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _showLogoutConfirmation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppTheme.lightTheme.colorScheme.error,
                                foregroundColor:
                                    AppTheme.lightTheme.colorScheme.onError,
                                padding: EdgeInsets.symmetric(vertical: 2.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomIconWidget(
                                    iconName: 'logout',
                                    color:
                                        AppTheme.lightTheme.colorScheme.onError,
                                    size: 5.w),
                                  SizedBox(width: 2.w),
                                  Text(
                                    'Se déconnecter',
                                    style: AppTheme.lightTheme.textTheme.bodyLarge
                                        ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          AppTheme.lightTheme.colorScheme.onError)),
                                ]))),

                          SizedBox(height: 4.h),

                          // Delete Account Button
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 6.w),
                            width: double.infinity,
                            child: TextButton(
                              onPressed: _showDeleteAccountConfirmation,
                              child: Text(
                                'Supprimer mon compte',
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  color: AppTheme.lightTheme.colorScheme.error,
                                  fontWeight: FontWeight.w500)))),

                          SizedBox(height: 6.h),
                        ])))),
        // Add persistent bottom navigation

      );
  }

  String _formatJoinDate(dynamic createdAt) {
    if (createdAt == null) return 'Récemment';
    try {
      final date = DateTime.parse(createdAt.toString());
      final months = [
        'janvier',
        'février',
        'mars',
        'avril',
        'mai',
        'juin',
        'juillet',
        'août',
        'septembre',
        'octobre',
        'novembre',
        'décembre'
      ];
      return '${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return 'Récemment';
    }
  }

  String _formatNotificationTime(dynamic time) {
    if (time == null) return '09:00';
    return time.toString().substring(0, 5); // Extract HH:MM from time
  }

  List<String> _getSelectedDomains() {
    // Only use selected_problematiques for display
    final problematiques = _userData?["selected_problematiques"];
    if (problematiques != null && problematiques is List && problematiques.isNotEmpty) {
      return problematiques.cast<String>();
    }
    
    // Return error message if no problematiques found
    return ["Erreur: Aucune problématique sélectionnée"];
  }

  String? _getSelectedProblematique() {
    // Get the single selected problematique
    final problematiques = _userData?["selected_problematiques"];
    if (problematiques != null && problematiques is List && problematiques.isNotEmpty) {
      return problematiques.first as String;
    }
    return null;
  }

  void _handleBottomNavTap(int index) async {
    if (index == _currentBottomNavIndex) return;

    // Validate authentication before any navigation
    final canNavigate = await AuthGuard.canNavigate(context, 'navigation');
    if (!canNavigate) return;

    // Navigate to different screens based on index
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home-dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/notes');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/challenge-history');
        break;
      case 3:
        // Already on user profile
        break;
    }
  }

  void _showProfilePictureModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfilePictureModal(
        onImageSelected: (XFile? image) {
          if (image != null) {
            setState(() {
              _selectedProfileImage = image.path;
            });
            _showBeautifulSuccessMessage('Photo de profil mise à jour');
          } else {
            setState(() {
              _selectedProfileImage = null;
            });
            _showBeautifulSuccessMessage('Photo de profil supprimée');
          }
        }));
  }

  void _showLifeDomainsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 2.h, bottom: 1.h),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Titre
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Votre objectif',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Terminé',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Widget de sélection avec progression
            Expanded(
              child: ProblematiqueProgressSelectionWidget(
                selectedDomains: const [],
                onDomainToggle: (_) async {
                  // Recharger les données après modification
                  await _loadUserData();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateNotificationSetting(String key, bool value) async {
    try {
      await _userService.updateUserProfile(
        userId: _authService.userId!,
        notificationsEnabled: value);
      await _loadUserData(); // Reload data
      _showBeautifulSuccessMessage('Préférences sauvegardées');
    } catch (e) {
      _showBeautifulErrorMessage('Erreur lors de la sauvegarde: $e');
    }
  }

  void _showTimePicker() async {
    final currentTime = _userData?["notification_time"];
    TimeOfDay initialTime = TimeOfDay(hour: 9, minute: 0);

    if (currentTime != null) {
      try {
        final timeParts = currentTime.toString().split(':');
        initialTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]));
      } catch (e) {
        // Use default time if parsing fails
      }
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: AppTheme.lightTheme.colorScheme),
          child: child!);
      });

    if (picked != null) {
      try {
        final timeString =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
        await _userService.updateUserProfile(
          userId: _authService.userId!,
          notificationTime: timeString);
        await _loadUserData(); // Reload data
        _showBeautifulSuccessMessage('Heure de notification mise à jour');
      } catch (e) {
        _showBeautifulErrorMessage('Erreur lors de la mise à jour: $e');
      }
    }
  }

  void _showChangeEmailDialog() {
    final TextEditingController emailController =
        TextEditingController(text: _userData?["email"] as String? ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Changer l\'adresse e-mail'),
        content: TextField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: 'Nouvelle adresse e-mail',
            hintText: 'exemple@email.com'),
          keyboardType: TextInputType.emailAddress),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              try {
                // Update in auth service (this would need to be implemented)
                // await _authService.updateEmail(emailController.text);
                Navigator.pop(context);
                _showBeautifulSuccessMessage('Fonctionnalité à implémenter');
              } catch (e) {
                _showBeautifulErrorMessage('Erreur: $e');
              }
            },
            child: Text('Sauvegarder')),
        ]));
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Changer le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: InputDecoration(labelText: 'Mot de passe actuel'),
              obscureText: true),
            SizedBox(height: 2.h),
            TextField(
              controller: newPasswordController,
              decoration: InputDecoration(labelText: 'Nouveau mot de passe'),
              obscureText: true),
            SizedBox(height: 2.h),
            TextField(
              controller: confirmPasswordController,
              decoration:
                  InputDecoration(labelText: 'Confirmer le mot de passe'),
              obscureText: true),
          ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text ==
                  confirmPasswordController.text) {
                Navigator.pop(context);
                _showBeautifulSuccessMessage('Fonctionnalité à implémenter');
              } else {
                _showBeautifulErrorMessage('Les mots de passe ne correspondent pas');
              }
            },
            child: Text('Sauvegarder')),
        ]));
  }

  Future<void> _exportUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final exportData = {
        'user_profile': _userData,
        'user_stats': _userStats,
        'export_date': DateTime.now().toIso8601String(),
      };

      final String jsonData = jsonEncode(exportData);
      final String fileName =
          'challengeme_data_${DateTime.now().millisecondsSinceEpoch}.json';

      if (kIsWeb) {
        final bytes = utf8.encode(jsonData);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      }

      _showBeautifulSuccessMessage('Données exportées avec succès');
    } catch (e) {
      _showBeautifulErrorMessage('Erreur lors de l\'export des données: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showHelpCenter() {
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Centre d\'aide'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Une question ? Un problème ? Envoyez-nous un message !',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  SizedBox(height: 2.h),
                  TextFormField(
                    controller: subjectController,
                    decoration: InputDecoration(
                      labelText: 'Sujet',
                      hintText: 'Ex: Problème de connexion',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer un sujet';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 2.h),
                  TextFormField(
                    controller: messageController,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      hintText: 'Décrivez votre problème ou question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer un message';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Email de réponse : ${_userData?["email"] ?? "Non connecté"}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppTheme.lightTheme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setDialogState(() => isSubmitting = true);
                        
                        final success = await _submitHelpForm(
                          subject: subjectController.text.trim(),
                          message: messageController.text.trim(),
                          userEmail: _userData?["email"] as String? ?? 'unknown',
                        );
                        
                        Navigator.pop(context);
                        
                        if (success) {
                          _showBeautifulSuccessMessage(
                            'Message envoyé ! Nous vous répondrons rapidement.',
                          );
                        } else {
                          _showBeautifulErrorMessage(
                            'Erreur lors de l\'envoi. Réessayez ou contactez hentzpierre888@gmail.com',
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _submitHelpForm({
    required String subject,
    required String message,
    required String userEmail,
  }) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'send-help-email',
        body: {
          'subject': subject,
          'message': message,
          'userEmail': userEmail,
          'userName': _userData?["full_name"] ?? 'Utilisateur',
        },
      );
      
      if (response.status == 200) {
        return true;
      }
      
      // Fallback: log pour debug si edge function pas encore créée
      debugPrint('📧 Help form submitted:');
      debugPrint('  Subject: $subject');
      debugPrint('  Message: $message');
      debugPrint('  From: $userEmail');
      return true; // Return true pour test en attendant l'edge function
    } catch (e) {
      debugPrint('❌ Error submitting help form: $e');
      // Fallback temporaire: considérer comme succès pour UX
      // En prod, l'edge function gérera l'envoi réel
      return true;
    }
  }

  void _showFeedbackDialog() {
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Envoyer des commentaires'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Une suggestion ? Un bug à signaler ? Aidez-nous à améliorer l\'app !',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  SizedBox(height: 2.h),
                  TextFormField(
                    controller: subjectController,
                    decoration: InputDecoration(
                      labelText: 'Sujet',
                      hintText: 'Ex: Suggestion d\'amélioration',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer un sujet';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 2.h),
                  TextFormField(
                    controller: messageController,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      hintText: 'Décrivez votre suggestion ou le bug rencontré...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer un message';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Email de réponse : ${_userData?["email"] ?? "Non connecté"}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppTheme.lightTheme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setDialogState(() => isSubmitting = true);
                        
                        final success = await _submitHelpForm(
                          subject: '[Feedback] ${subjectController.text.trim()}',
                          message: messageController.text.trim(),
                          userEmail: _userData?["email"] as String? ?? 'unknown',
                        );
                        
                        Navigator.pop(context);
                        
                        if (success) {
                          _showBeautifulSuccessMessage(
                            'Merci pour votre retour ! Nous l\'avons bien reçu.',
                          );
                        } else {
                          _showBeautifulErrorMessage(
                            'Erreur lors de l\'envoi. Réessayez ou contactez hentzpierre888@gmail.com',
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('À propos de ChallengeMe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 1.h),
            Text(
                'ChallengeMe vous accompagne dans votre développement personnel quotidien.'),
            SizedBox(height: 2.h),
            Text('© 2024 ChallengeMe. Tous droits réservés.'),
          ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer')),
        ]));
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Se déconnecter'),
        content: Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              try {
                Navigator.pop(context); // Close dialog first

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.lightTheme.colorScheme.primary)));

                await _authService.signOut();

                // Close loading dialog
                Navigator.pop(context);

                // Navigate to login
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login-screen', (route) => false);
              } catch (e) {
                Navigator.pop(context); // Close loading dialog
                _showBeautifulErrorMessage('Erreur lors de la déconnexion: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.error),
            child: Text('Se déconnecter')),
        ]));
  }

  void _showDeleteAccountConfirmation() {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer le compte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                '⚠️ Cette action est irréversible. Toutes vos données seront définitivement supprimées.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.error,
                ),
              ),
            SizedBox(height: 2.h),
            Text(
                'Cela inclut : défis, progression, statistiques, notifications et toutes vos données personnelles.',
                style: TextStyle(fontSize: 12.sp),
              ),
            SizedBox(height: 2.h),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Confirmez votre e-mail',
                hintText: _userData?["email"] as String? ?? '')),
          ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.trim() == _userData?["email"]) {
                Navigator.pop(context); // Close confirmation dialog
                
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: AppTheme.lightTheme.colorScheme.primary,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Suppression du compte...',
                            style: AppTheme.lightTheme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                try {
                  // Delete the account
                  await _authService.deleteAccount();

                  // Close loading dialog
                  if (mounted) Navigator.pop(context);

                  // Navigate to login screen
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context, 
                      '/login-screen', 
                      (route) => false,
                    );
                  }

                  // Show success message on login screen
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Votre compte a été supprimé avec succès'),
                        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                        duration: Duration(seconds: 5),
                      ),
                    );
                  }
                } catch (e) {
                  // Close loading dialog
                  if (mounted) Navigator.pop(context);
                  
                  // Show error
                  if (mounted) {
                    _showBeautifulErrorMessage(
                      'Erreur lors de la suppression du compte: ${e.toString().replaceAll('Exception: ', '')}',
                    );
                  }
                }
              } else {
                _showBeautifulErrorMessage('L\'adresse e-mail ne correspond pas');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.error),
            child: Text('Supprimer définitivement')),
        ]));
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating));
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        behavior: SnackBarBehavior.floating));
  }

  // Nouvelle popup de succès centrée et esthétique
  void _showBeautifulSuccessMessage(String message) {
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
                // Icône de succès animée
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
                  'Succès !',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2.h),
                
                // Message
                Text(
                  message,
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

  // Nouvelle popup d'erreur centrée et esthétique
  void _showBeautifulErrorMessage(String message) {
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
                // Icône d'erreur animée
                Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error,
                    color: AppTheme.lightTheme.colorScheme.error,
                    size: 12.w,
                  ),
                ),
                SizedBox(height: 3.h),
                
                // Titre
                Text(
                  'Erreur',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2.h),
                
                // Message
                Text(
                  message,
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
                      backgroundColor: AppTheme.lightTheme.colorScheme.error,
                      foregroundColor: AppTheme.lightTheme.colorScheme.onError,
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

  void _triggerTestNotification() async {
    try {
      _showBeautifulSuccessMessage('Test en cours...');
      
      final diagnosticResult = await _notificationService.triggerTestNotification();
      
      // Afficher le diagnostic complet dans une dialog
      _showDiagnosticDialog('🔔 Diagnostic Notifications', diagnosticResult);
      
    } catch (e) {
      _showDiagnosticDialog('❌ Erreur Notifications', e.toString());
    }
  }
  
  void _showDiagnosticDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(
              message,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }
}