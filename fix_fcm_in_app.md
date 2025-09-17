# 🚀 Fix FCM dans l'App DailyGrowth

## Le problème
Le FCM ne fonctionne que en HTTPS. Les tests locaux HTTP échouent normalement.

## ✅ Solution: Modifier le diagnostic dans l'app

### 1. Améliorer l'initialisation Firebase

Dans `WebNotificationService.dart`, ajouter une vérification d'initialisation :

```dart
Future<String?> generateFCMToken() async {
  if (!kIsWeb) return null;
  
  try {
    debugPrint('🔍 Attempting to generate FCM token...');
    
    // Wait for Firebase to be fully initialized
    await Future.delayed(Duration(seconds: 1));
    
    // Check if Firebase is ready
    final isReady = js.context.callMethod('eval', ['''
      (function() {
        return typeof window.firebaseApp !== 'undefined' && 
               typeof window.firebaseMessaging !== 'undefined';
      })()
    ''']);
    
    if (!isReady) {
      debugPrint('⚠️ Firebase not ready, waiting...');
      await Future.delayed(Duration(seconds: 2));
    }
    
    // Rest of the token generation code...
```

### 2. Test direct dans l'app

1. Ouvre ton app DailyGrowth sur iPhone
2. Va dans Profil → Test notifications  
3. Le token devrait se générer maintenant

### 3. Alternative: Force token via JavaScript

Dans l'app, ajoute un bouton "Force FCM Token" qui exécute :

```javascript
javascript:(async function(){
  try {
    const { getToken } = await import('https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging.js');
    const token = await getToken(window.firebaseMessaging, {
      vapidKey: 'BJe790aSYySweHjaldtDhKaWTx5BBQ0dskvXly3urJWFnFifeoWY1EA8wJnDvyUhIu_s_AZODY9ucqBi0FgMxXs'
    });
    if(token) {
      localStorage.setItem('fcm_token', token);
      alert('Token: ' + token.substring(0,50) + '...');
    }
  } catch(e) { alert('Erreur: ' + e.message); }
})()
```