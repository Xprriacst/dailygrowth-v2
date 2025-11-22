# 📱 Stratégie de Déploiement Progressif - Notifications Push iOS

## 🎯 Objectif
Mettre en place un système de notifications push iOS natif fonctionnel de manière progressive et testable, sans casser l'existant.

## 📊 État Actuel

### ✅ Ce qui fonctionne
- **Web (PWA)** : Notifications push via Firebase Cloud Messaging fonctionnelles
- **Android** : Notifications locales via `flutter_local_notifications`
- **iOS** : Notifications locales via `flutter_local_notifications`
- **Infrastructure** : Firebase configuré, FCM tokens stockés en base

### ❌ Ce qui ne fonctionne pas
- **iOS natif** : Pas de notifications push distantes (APNs)
- **iOS natif** : Pas de réception de notifications en arrière-plan
- **iOS natif** : Pas de gestion des tokens FCM pour iOS

## 🗺️ Plan de Déploiement en 4 Phases

### Phase 1 : Infrastructure et Configuration (Fondations) 🔧
**Objectif** : Préparer l'environnement iOS pour recevoir des notifications push

**Tâches** :
1. ✅ Ajouter `GoogleService-Info.plist` dans le projet iOS
2. ✅ Configurer Firebase dans `AppDelegate.swift`
3. ✅ Vérifier les capabilities dans Xcode (Push Notifications, Background Modes)
4. ✅ Configurer les certificats APNs dans Firebase Console
5. ✅ Tester la connexion Firebase → APNs

**Critères de succès** :
- L'app iOS peut se connecter à Firebase
- Les certificats APNs sont valides dans Firebase Console
- Pas d'erreurs de build iOS

**Risques** : Faible (configuration uniquement, pas de changement fonctionnel)

---

### Phase 2 : Service de Notifications iOS (Code Dart) 📱
**Objectif** : Créer un service dédié pour gérer les notifications push iOS

**Tâches** :
1. ✅ Créer `lib/services/ios_push_notification_service.dart`
2. ✅ Initialiser Firebase Messaging pour iOS
3. ✅ Gérer les permissions iOS (demande explicite)
4. ✅ Récupérer et stocker le token FCM iOS
5. ✅ Gérer les notifications en premier plan
6. ✅ Gérer les notifications en arrière-plan
7. ✅ Gérer les clics sur notifications

**Architecture** :
```dart
class IOSPushNotificationService {
  // Initialisation Firebase
  Future<void> initialize()
  
  // Permissions
  Future<bool> requestPermissions()
  
  // Token FCM
  Future<String?> getFCMToken()
  Future<void> saveTokenToDatabase(String token)
  
  // Gestion notifications
  void setupForegroundHandler()
  void setupBackgroundHandler()
  void handleNotificationTap(RemoteMessage message)
}
```

**Critères de succès** :
- Le service s'initialise sans erreur
- Les permissions sont demandées correctement
- Le token FCM est récupéré et sauvegardé
- Les notifications en premier plan sont affichées

**Risques** : Moyen (nouveau code, mais isolé dans un service)

---

### Phase 3 : Intégration Progressive (Feature Flag) 🚀
**Objectif** : Intégrer le service iOS de manière progressive avec feature flag

**Tâches** :
1. ✅ Ajouter un feature flag `ios_push_notifications_enabled` dans Supabase
2. ✅ Modifier `NotificationService` pour utiliser `IOSPushNotificationService` si flag activé
3. ✅ Créer un écran de test dans l'app (admin/dev uniquement)
4. ✅ Tester avec un utilisateur de test
5. ✅ Monitorer les logs et erreurs

**Feature Flag** :
```sql
-- Table feature_flags
CREATE TABLE IF NOT EXISTS feature_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  flag_name TEXT UNIQUE NOT NULL,
  enabled BOOLEAN DEFAULT false,
  enabled_for_users TEXT[] DEFAULT ARRAY[]::TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Flag pour iOS push
INSERT INTO feature_flags (flag_name, enabled, enabled_for_users)
VALUES ('ios_push_notifications', false, ARRAY[]::TEXT[]);
```

**Intégration dans NotificationService** :
```dart
Future<void> initialize() async {
  // ... code existant ...
  
  // iOS Push Notifications (si feature flag activé)
  if (Platform.isIOS && !kIsWeb) {
    final isEnabled = await _checkFeatureFlag('ios_push_notifications');
    if (isEnabled) {
      await _iosPushService.initialize();
    }
  }
}
```

**Critères de succès** :
- Le feature flag fonctionne
- L'intégration n'affecte pas les autres plateformes
- Les tests passent avec le flag activé/désactivé
- Pas de régression sur Android/Web

**Risques** : Faible (feature flag permet rollback immédiat)

---

### Phase 4 : Déploiement Progressif (Canary → Beta → Production) 🎯
**Objectif** : Déployer progressivement aux utilisateurs

**Étape 4.1 : Canary (1-5 utilisateurs)**
- Activer le flag pour quelques utilisateurs de test
- Monitorer pendant 3-7 jours
- Vérifier : réception notifications, pas de crash, tokens valides

**Étape 4.2 : Beta (10-20% utilisateurs)**
- Activer pour un pourcentage d'utilisateurs iOS
- Monitorer métriques : taux de succès, erreurs, feedback
- Ajuster si nécessaire

**Étape 4.3 : Production (100%)**
- Activer pour tous les utilisateurs iOS
- Monitorer en continu
- Documenter les problèmes courants

**Métriques à suivre** :
- Taux de permission accordée
- Taux de token FCM généré
- Taux de notification reçue
- Taux d'erreur
- Crash rate

**Critères de succès** :
- 80%+ des utilisateurs iOS ont activé les notifications
- 95%+ des notifications sont reçues avec succès
- Pas d'augmentation du crash rate
- Feedback utilisateur positif

**Risques** : Faible (déploiement progressif avec monitoring)

---

## 🔧 Détails Techniques par Phase

### Phase 1 : Configuration iOS

#### 1.1 GoogleService-Info.plist
```bash
# Télécharger depuis Firebase Console
# Projet: dailygrowth-pwa
# iOS App → Télécharger GoogleService-Info.plist
# Placer dans: ios/Runner/GoogleService-Info.plist
```

#### 1.2 AppDelegate.swift
```swift
import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Firebase
    FirebaseApp.configure()
    
    // Register for remote notifications
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    application.registerForRemoteNotifications()
    
    // Set FCM messaging delegate
    Messaging.messaging().delegate = self
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle APNs token
  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }
  
  // Handle notification registration failure
  override func application(_ application: UIApplication,
                            didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Failed to register for remote notifications: \(error)")
  }
}

// FCM Messaging Delegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("FCM Token: \(fcmToken ?? "nil")")
    // Token sera récupéré par Flutter via firebase_messaging plugin
  }
}
```

#### 1.3 Xcode Capabilities
- Ouvrir `ios/Runner.xcworkspace` dans Xcode
- Sélectionner Runner → Signing & Capabilities
- Ajouter :
  - ✅ Push Notifications
  - ✅ Background Modes → Remote notifications

#### 1.4 Firebase Console - APNs Configuration
1. Aller dans Firebase Console → Project Settings → Cloud Messaging
2. Section "Apple app configuration"
3. Uploader la clé APNs (ou certificat)
   - Option A : APNs Auth Key (recommandé)
   - Option B : APNs Certificate
4. Vérifier que l'App ID correspond au Bundle ID iOS

---

### Phase 2 : Service iOS Push

#### 2.1 Structure du Service
```dart
// lib/services/ios_push_notification_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class IOSPushNotificationService {
  static final IOSPushNotificationService _instance = 
      IOSPushNotificationService._internal();
  factory IOSPushNotificationService() => _instance;
  IOSPushNotificationService._internal();

  FirebaseMessaging? _messaging;
  bool _isInitialized = false;
  String? _fcmToken;

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (!Platform.isIOS || kIsWeb) return;

    try {
      _messaging = FirebaseMessaging.instance;
      
      // Request permissions
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ iOS Push Notifications: Permissions granted');
        
        // Get FCM token
        await _getAndSaveToken();
        
        // Setup handlers
        _setupForegroundHandler();
        _setupBackgroundHandler();
        _setupTokenRefreshHandler();
        
        _isInitialized = true;
      } else {
        debugPrint('❌ iOS Push Notifications: Permissions denied');
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize iOS Push: $e');
    }
  }

  Future<void> _getAndSaveToken() async {
    try {
      _fcmToken = await _messaging!.getToken();
      if (_fcmToken != null) {
        debugPrint('🔑 FCM Token iOS: ${_fcmToken!.substring(0, 20)}...');
        await _saveTokenToDatabase(_fcmToken!);
      }
    } catch (e) {
      debugPrint('❌ Failed to get FCM token: $e');
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    // Save to Supabase user_profiles.fcm_token
    // Implementation similar to web version
  }

  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📨 Foreground notification: ${message.notification?.title}');
      // Show local notification
    });
  }

  void _setupBackgroundHandler() {
    // Background handler must be top-level function
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  void _setupTokenRefreshHandler() {
    _messaging!.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM Token refreshed: ${newToken.substring(0, 20)}...');
      _saveTokenToDatabase(newToken);
    });
  }

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;
}

// Top-level function for background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📨 Background notification: ${message.notification?.title}');
  // Handle background notification
}
```

---

### Phase 3 : Feature Flag

#### 3.1 Migration SQL
```sql
-- Créer table feature_flags si n'existe pas
CREATE TABLE IF NOT EXISTS feature_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  flag_name TEXT UNIQUE NOT NULL,
  enabled BOOLEAN DEFAULT false,
  enabled_for_users TEXT[] DEFAULT ARRAY[]::TEXT[],
  metadata JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE feature_flags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Feature flags are readable by authenticated users"
  ON feature_flags FOR SELECT
  USING (auth.role() = 'authenticated');

-- Insert iOS push flag
INSERT INTO feature_flags (flag_name, enabled, enabled_for_users)
VALUES ('ios_push_notifications', false, ARRAY[]::TEXT[])
ON CONFLICT (flag_name) DO NOTHING;
```

#### 3.2 Service Feature Flag
```dart
// lib/services/feature_flag_service.dart
class FeatureFlagService {
  Future<bool> isEnabled(String flagName, {String? userId}) async {
    final client = await SupabaseService().client;
    
    final response = await client
        .from('feature_flags')
        .select()
        .eq('flag_name', flagName)
        .maybeSingle();
    
    if (response == null) return false;
    
    final enabled = response['enabled'] as bool;
    final enabledForUsers = 
        (response['enabled_for_users'] as List?)?.cast<String>() ?? [];
    
    // Check global flag
    if (!enabled) return false;
    
    // Check user-specific flag
    if (userId != null && enabledForUsers.isNotEmpty) {
      return enabledForUsers.contains(userId);
    }
    
    return enabled;
  }
}
```

---

## 📊 Monitoring et Métriques

### Métriques Clés
1. **Taux de permission** : % utilisateurs iOS ayant accordé permissions
2. **Taux de token** : % utilisateurs iOS avec token FCM valide
3. **Taux de réception** : % notifications reçues avec succès
4. **Taux d'erreur** : % échecs d'envoi
5. **Latence** : Temps entre envoi et réception

### Dashboard SQL
```sql
-- Vue pour monitoring
CREATE OR REPLACE VIEW ios_push_metrics AS
SELECT 
  COUNT(DISTINCT up.id) FILTER (WHERE up.fcm_token IS NOT NULL) as users_with_token,
  COUNT(DISTINCT up.id) FILTER (WHERE up.notifications_enabled = true) as users_enabled,
  COUNT(DISTINCT up.id) as total_ios_users,
  ROUND(
    100.0 * COUNT(DISTINCT up.id) FILTER (WHERE up.fcm_token IS NOT NULL) / 
    NULLIF(COUNT(DISTINCT up.id), 0), 
    2
  ) as token_rate_percent
FROM user_profiles up
WHERE up.fcm_token IS NOT NULL 
  OR up.notifications_enabled = true;
```

---

## 🚨 Plan de Rollback

### Si problème détecté
1. **Désactiver le feature flag** immédiatement
   ```sql
   UPDATE feature_flags 
   SET enabled = false 
   WHERE flag_name = 'ios_push_notifications';
   ```

2. **Vérifier les logs** pour identifier le problème

3. **Corriger** et re-tester en canary

4. **Réactiver** progressivement

### Points de contrôle
- Après Phase 1 : Build iOS fonctionne
- Après Phase 2 : Service s'initialise sans erreur
- Après Phase 3 : Feature flag fonctionne
- Après Phase 4.1 : Canary stable 3 jours
- Après Phase 4.2 : Beta stable 7 jours

---

## 📝 Checklist de Déploiement

### Phase 1
- [ ] GoogleService-Info.plist ajouté
- [ ] AppDelegate.swift configuré
- [ ] Capabilities Xcode configurées
- [ ] APNs configuré dans Firebase
- [ ] Build iOS réussi
- [ ] Test connexion Firebase

### Phase 2
- [ ] Service iOS créé
- [ ] Permissions demandées
- [ ] Token FCM récupéré
- [ ] Token sauvegardé en base
- [ ] Handler premier plan fonctionne
- [ ] Handler arrière-plan fonctionne

### Phase 3
- [ ] Table feature_flags créée
- [ ] Service feature flag créé
- [ ] Intégration dans NotificationService
- [ ] Tests avec flag activé/désactivé
- [ ] Pas de régression Android/Web

### Phase 4
- [ ] Canary : 3-5 utilisateurs testent 3 jours
- [ ] Beta : 10-20% utilisateurs testent 7 jours
- [ ] Production : 100% avec monitoring
- [ ] Documentation utilisateur créée

---

## 🎯 Timeline Estimé

- **Phase 1** : 2-3 jours (configuration)
- **Phase 2** : 3-5 jours (développement)
- **Phase 3** : 2-3 jours (intégration)
- **Phase 4.1 Canary** : 3-7 jours (tests)
- **Phase 4.2 Beta** : 7-14 jours (validation)
- **Phase 4.3 Production** : Continu (monitoring)

**Total estimé** : 3-4 semaines pour déploiement complet

---

## 📚 Ressources

- [Firebase iOS Setup](https://firebase.google.com/docs/cloud-messaging/ios/client)
- [APNs Configuration](https://developer.apple.com/documentation/usernotifications)
- [Flutter Firebase Messaging](https://firebase.flutter.dev/docs/messaging/overview)
- [Feature Flags Best Practices](https://launchdarkly.com/blog/feature-flag-best-practices/)

---

## ✅ Prochaines Étapes

1. **Valider cette stratégie** avec l'équipe
2. **Commencer Phase 1** : Configuration iOS
3. **Tester chaque phase** avant de passer à la suivante
4. **Documenter** les problèmes rencontrés
5. **Itérer** selon les retours




