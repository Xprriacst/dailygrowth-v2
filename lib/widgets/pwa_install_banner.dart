import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/pwa_install_service.dart';
import 'pwa_install_popup.dart';

class PWAInstallBanner extends StatefulWidget {
  final bool showOnlyOnMobile;
  final Duration? autoHideDelay;

  const PWAInstallBanner({
    Key? key,
    this.showOnlyOnMobile = true,
    this.autoHideDelay,
  }) : super(key: key);

  @override
  State<PWAInstallBanner> createState() => _PWAInstallBannerState();
}

class _PWAInstallBannerState extends State<PWAInstallBanner>
    with SingleTickerProviderStateMixin {
  final _installService = PWAInstallService();
  
  bool _isVisible = false;
  bool _isDismissed = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupInstallService();
    
    // Auto-hide après un délai si spécifié
    if (widget.autoHideDelay != null) {
      Future.delayed(widget.autoHideDelay!, () {
        if (mounted && _isVisible && !_isDismissed) {
          _hideBanner();
        }
      });
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
  }

  void _setupInstallService() {
    // Écouter les changements de disponibilité d'installation
    _installService.onInstallAvailabilityChanged = (isAvailable) {
      if (mounted && isAvailable && !_isDismissed) {
        // Vérifier si on doit afficher seulement sur mobile
        if (widget.showOnlyOnMobile && !_installService.isMobileDevice()) {
          return;
        }
        
        setState(() => _isVisible = true);
        _animationController.forward();
      } else if (mounted && !isAvailable) {
        _hideBanner();
      }
    };

    // Callback de succès d'installation
    _installService.onInstallSuccess = () {
      if (mounted) {
        _hideBanner();
        _showSuccessMessage();
      }
    };

    // Vérifier immédiatement si l'installation est disponible
    if (_installService.isInstallable && !_isDismissed) {
      if (!widget.showOnlyOnMobile || _installService.isMobileDevice()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _isVisible = true);
            _animationController.forward();
          }
        });
      }
    }
  }

  void _hideBanner() {
    if (mounted && _isVisible) {
      _animationController.reverse().then((_) {
        if (mounted) {
          setState(() => _isVisible = false);
        }
      });
    }
  }

  void _showInstallPopup() {
    PWAInstallPopup.showIfAvailable(
      context,
      onInstalled: () {
        _hideBanner();
        _showSuccessMessage();
      },
      onDismissed: () {
        // Ne pas cacher le banner si l'utilisateur ferme juste la popup
      },
    );
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Application installée avec succès !'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _dismissBanner() {
    setState(() => _isDismissed = true);
    _hideBanner();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !_isVisible || _isDismissed) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF47C5FB),
              Color(0xFF1E88E5),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showInstallPopup,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icône
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.download_for_offline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Texte
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Installer DailyGrowth',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Accès rapide depuis votre écran d\'accueil',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Bouton d'action
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Installer',
                      style: TextStyle(
                        color: Color(0xFF1E88E5),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Bouton de fermeture
                  InkWell(
                    onTap: _dismissBanner,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        color: Colors.white.withOpacity(0.8),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}