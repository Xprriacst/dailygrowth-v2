import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../utils/build_version_helper.dart';

/// Service pour vérifier si une nouvelle version de l'app est disponible
class VersionCheckerService {
  static const String _localStorageKey = 'challengeme.buildVersion';
  static const Duration _checkInterval = Duration(minutes: 5);
  
  Timer? _checkTimer;
  String? _currentVersion;
  Function(String newVersion)? _onNewVersionDetected;

  /// Démarre la vérification périodique de version
  void startVersionCheck({
    required Function(String newVersion) onNewVersionDetected,
  }) {
    if (!kIsWeb) {
      debugPrint('[VersionChecker] Non-web platform, skipping version check');
      return;
    }

    _onNewVersionDetected = onNewVersionDetected;
    _currentVersion = getAppBuildVersion();
    
    debugPrint('[VersionChecker] Current version: $_currentVersion');
    
    // Vérification immédiate
    _checkForNewVersion();
    
    // Puis vérification périodique
    _checkTimer = Timer.periodic(_checkInterval, (_) {
      _checkForNewVersion();
    });
  }

  /// Arrête la vérification périodique
  void stopVersionCheck() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// Vérifie si une nouvelle version est disponible
  Future<void> _checkForNewVersion() async {
    try {
      final dio = Dio();
      
      // Récupérer la version actuelle du serveur
      final response = await dio.get(
        '${Uri.base.origin}/index.html',
        options: Options(
          headers: {'Cache-Control': 'no-cache'},
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && response.data is String) {
        // Extraire la version du HTML
        final versionMatch = RegExp(r'window\.APP_BUILD_VERSION\s*=\s*[\'"]([^\'"]+)[\'"]')
            .firstMatch(response.data);
        
        if (versionMatch != null) {
          final serverVersion = versionMatch.group(1);
          
          if (serverVersion != null && 
              serverVersion != '__APP_BUILD_VERSION__' &&
              serverVersion != _currentVersion &&
              serverVersion.isNotEmpty) {
            
            debugPrint('[VersionChecker] 🆕 New version detected: $serverVersion (current: $_currentVersion)');
            _onNewVersionDetected?.call(serverVersion);
          } else {
            debugPrint('[VersionChecker] ✅ Running latest version: $_currentVersion');
          }
        }
      }
    } catch (e) {
      debugPrint('[VersionChecker] ⚠️ Error checking version: $e');
    }
  }

  /// Force un rechargement de l'application
  static void reloadApp() {
    if (kIsWeb) {
      // Nettoyer tous les caches
      try {
        // ignore: avoid_web_libraries_in_flutter
        import 'dart:html' as html;
        
        // Vider le localStorage (optionnel - garde les données utilisateur)
        // html.window.localStorage.clear();
        
        // Forcer le rechargement en vidant le cache
        html.window.location.reload();
      } catch (e) {
        debugPrint('[VersionChecker] ❌ Error reloading app: $e');
      }
    }
  }

  /// Vérifie si le Service Worker a une nouvelle version en attente
  static Future<bool> checkServiceWorkerUpdate() async {
    if (!kIsWeb) return false;
    
    try {
      // ignore: avoid_web_libraries_in_flutter
      import 'dart:html' as html;
      import 'dart:js_util' as js_util;
      
      final navigator = html.window.navigator;
      final swContainer = js_util.getProperty(navigator, 'serviceWorker');
      
      if (swContainer != null) {
        final registration = await js_util.promiseToFuture(
          js_util.callMethod(swContainer, 'getRegistration', [])
        );
        
        if (registration != null) {
          // Vérifier s'il y a un worker en attente
          final waiting = js_util.getProperty(registration, 'waiting');
          if (waiting != null) {
            debugPrint('[VersionChecker] 🔄 Service Worker update available');
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint('[VersionChecker] ⚠️ Error checking SW update: $e');
    }
    
    return false;
  }

  /// Active le nouveau Service Worker en attente
  static Future<void> activateNewServiceWorker() async {
    if (!kIsWeb) return;
    
    try {
      // ignore: avoid_web_libraries_in_flutter
      import 'dart:html' as html;
      import 'dart:js_util' as js_util;
      
      final navigator = html.window.navigator;
      final swContainer = js_util.getProperty(navigator, 'serviceWorker');
      
      if (swContainer != null) {
        final registration = await js_util.promiseToFuture(
          js_util.callMethod(swContainer, 'getRegistration', [])
        );
        
        if (registration != null) {
          final waiting = js_util.getProperty(registration, 'waiting');
          if (waiting != null) {
            debugPrint('[VersionChecker] 🔄 Activating new Service Worker...');
            
            // Envoyer message SKIP_WAITING au SW
            js_util.callMethod(waiting, 'postMessage', [
              js_util.jsify({'type': 'SKIP_WAITING'})
            ]);
            
            // Recharger après un court délai
            await Future.delayed(const Duration(milliseconds: 500));
            reloadApp();
          }
        }
      }
    } catch (e) {
      debugPrint('[VersionChecker] ❌ Error activating SW: $e');
      // Fallback: reload anyway
      reloadApp();
    }
  }
}
