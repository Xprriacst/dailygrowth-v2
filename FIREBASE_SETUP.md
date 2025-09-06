# Configuration Firebase pour DailyGrowth PWA

## 🚨 ÉTAPES OBLIGATOIRES

### 1. Créer un Projet Firebase

1. Aller sur [Firebase Console](https://console.firebase.google.com/)
2. Cliquer sur "Ajouter un projet"
3. Nommer votre projet : `dailygrowth-pwa`
4. Activer Google Analytics (optionnel)
5. Créer le projet

### 2. Configurer Firebase Cloud Messaging

#### Étape 2.1 : Ajouter une Application Web
1. Dans la console Firebase, cliquer sur l'icône Web `</>`
2. Saisir le nom d'app : `DailyGrowth PWA`
3. Cocher "Configurer également Firebase Hosting" (optionnel)
4. Enregistrer l'app

#### Étape 2.2 : Récupérer la Configuration
Vous obtiendrez un objet de configuration comme :
```javascript
const firebaseConfig = {
  apiKey: "AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  authDomain: "dailygrowth-pwa.firebaseapp.com",
  projectId: "dailygrowth-pwa",
  storageBucket: "dailygrowth-pwa.appspot.com",
  messagingSenderId: "123456789012",
  appId: "1:123456789012:web:abcdefghijklmnop"
};
```

### 3. Remplacer les Configurations

#### Fichier 1 : `web/sw.js`
Ligne 17-24, remplacer :
```javascript
const firebaseConfig = {
  apiKey: "VOTRE_VRAIE_API_KEY",
  authDomain: "dailygrowth-pwa.firebaseapp.com", 
  projectId: "dailygrowth-pwa",
  storageBucket: "dailygrowth-pwa.appspot.com",
  messagingSenderId: "VOTRE_SENDER_ID",
  appId: "VOTRE_APP_ID"
};
```

#### Fichier 2 : `web/firebase-messaging-sw.js`
Ligne 5-12, remplacer par la même configuration.

### 4. Générer une Clé Serveur

1. Dans Firebase Console → Paramètres du projet → Cloud Messaging
2. Onglet "Clés serveur Web"
3. Cliquer sur "Générer une paire de clés"
4. Copier la "Clé publique" générée

#### Mettre à jour `web/index.html`
Ajouter avant `</head>` :
```html
<script>
  // Configuration Firebase
  const firebaseConfig = {
    apiKey: "VOTRE_API_KEY",
    authDomain: "dailygrowth-pwa.firebaseapp.com",
    projectId: "dailygrowth-pwa", 
    storageBucket: "dailygrowth-pwa.appspot.com",
    messagingSenderId: "VOTRE_SENDER_ID",
    appId: "VOTRE_APP_ID"
  };
</script>
```

### 5. Configuration Supabase (Optionnel)

Pour stocker les tokens FCM des utilisateurs, ajouter une colonne à votre table `user_profiles` :

```sql
ALTER TABLE user_profiles 
ADD COLUMN fcm_token TEXT;
```

### 6. Tester la Configuration

#### Test Local
```bash
flutter run -d chrome --web-renderer html
```

#### Test de Production
1. Build : `flutter build web --web-renderer html`  
2. Servir depuis `build/web/`
3. Tester sur iOS Safari avec PWA installée

### 7. Fonctionnalités Disponibles

#### ✅ Après Configuration Complète

- **Notifications Push** : iOS Safari 16.4+, Android Chrome
- **Badges d'Application** : iOS Safari 16.4+ uniquement  
- **Notifications en Arrière-plan** : Via service worker
- **Clics sur Notifications** : Navigation automatique
- **Gestion des Permissions** : Native browser API

#### 📱 Types de Notifications Implémentés

1. **Défis Quotidiens** : `showChallengeNotification()`
2. **Citations** : `showQuoteNotification()`
3. **Succès** : `showAchievementNotification()` 
4. **Séries** : `showStreakNotification()`
5. **Rappels** : `showReminderNotification()`

### 8. API Backend (Optionnel)

Pour envoyer des notifications push depuis votre backend :

```javascript
// Exemple Node.js avec firebase-admin
const admin = require('firebase-admin');

const message = {
  notification: {
    title: '🎯 Nouveau défi !',
    body: 'Votre micro-défi quotidien vous attend'
  },
  data: {
    type: 'challenge',
    url: '/#/challenges',
    badge_count: '1'
  },
  token: 'USER_FCM_TOKEN'
};

admin.messaging().send(message);
```

## 🔧 Dépannage

### Problème : Notifications non reçues
- Vérifier que la PWA est installée sur l'écran d'accueil (iOS)
- Vérifier les permissions dans paramètres Safari
- Vérifier la configuration Firebase

### Problème : Badge non affiché
- iOS Safari 16.4+ uniquement
- PWA doit être ajoutée à l'écran d'accueil
- Vérifier `navigator.setAppBadge` dans console

### Problème : Service Worker erreurs  
- Vérifier la syntaxe dans `firebase-messaging-sw.js`
- Ouvrir DevTools → Application → Service Workers
- Regarder les logs d'erreurs

## 📋 Checklist Final

- [ ] Projet Firebase créé
- [ ] Configuration copiée dans `sw.js` et `firebase-messaging-sw.js`
- [ ] Clé publique générée et configurée
- [ ] PWA testée sur iOS Safari 16.4+
- [ ] Notifications push fonctionnelles
- [ ] Badge d'application fonctionnel
- [ ] Backend configuré (optionnel)

---

**Une fois ces étapes terminées, votre système de notifications PWA sera complètement fonctionnel sur iOS Safari 16.4+ et autres navigateurs supportés !**