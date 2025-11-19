import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sizer/sizer.dart';
import 'dart:io' show Platform;

import '../../services/notification_service.dart';
import '../../services/web_notification_service.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({Key? key}) : super(key: key);

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final _notificationService = NotificationService();
  WebNotificationService? _webNotificationService;

  final List<String> _logs = [];
  bool _isLoading = false;
  String? _fcmToken;
  String _permissionStatus = 'Inconnu';
  String _platform = '';

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    setState(() {
      _isLoading = true;
    });

    _addLog('🚀 Initialisation de la page de test...');

    // Détection de la plateforme
    if (kIsWeb) {
      _platform = 'Web (PWA)';
      _webNotificationService = WebNotificationService();
      _addLog('📱 Plateforme détectée: Web/PWA');
      await _checkWebPermissionsAndToken();
    } else {
      try {
        if (Platform.isAndroid) {
          _platform = 'Android';
        } else if (Platform.isIOS) {
          _platform = 'iOS';
        } else if (Platform.isMacOS) {
          _platform = 'macOS';
        } else if (Platform.isWindows) {
          _platform = 'Windows';
        } else if (Platform.isLinux) {
          _platform = 'Linux';
        } else {
          _platform = 'Mobile';
        }
        _addLog('📱 Plateforme détectée: $_platform');
      } catch (e) {
        _platform = 'Mobile';
        _addLog('📱 Plateforme détectée: Mobile (fallback)');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _checkWebPermissionsAndToken() async {
    if (_webNotificationService == null) return;

    try {
      // Vérifier les permissions
      _addLog('🔍 Vérification des permissions...');
      final permissionResult = await _webNotificationService!.requestPermission();

      setState(() {
        _permissionStatus = permissionResult == 'granted' ? 'Accordée ✅' : 'Refusée ❌';
      });
      _addLog('🔐 Permission: $_permissionStatus');

      // Récupérer le token FCM
      if (permissionResult == 'granted') {
        _addLog('🔑 Récupération du token FCM...');
        final token = await _webNotificationService!.getFCMToken();

        if (token != null && token.isNotEmpty) {
          setState(() {
            _fcmToken = token;
          });
          final tokenPreview = token.length > 20 ? token.substring(0, 20) : token;
          _addLog('✅ Token FCM récupéré: $tokenPreview...');
        } else {
          _addLog('⚠️ Aucun token FCM trouvé, génération...');
          final newToken = await _webNotificationService!.generateFCMToken();
          setState(() {
            _fcmToken = newToken;
          });
          final tokenPreview = newToken != null && newToken.length > 20
              ? newToken.substring(0, 20)
              : (newToken ?? 'erreur');
          _addLog('✅ Nouveau token généré: $tokenPreview...');
        }
      }
    } catch (e) {
      _addLog('❌ Erreur lors de la vérification: $e');
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $message');
      // Limiter à 50 logs
      if (_logs.length > 50) {
        _logs.removeLast();
      }
    });
  }

  Future<void> _testInstantNotification() async {
    _addLog('🔔 Test de notification instantanée...');
    setState(() {
      _isLoading = true;
    });

    try {
      if (kIsWeb && _webNotificationService != null) {
        // Test pour web
        await _webNotificationService!.showNotification(
          title: '🎯 Test Notification',
          body: 'Ceci est une notification de test instantanée !',
          data: {'test': 'true', 'timestamp': DateTime.now().toString()},
        );
        _addLog('✅ Notification web envoyée');
      } else {
        // Test pour mobile
        await _notificationService.sendInstantNotification(
          title: '🎯 Test Notification',
          body: 'Ceci est une notification de test instantanée !',
        );
        _addLog('✅ Notification mobile envoyée');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification envoyée ! Vérifiez vos notifications.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _addLog('❌ Erreur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testScheduledNotification() async {
    _addLog('⏰ Test de notification programmée (dans 10 secondes)...');
    setState(() {
      _isLoading = true;
    });

    try {
      final scheduledTime = DateTime.now().add(const Duration(seconds: 10));

      if (kIsWeb && _webNotificationService != null) {
        // Pour web, on simule avec un délai
        _addLog('⏳ Programmation pour ${scheduledTime.toString().substring(11, 19)}');

        Future.delayed(const Duration(seconds: 10), () async {
          await _webNotificationService!.showNotification(
            title: '⏰ Notification programmée',
            body: 'Cette notification était programmée il y a 10 secondes !',
            data: {'scheduled': 'true'},
          );
          _addLog('✅ Notification programmée envoyée');
        });

        _addLog('✅ Notification programmée pour dans 10 secondes');
      } else {
        // Pour mobile, utiliser le vrai système de scheduling
        // Note: Ceci nécessite une implémentation plus complexe avec flutter_local_notifications
        _addLog('⚠️ Scheduling natif non implémenté dans ce test');
        _addLog('💡 Utilisation d\'un délai simulé...');

        Future.delayed(const Duration(seconds: 10), () async {
          await _notificationService.sendInstantNotification(
            title: '⏰ Notification programmée',
            body: 'Cette notification était programmée il y a 10 secondes !',
          );
          _addLog('✅ Notification programmée envoyée');
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification programmée pour dans 10 secondes !'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _addLog('❌ Erreur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testAchievementNotification() async {
    _addLog('🏆 Test de notification de succès...');
    setState(() {
      _isLoading = true;
    });

    try {
      if (kIsWeb && _webNotificationService != null) {
        await _webNotificationService!.showAchievementNotification(
          title: 'Premier test réussi !',
          description: 'Vous avez testé les notifications',
          pointsEarned: 10,
        );
        _addLog('✅ Notification de succès web envoyée');
      } else {
        await _notificationService.sendAchievementNotification(
          userId: 'test-user',
          achievementName: 'Premier test réussi !',
          description: 'Vous avez testé les notifications',
          pointsEarned: 10,
        );
        _addLog('✅ Notification de succès mobile envoyée');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification de succès envoyée !'),
            backgroundColor: Colors.amber,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _addLog('❌ Erreur: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
    _addLog('🗑️ Logs effacés');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications Push'),
        backgroundColor: const Color(0xFF47C5FB),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializePage,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading && _logs.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Informations de statut
                    _buildStatusCard(),
                    SizedBox(height: 3.h),

                    // Boutons de test
                    _buildTestButtons(),
                    SizedBox(height: 3.h),

                    // Zone de logs
                    _buildLogsSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'État du système',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF47C5FB),
              ),
            ),
            SizedBox(height: 2.h),
            _buildStatusRow('Plateforme', _platform, Icons.phone_android),
            SizedBox(height: 1.h),
            _buildStatusRow('Permissions', _permissionStatus, Icons.security),
            if (_fcmToken != null) ...[
              SizedBox(height: 1.h),
              _buildStatusRow(
                'Token FCM',
                '${_fcmToken!.substring(0, 20)}...',
                Icons.key,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: Colors.grey[600]),
        SizedBox(width: 2.w),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[700],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTestButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tests disponibles',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _testInstantNotification,
          icon: const Icon(Icons.notifications_active),
          label: const Text('Notification instantanée'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF47C5FB),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 1.5.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        SizedBox(height: 1.5.h),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _testScheduledNotification,
          icon: const Icon(Icons.schedule),
          label: const Text('Notification dans 10s'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 1.5.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        SizedBox(height: 1.5.h),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _testAchievementNotification,
          icon: const Icon(Icons.emoji_events),
          label: const Text('Notification de succès'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[700],
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 1.5.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Journal d\'activité',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _clearLogs,
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Effacer'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Container(
          height: 40.h,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: _logs.isEmpty
              ? Center(
                  child: Text(
                    'Aucun log pour le moment',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14.sp,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(2.w),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 1.h),
                      child: Text(
                        _logs[index],
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontFamily: 'monospace',
                          color: Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
