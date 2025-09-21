import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/pwa_install_service.dart';

class PWAInstallPopup extends StatefulWidget {
  final VoidCallback? onInstalled;
  final VoidCallback? onDismissed;

  const PWAInstallPopup({
    Key? key,
    this.onInstalled,
    this.onDismissed,
  }) : super(key: key);

  @override
  State<PWAInstallPopup> createState() => _PWAInstallPopupState();

  /// Affiche la popup d'installation si elle est disponible
  static void showIfAvailable(BuildContext context, {
    VoidCallback? onInstalled,
    VoidCallback? onDismissed,
  }) {
    if (!kIsWeb) return;

    final installService = PWAInstallService();
    
    if (installService.isInstallable) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => PWAInstallPopup(
          onInstalled: onInstalled,
          onDismissed: onDismissed,
        ),
      );
    }
  }
}

class _PWAInstallPopupState extends State<PWAInstallPopup> 
    with SingleTickerProviderStateMixin {
  final _installService = PWAInstallService();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  bool _isInstalling = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _animationController.forward();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _handleInstall() async {
    setState(() => _isInstalling = true);

    try {
      final success = await _installService.promptInstall();
      
      if (success) {
        widget.onInstalled?.call();
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Afficher les instructions manuelles
        _showManualInstructions();
      }
    } catch (e) {
      debugPrint('[PWAInstallPopup] Error during install: $e');
      _showManualInstructions();
    } finally {
      if (mounted) {
        setState(() => _isInstalling = false);
      }
    }
  }

  void _showManualInstructions() {
    final instructions = _installService.getInstallInstructions();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Installer l\'application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline,
              size: 48,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Text(
              instructions,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('D\'accord'),
          ),
        ],
      ),
    );
  }

  void _handleDismiss() {
    widget.onDismissed?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icône de l'app
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF47C5FB),
                          Color(0xFF1E88E5),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Titre
                  const Text(
                    'Installer DailyGrowth',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E88E5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Description
                  const Text(
                    'Ajoutez DailyGrowth à votre écran d\'accueil pour un accès rapide et une expérience native.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Avantages
                  Column(
                    children: [
                      _buildFeatureRow(
                        Icons.flash_on,
                        'Démarrage instantané',
                      ),
                      _buildFeatureRow(
                        Icons.notifications_active,
                        'Notifications push',
                      ),
                      _buildFeatureRow(
                        Icons.offline_bolt,
                        'Fonctionne hors ligne',
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Boutons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isInstalling ? null : _handleDismiss,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Plus tard',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isInstalling ? null : _handleInstall,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF47C5FB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 3,
                          ),
                          child: _isInstalling
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Installer',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF47C5FB),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}