import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'dart:js' as js;

class PWAInstallService {
  static final PWAInstallService _instance = PWAInstallService._internal();
  factory PWAInstallService() => _instance;
  PWAInstallService._internal();

  // Event pour signaler quand l'installation est disponible
  Function(bool)? onInstallAvailabilityChanged;
  
  // Event pour les callbacks de l'installation
  Function()? onInstallSuccess;
  Function(String)? onInstallError;

  bool _isInstallable = false;
  bool _isInitialized = false;
  
  // Référence vers l'événement beforeinstallprompt
  dynamic _deferredPrompt;

  bool get isInstallable => _isInstallable;
  bool get isInitialized => _isInitialized;

  /// Initialise le service d'installation PWA
  Future<void> initialize() async {
    if (!kIsWeb) {
      debugPrint('[PWAInstall] Not running on web, skipping initialization');
      return;
    }

    if (_isInitialized) {
      debugPrint('[PWAInstall] Already initialized');
      return;
    }

    try {
      debugPrint('[PWAInstall] Initializing PWA install service...');

      // Vérifier si PWA est déjà installée
      if (_isPWAInstalled()) {
        debugPrint('[PWAInstall] PWA already installed');
        _isInitialized = true;
        return;
      }

      // Écouter l'événement beforeinstallprompt
      _setupBeforeInstallPromptListener();

      // Vérifier les critères d'installation après un délai
      Future.delayed(const Duration(seconds: 2), () {
        _checkInstallCriteria();
      });

      _isInitialized = true;
      debugPrint('[PWAInstall] ✅ PWA install service initialized');
    } catch (e) {
      debugPrint('[PWAInstall] ❌ Error initializing: $e');
    }
  }

  /// Configure l'écouteur pour l'événement beforeinstallprompt
  void _setupBeforeInstallPromptListener() {
    try {
      js.context.callMethod('addEventListener', [
        'beforeinstallprompt',
        js.allowInterop((e) {
          debugPrint('[PWAInstall] 🎯 beforeinstallprompt event fired');
          
          // Empêcher l'affichage automatique du navigateur
          e.preventDefault();
          
          // Sauvegarder l'événement pour plus tard
          _deferredPrompt = e;
          _isInstallable = true;
          
          // Notifier que l'installation est disponible
          onInstallAvailabilityChanged?.call(true);
          
          debugPrint('[PWAInstall] ✅ Install prompt ready');
        })
      ]);

      // Écouter l'événement appinstalled
      js.context.callMethod('addEventListener', [
        'appinstalled',
        js.allowInterop((e) {
          debugPrint('[PWAInstall] 🎉 App was installed successfully');
          _isInstallable = false;
          _deferredPrompt = null;
          onInstallSuccess?.call();
          onInstallAvailabilityChanged?.call(false);
        })
      ]);

    } catch (e) {
      debugPrint('[PWAInstall] ❌ Error setting up listeners: $e');
    }
  }

  /// Vérifie si la PWA est déjà installée
  bool _isPWAInstalled() {
    try {
      // Vérifier si l'app est en mode standalone
      final isStandalone = js.context['navigator']['standalone'] == true ||
          html.window.matchMedia('(display-mode: standalone)').matches;
      
      if (isStandalone) {
        debugPrint('[PWAInstall] PWA is running in standalone mode');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('[PWAInstall] Error checking if PWA is installed: $e');
      return false;
    }
  }

  /// Vérifie les critères d'installation
  void _checkInstallCriteria() {
    try {
      // Vérifier si on est sur mobile
      final isMobile = isMobileDevice();
      
      // Vérifier si l'app est éligible à l'installation
      final isEligible = _deferredPrompt != null || isMobile;
      
      debugPrint('[PWAInstall] Install criteria check:');
      debugPrint('[PWAInstall] - Is mobile: $isMobile');
      debugPrint('[PWAInstall] - Has deferred prompt: ${_deferredPrompt != null}');
      debugPrint('[PWAInstall] - Is eligible: $isEligible');
      
      if (isEligible && !_isPWAInstalled()) {
        _isInstallable = true;
        onInstallAvailabilityChanged?.call(true);
      }
    } catch (e) {
      debugPrint('[PWAInstall] Error checking install criteria: $e');
    }
  }

  /// Détecte si l'utilisateur est sur un appareil mobile
  bool isMobileDevice() {
    try {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      final isMobile = userAgent.contains('mobile') || 
                      userAgent.contains('android') || 
                      userAgent.contains('iphone') || 
                      userAgent.contains('ipad');
      
      // Vérifier aussi la taille de l'écran
      final screenWidth = html.window.screen?.width ?? 0;
      final isSmallScreen = screenWidth <= 768;
      
      return isMobile || isSmallScreen;
    } catch (e) {
      debugPrint('[PWAInstall] Error detecting mobile device: $e');
      return false;
    }
  }

  /// Détecte le type de navigateur
  String getBrowserType() {
    try {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      
      if (userAgent.contains('safari') && !userAgent.contains('chrome')) {
        return 'safari';
      } else if (userAgent.contains('chrome')) {
        return 'chrome';
      } else if (userAgent.contains('firefox')) {
        return 'firefox';
      } else if (userAgent.contains('edge')) {
        return 'edge';
      }
      
      return 'unknown';
    } catch (e) {
      debugPrint('[PWAInstall] Error detecting browser: $e');
      return 'unknown';
    }
  }

  /// Déclenche l'installation de la PWA
  Future<bool> promptInstall() async {
    if (!_isInstallable) {
      debugPrint('[PWAInstall] ⚠️ Install not available');
      return false;
    }

    try {
      debugPrint('[PWAInstall] 🚀 Prompting installation...');

      if (_deferredPrompt != null) {
        // Utiliser l'API native beforeinstallprompt
        final result = await _deferredPrompt.prompt();
        
        if (result != null && result['outcome'] == 'accepted') {
          debugPrint('[PWAInstall] ✅ User accepted the install prompt');
          _deferredPrompt = null;
          _isInstallable = false;
          onInstallAvailabilityChanged?.call(false);
          return true;
        } else {
          debugPrint('[PWAInstall] ❌ User dismissed the install prompt');
          return false;
        }
      } else {
        // Fallback pour les navigateurs qui ne supportent pas beforeinstallprompt
        debugPrint('[PWAInstall] ⚠️ Native install prompt not available, using fallback');
        return false;
      }
    } catch (e) {
      debugPrint('[PWAInstall] ❌ Error during installation: $e');
      onInstallError?.call(e.toString());
      return false;
    }
  }

  /// Obtient les instructions d'installation spécifiques au navigateur
  String getInstallInstructions() {
    final browser = getBrowserType();
    
    switch (browser) {
      case 'safari':
        return 'Appuyez sur l\'icône de partage et sélectionnez "Sur l\'écran d\'accueil"';
      case 'chrome':
        return 'Appuyez sur le menu et sélectionnez "Installer l\'application"';
      case 'firefox':
        return 'Appuyez sur le menu et sélectionnez "Installer"';
      case 'edge':
        return 'Appuyez sur le menu et sélectionnez "Installer cette application"';
      default:
        return 'Consultez les options de votre navigateur pour installer l\'application';
    }
  }

  /// Nettoie les ressources
  void dispose() {
    _deferredPrompt = null;
    _isInstallable = false;
    onInstallAvailabilityChanged = null;
    onInstallSuccess = null;
    onInstallError = null;
  }
}