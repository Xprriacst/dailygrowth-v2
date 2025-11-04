import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:universal_html/html.dart' as html;
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
        // Extraire la version du HTML de manière simple
        final htmlData = response.data as String;
        
        // Chercher "window.APP_BUILD_VERSION = 'xxxxx'" ou "window.APP_BUILD_VERSION = \"xxxxx\""
        final startMarker = 'window.APP_BUILD_VERSION = ';
        final startIndex = htmlData.indexOf(startMarker);
        
        if (startIndex >= 0) {
          final valueStart = startIndex + startMarker.length;
          // Ignorer le premier guillemet
          final quote = htmlData[valueStart]; // ' ou "
          final versionStart = valueStart + 1;
          final versionEnd = htmlData.indexOf(quote, versionStart);
          
          if (versionEnd > versionStart) {
            final serverVersion = htmlData.substring(versionStart, versionEnd);
            
            if (serverVersion != '__APP_BUILD_VERSION__' &&
                serverVersion != _currentVersion &&
                serverVersion.isNotEmpty) {
              
              debugPrint('[VersionChecker] 🆕 New version detected: $serverVersion (current: $_currentVersion)');
              _onNewVersionDetected?.call(serverVersion);
            } else {
              debugPrint('[VersionChecker] ✅ Running latest version: $_currentVersion');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[VersionChecker] ⚠️ Error checking version: $e');
    }
  }

  /// Force un rechargement de l'application
  static Future<void> reloadApp() async {
    if (!kIsWeb) return;

    try {
      debugPrint('[VersionChecker] 🔄 Starting app reload process...');

      // 1. Vérifier s'il y a un Service Worker en attente et lui envoyer SKIP_WAITING
      if (html.window.navigator.serviceWorker != null) {
        try {
          final registration = await html.window.navigator.serviceWorker!.ready;

          // S'il y a un SW en attente, lui envoyer le message SKIP_WAITING
          final waiting = registration.waiting;
          if (waiting != null) {
            debugPrint('[VersionChecker] 📤 Sending SKIP_WAITING to waiting Service Worker');
            waiting.postMessage({'type': 'SKIP_WAITING'});

            // Attendre un peu pour laisser le SW s'activer
            await Future.delayed(const Duration(milliseconds: 500));
          } else {
            debugPrint('[VersionChecker] ℹ️ No waiting Service Worker, proceeding with reload');
          }
        } catch (e) {
          debugPrint('[VersionChecker] ⚠️ Could not check Service Worker: $e');
        }
      }

      // 2. Recharger la page
      _performReload();
    } catch (e) {
      debugPrint('[VersionChecker] ❌ Error during reload process: $e');
      // Fallback: recharger quand même
      _performReload();
    }
  }

  /// Effectue le rechargement de la page
  static void _performReload() {
    try {
      debugPrint('[VersionChecker] 🔄 Performing page reload...');

      // Utiliser location.replace() avec l'URL actuelle propre pour éviter l'historique
      final cleanUrl = _getCleanUrl();
      html.window.location.replace(cleanUrl);
    } catch (e) {
      debugPrint('[VersionChecker] ⚠️ Replace failed, trying reload: $e');
      try {
        // Fallback: reload simple
        html.window.location.reload();
      } catch (e2) {
        debugPrint('[VersionChecker] ❌ All reload methods failed: $e2');
      }
    }
  }

  /// Obtient une URL propre sans paramètres temporaires
  static String _getCleanUrl() {
    final currentUrl = html.window.location.href ?? '';

    // Supprimer les paramètres _t= qui pourraient exister
    final uri = Uri.parse(currentUrl);
    final cleanParams = Map<String, dynamic>.from(uri.queryParameters);
    cleanParams.remove('_t');

    // Reconstruire l'URL sans le paramètre _t
    final newUri = uri.replace(queryParameters: cleanParams.isEmpty ? null : cleanParams);
    return newUri.toString();
  }

  /// Vérifie si le Service Worker a une nouvelle version en attente
  /// Note: Méthode simplifiée - utilise le rechargement direct
  static Future<bool> checkServiceWorkerUpdate() async {
    if (!kIsWeb) return false;
    
    // Simplifié: on se fie à la détection de version pour déclencher le reload
    debugPrint('[VersionChecker] ℹ️ Service Worker check - using version detection instead');
    return false;
  }

  /// Active le nouveau Service Worker en attente
  /// Note: Le rechargement de la page active automatiquement le nouveau SW
  static Future<void> activateNewServiceWorker() async {
    if (!kIsWeb) return;
    
    try {
      debugPrint('[VersionChecker] 🔄 Activating new version via reload...');
      
      // Le rechargement va automatiquement activer le nouveau SW
      // grâce au message SKIP_WAITING dans sw.js
      await Future.delayed(const Duration(milliseconds: 500));
      reloadApp();
    } catch (e) {
      debugPrint('[VersionChecker] ❌ Error during reload: $e');
      // Fallback: reload anyway
      reloadApp();
    }
  }
}
