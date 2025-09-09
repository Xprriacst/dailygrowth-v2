// Service dédié aux notifications web pour PWA
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'dart:js' as js;

class WebNotificationService {
  static final WebNotificationService _instance = WebNotificationService._internal();
  factory WebNotificationService() => _instance;
  WebNotificationService._internal();

  bool _isInitialized = false;
  String? _permission;

  Future<void> initialize() async {
    if (_isInitialized || !kIsWeb) return;

    try {
      // Vérifier le support des notifications
      if (!_isNotificationSupported()) {
        debugPrint('❌ Web notifications not supported in this browser');
        return;
      }

      // Vérifier l'état actuel des permissions sans les demander
      _permission = html.Notification.permission;
      debugPrint('🔔 Current web notification permission: $_permission');

      // Configurer les gestionnaires d'événements
      _setupEventHandlers();

      _isInitialized = true;
      debugPrint('✅ WebNotificationService initialized (permission not requested yet)');
    } catch (e) {
      debugPrint('❌ Failed to initialize WebNotificationService: $e');
    }
  }

  bool _isNotificationSupported() {
    return js.context.hasProperty('Notification') && 
           html.Notification.supported;
  }

  void _setupEventHandlers() {
    // Écouter les messages du service worker pour les badges
    html.window.addEventListener('message', (event) {
      final data = (event as html.MessageEvent).data;
      if (data is Map && data['type'] == 'BADGE_UPDATED') {
        debugPrint('📱 Badge updated: ${data['count']}');
      }
    });
  }

  // Afficher une notification web native
  Future<void> showNotification({
    required String title,
    required String body,
    String? icon,
    String? tag,
    Map<String, dynamic>? data,
    List<Map<String, String>>? actions,
  }) async {
    if (!kIsWeb || !_isInitialized || _permission != 'granted') {
      debugPrint('❌ Cannot show web notification: not initialized or permission denied');
      return;
    }

    try {
      final options = <String, dynamic>{
        'body': body,
        'icon': icon ?? '/icons/Icon-192.png',
        'badge': '/icons/Icon-192.png',
        'tag': tag ?? 'dailygrowth-notification',
        'requireInteraction': false,
        'silent': false,
        'data': data ?? {},
      };

      // Ajouter les actions si disponibles
      if (actions != null && actions.isNotEmpty) {
        options['actions'] = actions.map((action) => {
          'action': action['action'],
          'title': action['title'],
          'icon': action['icon'],
        }).toList();
      }

      // Créer la notification
      final notification = html.Notification(title);
      // Note: Options via constructor not supported, using properties instead

      // Gérer le clic sur la notification
      notification.onClick.listen((_) {
        debugPrint('🔔 Web notification clicked');
        try { 
          // Focus not available in modern browsers for security 
        } catch (e) {
          debugPrint('Focus not available: $e');
        }
        notification.close();
        
        // Navigation si URL fournie dans data
        if (data != null && data['url'] != null) {
          html.window.location.href = data['url'];
        }
      });

      // Auto-fermeture après 5 secondes
      Future.delayed(const Duration(seconds: 5), () {
        try {
          notification.close();
        } catch (e) {
          // Ignore - notification peut déjà être fermée
        }
      });

      debugPrint('✅ Web notification shown: $title');
    } catch (e) {
      debugPrint('❌ Failed to show web notification: $e');
    }
  }

  // Mettre à jour le badge d'application (iOS Safari 16.4+)
  Future<void> updateBadge(int count) async {
    if (!kIsWeb) return;

    try {
      // Méthode 1: Badge API native (Safari iOS 16.4+)
      if (js.context.hasProperty('navigator') && 
          js.context['navigator'].hasProperty('setAppBadge')) {
        if (count > 0) {
          js.context['navigator'].callMethod('setAppBadge', [count]);
          debugPrint('🔴 Badge updated via native API: $count');
        } else {
          js.context['navigator'].callMethod('clearAppBadge');
          debugPrint('🔴 Badge cleared via native API');
        }
        return;
      }

      // Méthode 2: Service Worker
      if (js.context['navigator'].hasProperty('serviceWorker')) {
        final registration = await html.window.navigator.serviceWorker?.ready;
        if (registration != null) {
          registration.active?.postMessage({
            'type': 'SET_BADGE',
            'count': count
          });
          debugPrint('🔴 Badge update sent to service worker: $count');
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to update badge: $e');
    }
  }

  // Vérifier si les notifications sont autorisées
  bool get isPermissionGranted => _permission == 'granted';

  // Obtenir le statut de permission
  String get permissionStatus => _permission ?? 'default';

  // Demander la permission explicitement
  Future<String> requestPermission() async {
    if (!kIsWeb || !_isNotificationSupported()) {
      return 'denied';
    }

    try {
      _permission = await html.Notification.requestPermission();
      debugPrint('🔔 Permission requested: $_permission');
      return _permission!;
    } catch (e) {
      debugPrint('❌ Failed to request permission: $e');
      return 'denied';
    }
  }

  // Envoyer un message au service worker
  Future<void> sendMessageToServiceWorker(Map<String, dynamic> message) async {
    if (!kIsWeb) return;

    try {
      if (js.context['navigator'].hasProperty('serviceWorker')) {
        final registration = await html.window.navigator.serviceWorker?.ready;
        if (registration?.active != null) {
          registration!.active!.postMessage(message);
          debugPrint('📨 Message sent to service worker: ${message['type']}');
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to send message to service worker: $e');
    }
  }

  // Notifications prédéfinies pour DailyGrowth
  Future<void> showChallengeNotification({
    required String challengeName,
    String? challengeId,
  }) async {
    await showNotification(
      title: '🎯 Nouveau défi disponible !',
      body: challengeName,
      tag: 'challenge-notification',
      data: {
        'type': 'challenge',
        'challengeId': challengeId,
        'url': '/#/challenges',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      actions: [
        {'action': 'view', 'title': 'Voir le défi', 'icon': '/icons/Icon-192.png'},
        {'action': 'dismiss', 'title': 'Plus tard', 'icon': '/icons/Icon-192.png'},
      ],
    );

    // Mettre à jour le badge
    await updateBadge(1);
  }

  Future<void> showQuoteNotification({
    required String quote,
    required String author,
  }) async {
    await showNotification(
      title: '💫 Citation du jour',
      body: '"$quote" - $author',
      tag: 'quote-notification',
      data: {
        'type': 'quote',
        'url': '/#/quotes',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      actions: [
        {'action': 'view', 'title': 'Voir plus', 'icon': '/icons/Icon-192.png'},
        {'action': 'dismiss', 'title': 'Fermer', 'icon': '/icons/Icon-192.png'},
      ],
    );
  }

  Future<void> showAchievementNotification({
    required String achievementName,
    required String description,
    required int pointsEarned,
  }) async {
    await showNotification(
      title: '🏆 Nouveau succès débloqué !',
      body: '$achievementName - $description (+$pointsEarned points)',
      tag: 'achievement-notification',
      data: {
        'type': 'achievement',
        'url': '/#/profile',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      actions: [
        {'action': 'view', 'title': 'Voir profil', 'icon': '/icons/Icon-192.png'},
        {'action': 'share', 'title': 'Partager', 'icon': '/icons/Icon-192.png'},
      ],
    );

    // Mettre à jour le badge avec achievements
    await updateBadge(1);
  }

  Future<void> showStreakNotification({
    required int streakCount,
  }) async {
    String emoji = '🔥';
    String title = 'Série de $streakCount jours !';
    String body = 'Fantastique ! Continuez sur cette belle lancée !';

    if (streakCount == 7) {
      emoji = '🔥';
      title = 'Série de 7 jours !';
      body = 'Incroyable ! Une semaine entière de progression !';
    } else if (streakCount == 30) {
      emoji = '🌟';
      title = 'Série de 30 jours !';
      body = 'Extraordinaire ! Un mois complet de croissance !';
    } else if (streakCount == 100) {
      emoji = '💎';
      title = 'Série de 100 jours !';
      body = 'Légendaire ! Vous êtes un champion de la croissance !';
    }

    await showNotification(
      title: '$emoji $title',
      body: body,
      tag: 'streak-notification',
      data: {
        'type': 'streak',
        'streakCount': streakCount,
        'url': '/#/profile',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      actions: [
        {'action': 'celebrate', 'title': 'Célébrer', 'icon': '/icons/Icon-192.png'},
        {'action': 'continue', 'title': 'Continuer', 'icon': '/icons/Icon-192.png'},
      ],
    );
  }

  Future<void> showReminderNotification({
    required String userName,
  }) async {
    await showNotification(
      title: '⏰ N\'oubliez pas votre défi !',
      body: 'Bonjour $userName, votre micro-défi vous attend dans l\'application.',
      tag: 'reminder-notification',
      data: {
        'type': 'reminder',
        'url': '/#/challenges',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      actions: [
        {'action': 'open', 'title': 'Ouvrir', 'icon': '/icons/Icon-192.png'},
        {'action': 'snooze', 'title': 'Plus tard', 'icon': '/icons/Icon-192.png'},
      ],
    );
  }

  // Nettoyer les badges et notifications
  Future<void> clearBadge() async {
    await updateBadge(0);
  }

  Future<void> clearAllNotifications() async {
    try {
      await sendMessageToServiceWorker({'type': 'CLEAR_NOTIFICATIONS'});
      await clearBadge();
      debugPrint('🧹 All notifications cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear notifications: $e');
    }
  }

  void dispose() {
    // Cleanup if needed
  }
}