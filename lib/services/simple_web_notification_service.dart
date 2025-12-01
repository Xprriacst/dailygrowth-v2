import 'dart:async';
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'package:flutter/foundation.dart';

/// Service de notifications web simplifié qui fonctionne sur iOS
/// Basé sur la mini PWA testée et validée
class SimpleWebNotificationService {
  static SimpleWebNotificationService? _instance;
  static SimpleWebNotificationService get instance => _instance ??= SimpleWebNotificationService._();
  
  SimpleWebNotificationService._();

  bool _isInitialized = false;
  String _permission = 'default';

  /// Initialise le service de notifications web
  Future<void> initialize() async {
    if (_isInitialized || !kIsWeb) return;
    
    try {
      debugPrint('🔧 Initializing Simple Web Notification Service...');
      
      // Détection plateforme iOS
      final isIOS = _detectIOS();
      final isPWA = _detectPWA();
      
      debugPrint('🔍 Platform detection: iOS=$isIOS, PWA=$isPWA');
      
      if (isIOS && !isPWA) {
        debugPrint('⚠️ iOS detected but NOT running as PWA!');
        debugPrint('💡 Notifications require: Safari → Share → Add to Home Screen');
      }

      // Vérifier permissions actuelles
      if (_isNotificationSupported()) {
        _permission = await _getNotificationPermission();
        debugPrint('🔔 Current notification permission: $_permission');
        
        if (_permission == 'denied' && isIOS) {
          debugPrint('❌ iOS: Permissions denied. Check Settings → ChallengeMe → Notifications');
        }
      } else {
        _permission = 'denied';
        debugPrint('⚠️ Notifications not supported on this browser');
      }

      // Enregistrer le service worker
      await _registerServiceWorker();

      _isInitialized = true;
      debugPrint('✅ Simple Web Notification Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize Simple Web Notification Service: $e');
    }
  }

  /// Demande de permission avec support legacy callback
  Future<String> _requestPermissionLegacyWithCallback() async {
    try {
      final notification = js.context['Notification'];
      if (notification == null) {
        debugPrint('❌ Notification API not available for legacy fallback');
        return 'denied';
      }

      final completer = Completer<String>();
      dynamic result;

      try {
        result = js_util.callMethod(notification, 'requestPermission', [
          js.allowInterop((value) {
            if (!completer.isCompleted) {
              final permission = value?.toString() ?? 'default';
              debugPrint('🔔 Legacy callback result: $permission');
              completer.complete(permission);
            }
          })
        ]);
        debugPrint('ℹ️ requestPermission invoked with callback parameter');
      } catch (callbackError) {
        debugPrint('⚠️ Callback signature failed: $callbackError');
        try {
          result = js_util.callMethod(notification, 'requestPermission', []);
          debugPrint('ℹ️ requestPermission invoked without callback');
        } catch (noArgError) {
          debugPrint('❌ requestPermission invocation failed: $noArgError');
          return 'default';
        }
      }

      if (result is String) {
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      } else if (result != null) {
        try {
          final promiseResult = await js_util.promiseToFuture(result);
          if (!completer.isCompleted) {
            completer.complete(promiseResult?.toString() ?? 'default');
          }
        } catch (promiseError) {
          debugPrint('ℹ️ requestPermission does not return Promise: $promiseError');
        }
      }

      if (!completer.isCompleted) {
        // Ensure completion even if neither callback nor promise triggered
        debugPrint('⚠️ Legacy requestPermission returned without result');
        completer.complete('default');
      }

      return await completer.future;
    } catch (e) {
      debugPrint('❌ Legacy permission fallback failed: $e');
      return 'default';
    }
  }

  /// Détecte si on est sur iOS
  bool _detectIOS() {
    try {
      final userAgent = js.context.callMethod('eval', ['navigator.userAgent']).toString();
      debugPrint('🧭 User agent: ${userAgent.isNotEmpty ? userAgent : 'unknown'}');
      final isIOS = userAgent.contains(RegExp(r'iPhone|iPad|iPod'));
      debugPrint('🧭 Detected iOS via userAgent: $isIOS');
      return isIOS;
    } catch (e) {
      debugPrint('⚠️ Could not detect iOS platform: $e');
      return false;
    }
  }

  /// Détecte si on est en mode PWA
  bool _detectPWA() {
    try {
      final isStandalone = js.context.callMethod('eval', ['window.navigator.standalone']);
      final displayMode = js.context.callMethod(
        'eval',
        ['window.matchMedia("(display-mode: standalone)").matches'],
      );
      debugPrint('🏠 navigator.standalone: $isStandalone');
      debugPrint('🏠 display-mode standalone: $displayMode');
      final detectedPwa = isStandalone == true || displayMode == true;
      debugPrint('🏠 Detected PWA mode: $detectedPwa');
      return detectedPwa;
    } catch (e) {
      debugPrint('⚠️ Could not detect PWA mode: $e');
      return false;
    }
  }

  /// Vérifie si les notifications sont supportées
  bool _isNotificationSupported() {
    try {
      return js.context.hasProperty('Notification');
    } catch (e) {
      return false;
    }
  }

  /// Récupère les permissions de notification actuelles
  Future<String> _getNotificationPermission() async {
    try {
      // Méthode moderne
      try {
        final permissionStatus = await js_util.promiseToFuture(
          js_util.callMethod(
            js_util.getProperty(js.context['navigator'], 'permissions'),
            'query',
            [js_util.jsify({'name': 'notifications'})]
          )
        );
        final state = js_util.getProperty(permissionStatus, 'state').toString();
        debugPrint('✅ Got permission via modern API: $state');
        return state;
      } catch (e) {
        debugPrint('⚠️ Modern API failed, trying legacy: $e');
        // Fallback vers l'ancienne méthode
        final permission = js_util.getProperty(js.context['Notification'], 'permission');
        debugPrint('✅ Got permission via legacy API: $permission');
        return permission.toString();
      }
    } catch (e) {
      debugPrint('⚠️ Could not get notification permission: $e');
      return 'default';
    }
  }

  /// Demande les permissions de notification
  Future<bool> requestNotificationPermission() async {
    if (!_isNotificationSupported()) {
      debugPrint('❌ Notifications not supported on this device');
      return false;
    }

    try {
      debugPrint('🔔 Requesting notification permission...');

      // Méthode moderne pour iOS/Safari récents
      String permission;

      // Diagnostics des API disponibles
      try {
        final navigator = js.context['navigator'];
        final hasPermissionsApi =
            navigator is js.JsObject && navigator.hasProperty('permissions');
        final notification = js.context['Notification'];
        final hasLegacyRequest =
            notification is js.JsObject && notification.hasProperty('requestPermission');
        debugPrint('🔍 navigator.permissions available: $hasPermissionsApi');
        debugPrint('🔍 Notification.requestPermission available: $hasLegacyRequest');
      } catch (e) {
        debugPrint('⚠️ Error inspecting permission APIs: $e');
      }

      try {
        // Essayer la nouvelle méthode (iOS 15+)
        final permissionStatus = await js_util.promiseToFuture(
          js_util.callMethod(
            js_util.getProperty(js.context['navigator'], 'permissions'),
            'request',
            [js_util.jsify({'name': 'notifications'})]
          )
        );
        permission = js_util.getProperty(permissionStatus, 'state').toString();
        debugPrint('✅ Used modern permissions API');
      } catch (e) {
        debugPrint('⚠️ Modern permissions API failed, trying legacy: $e');
        // Fallback vers l'ancienne méthode avec gestion callback/promise
        permission = await _requestPermissionLegacyWithCallback();
        debugPrint('✅ Used legacy Notification.requestPermission with fallback');
      }
      
      _permission = permission;
      debugPrint('🔔 Permission result: $_permission');
      
      return _permission == 'granted';
    } catch (e) {
      debugPrint('❌ Error requesting notification permission: $e');
      debugPrint('💡 Try accessing from PWA (Home Screen) on iOS');
      return false;
    }
  }

  /// Enregistre le service worker
  Future<void> _registerServiceWorker() async {
    try {
      if (js.context.hasProperty('serviceWorker') && js.context['serviceWorker'].hasProperty('register')) {
        debugPrint('🔧 Registering service worker...');
        
        final registration = await js_util.promiseToFuture(
          js_util.callMethod(js.context['serviceWorker'], 'register', ['/sw.js'])
        );
        
        debugPrint('✅ Service Worker registered successfully');
      } else {
        debugPrint('⚠️ Service Worker not supported');
      }
    } catch (e) {
      debugPrint('❌ Service Worker registration failed: $e');
    }
  }

  /// Affiche une notification immédiate
  Future<void> showNotification({
    required String title,
    required String body,
    String? icon,
    String? tag,
  }) async {
    if (!_isNotificationSupported()) {
      debugPrint('❌ Notifications not supported');
      return;
    }

    // Vérifier les permissions actuelles avec une méthode simple
    try {
      final currentPermission = js.context['Notification']['permission'];
      _permission = currentPermission.toString();
      debugPrint('🔔 Current permission: $_permission');
    } catch (e) {
      debugPrint('⚠️ Could not check permission: $e');
    }

    if (_permission != 'granted') {
      debugPrint('❌ Notification permission not granted: $_permission');
      debugPrint('💡 Please enable notifications in iOS Settings → ChallengeMe');
      return;
    }

    try {
      debugPrint('📱 Showing web notification: $title - $body');
      
      final options = js_util.jsify({
        'body': body,
        'icon': icon ?? '/icons/Icon-192.png',
        'badge': '/icons/Icon-192.png',
        'tag': tag ?? 'dailygrowth-notification',
        'requireInteraction': true,
      });

      // Créer la notification via le constructeur JavaScript Notification
      final notificationConstructor = js_util.getProperty(js.context, 'Notification');
      final notification = js_util.callConstructor(notificationConstructor, [title, options]);
      
      debugPrint('✅ Notification displayed successfully');
      
      // Auto-close après 5 secondes
      Future.delayed(const Duration(seconds: 5), () {
        try {
          js_util.callMethod(notification, 'close', []);
        } catch (_) {}
      });
      
    } catch (e) {
      debugPrint('❌ Error showing notification: $e');
    }
  }

  /// Vérifie si on peut demander les permissions (iOS/PWA)
  bool shouldRequestPermission() {
    if (!kIsWeb) return false;
    return _permission == 'default' && _isNotificationSupported();
  }

  /// Vérifie si les permissions sont accordées
  bool hasPermission() {
    if (!kIsWeb) return false;
    return _permission == 'granted';
  }

  /// Test de notification
  Future<void> showTestNotification() async {
    await showNotification(
      title: '🧪 Test ChallengeMe',
      body: 'Notification de test réussie !',
      tag: 'test-notification',
    );
  }

  /// Fournit un diagnostic complet de l'environnement web actuel
  Future<Map<String, dynamic>> collectDiagnostics() async {
    final diagnostics = <String, dynamic>{};

    try {
      final userAgent = js.context.callMethod('eval', ['navigator.userAgent']).toString();
      diagnostics['userAgent'] = userAgent;
    } catch (e) {
      diagnostics['userAgentError'] = e.toString();
    }

    diagnostics['isIOS'] = _detectIOS();
    diagnostics['isPWA'] = _detectPWA();
    diagnostics['notificationsSupported'] = _isNotificationSupported();

    try {
      final navigator = js.context['navigator'];
      diagnostics['hasNavigatorPermissions'] =
          navigator is js.JsObject && navigator.hasProperty('permissions');
    } catch (e) {
      diagnostics['navigatorPermissionsError'] = e.toString();
    }

    try {
      final notification = js.context['Notification'];
      diagnostics['hasLegacyRequestPermission'] =
          notification is js.JsObject && notification.hasProperty('requestPermission');
    } catch (e) {
      diagnostics['legacyRequestPermissionError'] = e.toString();
    }

    if (diagnostics['notificationsSupported'] == true) {
      diagnostics['permissionStatus'] = await _getNotificationPermission();
    } else {
      diagnostics['permissionStatus'] = 'unsupported';
    }

    return diagnostics;
  }

  /// Notification de défi
  Future<void> showChallengeNotification({
    String? title,
    String? body,
  }) async {
    await showNotification(
      title: title ?? '🎯 Nouveau Défi',
      body: body ?? 'Un nouveau défi vous attend !',
      tag: 'challenge-notification',
    );
  }

  /// Notification de rappel
  Future<void> showReminderNotification({
    String? title,
    String? body,
  }) async {
    await showNotification(
      title: title ?? '⏰ Rappel',
      body: body ?? 'N\'oubliez pas votre défi du jour !',
      tag: 'reminder-notification',
    );
  }
}
