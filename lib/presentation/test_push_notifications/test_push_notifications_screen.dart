import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../services/web_notification_service.dart';
import 'package:universal_html/html.dart' as html;

class TestPushNotificationsScreen extends StatefulWidget {
  const TestPushNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<TestPushNotificationsScreen> createState() =>
      _TestPushNotificationsScreenState();
}

class _TestPushNotificationsScreenState
    extends State<TestPushNotificationsScreen> {
  final _webNotificationService = WebNotificationService();
  final List<String> _logs = [];
  String? _fcmToken;
  String _permissionStatus = 'Vérification...';
  bool _isIOS = false;
  bool _isSafari = false;
  bool _isStandalone = false;
  bool _badgeSupported = false;

  @override
  void initState() {
    super.initState();
    _detectEnvironment();
    _checkPermissions();
  }

  void _detectEnvironment() {
    if (!kIsWeb) return;

    try {
      final userAgent = html.window.navigator.userAgent;
      _isIOS = userAgent.contains(RegExp(r'iPhone|iPad|iPod'));
      _isSafari = RegExp(r'^((?!chrome|android).)*safari', caseSensitive: false)
          .hasMatch(userAgent);
      _isStandalone = html.window.matchMedia('(display-mode: standalone)').matches;

      // Check Badge API support (simplified check)
      _badgeSupported = _isStandalone && _isIOS;

      _log(
          '📱 Environnement: ${_isIOS ? 'iOS' : 'Desktop'} ${_isSafari ? 'Safari' : 'Autre'} ${_isStandalone ? '(Mode PWA)' : '(Navigateur)'}');

      if (_isStandalone && _isIOS) {
        _log('✅ PWA iOS installée - Notifications complètes disponibles');
      } else if (_isIOS && !_isStandalone) {
        _log('⚠️ iOS détecté mais PAS en mode PWA');
        _log('💡 Pour activer: Safari → Partager → Sur l\'écran d\'accueil');
      }
    } catch (e) {
      _log('❌ Erreur détection environnement: $e');
    }
  }

  Future<void> _checkPermissions() async {
    if (!kIsWeb) return;

    try {
      final permission = _webNotificationService.permissionStatus;
      setState(() {
        _permissionStatus = permission;
      });
      _log('🔔 Permission actuelle: $permission');
    } catch (e) {
      _log('❌ Erreur vérification permissions: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (!kIsWeb) {
      _log('❌ Fonctionne uniquement sur web/PWA');
      return;
    }

    _log('📱 Demande de permissions...');

    try {
      final permission = await _webNotificationService.requestPermission();
      setState(() {
        _permissionStatus = permission;
      });

      if (permission == 'granted') {
        _log('✅ Permissions accordées');
        await _getFCMToken();
      } else if (permission == 'denied') {
        _log('❌ Permissions refusées');
        if (_isIOS) {
          _log('💡 iOS: Vérifier Réglages → ChallengeMe → Notifications');
        }
      } else {
        _log('⚠️ Permissions non définies');
      }
    } catch (e) {
      _log('❌ Erreur permissions: $e');
    }
  }

  Future<void> _getFCMToken() async {
    if (!kIsWeb) return;

    _log('🔥 Récupération token FCM...');

    try {
      // Try to get existing token first
      String? token = await _webNotificationService.getFCMToken();

      // If no token exists, try to generate one
      if (token == null || token.isEmpty) {
        _log('⚠️ Pas de token existant, génération...');
        token = await _webNotificationService.generateFCMToken();
      }

      if (token != null && token.isNotEmpty) {
        setState(() {
          _fcmToken = token;
        });
        _log('✅ Token FCM obtenu: ${token.substring(0, 20)}...');
      } else {
        _log('❌ Impossible d\'obtenir le token FCM');
        _log('💡 Vérifier que le Service Worker est actif');
      }
    } catch (e) {
      _log('❌ Erreur token FCM: $e');
    }
  }

  Future<void> _testBasicNotification() async {
    if (!kIsWeb) return;

    _log('🧪 Test notification basique');

    if (_permissionStatus != 'granted') {
      _log('❌ Permissions non accordées - Demander d\'abord les permissions');
      return;
    }

    try {
      await _webNotificationService.showNotification(
        title: '🔔 Test DailyGrowth',
        body: 'Votre système de notifications fonctionne parfaitement !',
        icon: '/icons/Icon-192.png',
        data: {'type': 'test'},
      );
      _log('✅ Notification envoyée');
    } catch (e) {
      _log('❌ Erreur notification: $e');
    }
  }

  Future<void> _testChallengeNotification() async {
    if (!kIsWeb) return;

    _log('🧪 Test notification défi');

    try {
      await _webNotificationService.showChallengeNotification(
        title: '🎯 Nouveau micro-défi disponible !',
        body: 'Méditation de 10 minutes - Prenez un moment pour vous recentrer',
        icon: '/icons/Icon-192.png',
        data: {'type': 'challenge', 'challengeId': '123'},
      );
      _setBadge(1);
      _log('✅ Notification défi envoyée');
    } catch (e) {
      _log('❌ Erreur notification défi: $e');
    }
  }

  Future<void> _testAchievementNotification() async {
    if (!kIsWeb) return;

    _log('🧪 Test notification succès');

    try {
      await _webNotificationService.showAchievementNotification(
        title: '🏆 Nouveau succès débloqué !',
        body: 'Premier défi complété - Bravo pour ce premier pas ! (+50 points)',
        icon: '/icons/Icon-192.png',
        data: {'type': 'achievement', 'points': 50},
        pointsEarned: 50,
      );
      _setBadge(2);
      _log('✅ Notification succès envoyée');
    } catch (e) {
      _log('❌ Erreur notification succès: $e');
    }
  }

  Future<void> _testStreakNotification() async {
    if (!kIsWeb) return;

    _log('🧪 Test notification série');

    try {
      await _webNotificationService.showStreakNotification(
        title: '🔥 Série de 7 jours !',
        body:
            'Incroyable ! Vous avez maintenu votre série pendant une semaine entière !',
        icon: '/icons/Icon-192.png',
        data: {'type': 'streak', 'count': 7},
        streakCount: 7,
      );
      _setBadge(7);
      _log('✅ Notification série envoyée');
    } catch (e) {
      _log('❌ Erreur notification série: $e');
    }
  }

  void _setBadge(int count) {
    if (!kIsWeb) return;

    try {
      _webNotificationService.updateBadge(count);
      _log('🔴 Badge mis à jour: $count');
    } catch (e) {
      _log('❌ Badge API non supporté ou erreur: $e');
    }
  }

  void _clearBadge() {
    if (!kIsWeb) return;

    try {
      _webNotificationService.clearBadge();
      _log('⚫ Badge effacé');
    } catch (e) {
      _log('❌ Erreur effacement badge: $e');
    }
  }

  void _log(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _logs.add('[$timestamp] $message');
    });
    debugPrint('[$timestamp] $message');
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔥 Test Notifications Push'),
        backgroundColor: const Color(0xFF47C5FB),
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // PWA Status Card
              _buildCard(
                title: '📱 Status PWA',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusChip(
                      _isStandalone
                          ? '✅ PWA installée et lancée depuis l\'écran d\'accueil'
                          : '⚠️ PWA non installée - Ajouter à l\'écran d\'accueil pour notifications complètes',
                      _isStandalone ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Device: ${_isIOS ? 'iOS' : 'Desktop'} | '
                      'Browser: ${_isSafari ? 'Safari' : 'Other'} | '
                      'Mode: ${_isStandalone ? 'PWA' : 'Browser'}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),

              // Permissions & Token Card
              _buildCard(
                title: '🔔 Permissions & Token FCM',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatusChip(
                      _permissionStatus == 'granted'
                          ? '✅ Permissions accordées'
                          : _permissionStatus == 'denied'
                              ? '❌ Permissions refusées'
                              : '⚠️ Permissions non définies',
                      _permissionStatus == 'granted'
                          ? Colors.green
                          : _permissionStatus == 'denied'
                              ? Colors.red
                              : Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _requestPermissions,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF47C5FB),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('📱 Demander Permissions'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _getFCMToken,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF47C5FB),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('🔥 Obtenir Token FCM'),
                          ),
                        ),
                      ],
                    ),
                    if (_fcmToken != null) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Token FCM:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: SelectableText(
                          _fcmToken!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Test Notifications Card
              _buildCard(
                title: '🧪 Tests de Notifications',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _testBasicNotification,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF47C5FB),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('🔔 Basique'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _testChallengeNotification,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF47C5FB),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('🎯 Défi'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _testAchievementNotification,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF47C5FB),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('🏆 Succès'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _testStreakNotification,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF47C5FB),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('🔥 Série'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Badge Tests Card
              _buildCard(
                title: '🔴 Tests Badge iOS Safari 16.4+',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _setBadge(1),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF47C5FB),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Badge 1'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _setBadge(5),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF47C5FB),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Badge 5'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _setBadge(99),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF47C5FB),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Badge 99'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _clearBadge,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade600,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('⚫ Effacer'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _badgeSupported
                          ? '✅ Badge API supporté'
                          : '⚠️ Badge API limité (iOS Safari 16.4+ PWA requis)',
                      style: TextStyle(
                        fontSize: 12,
                        color: _badgeSupported ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),

              // Logs Card
              _buildCard(
                title: '📊 Logs en Temps Réel',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              _logs[index],
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _clearLogs,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('🧹 Effacer Logs'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color.shade800,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }
}
