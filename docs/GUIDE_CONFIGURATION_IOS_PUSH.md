# 📱 Guide Pas à Pas - Configuration Notifications Push iOS

Ce guide vous accompagne étape par étape pour finaliser la configuration des notifications push iOS.

---

## 📋 Checklist Préalable

Avant de commencer, vérifiez que vous avez :
- [ ] Un compte Firebase avec accès au projet `dailygrowth-pwa`
- [ ] Un compte Apple Developer (pour la clé APNs)
- [ ] Xcode installé sur Mac
- [ ] L'app iOS compilable (Bundle ID défini)

---

## Étape 1 : GoogleService-Info.plist

### 1.1 Accéder à Firebase Console

1. Ouvrez votre navigateur
2. Allez sur [Firebase Console](https://console.firebase.google.com/)
3. Connectez-vous avec votre compte Google
4. Sélectionnez le projet **`dailygrowth-pwa`**

### 1.2 Vérifier/Créer l'App iOS

**Si l'app iOS existe déjà :**
1. Cliquez sur l'icône ⚙️ (Settings) en haut à gauche
2. Dans "Your apps", cherchez l'app iOS
3. Si elle existe, passez à l'étape 1.3

**Si l'app iOS n'existe pas :**
1. Cliquez sur l'icône ⚙️ (Settings) en haut à gauche
2. Dans "Your apps", cliquez sur "Add app" ou l'icône iOS
3. Remplissez le formulaire :
   - **iOS bundle ID** : Le Bundle ID de votre app (ex: `com.dailygrowth.app`)
     - Pour trouver votre Bundle ID : Ouvrez `ios/Runner.xcodeproj` dans Xcode → Target "Runner" → General → Bundle Identifier
   - **App nickname** (optionnel) : "DailyGrowth iOS"
   - **App Store ID** (optionnel) : Laissez vide si pas encore publié
4. Cliquez sur "Register app"

### 1.3 Télécharger GoogleService-Info.plist

1. Dans la page de l'app iOS, vous verrez "Download GoogleService-Info.plist"
2. Cliquez sur le bouton pour télécharger
3. Le fichier se télécharge dans votre dossier Téléchargements

### 1.4 Placer le fichier dans le projet

**Option A : Via Finder (Recommandé)**
1. Ouvrez Finder
2. Naviguez vers : `/Users/alexandreerrasti/Downloads/dailygrowth v2/ios/Runner/`
3. Copiez le fichier `GoogleService-Info.plist` téléchargé dans ce dossier
4. Renommez-le si nécessaire pour qu'il s'appelle exactement `GoogleService-Info.plist`

**Option B : Via Terminal**
```bash
cd "/Users/alexandreerrasti/Downloads/dailygrowth v2/ios/Runner"
# Copiez votre fichier téléchargé ici
cp ~/Downloads/GoogleService-Info.plist .
```

### 1.5 Ajouter au projet Xcode (si nécessaire)

1. Ouvrez Xcode
2. Ouvrez le workspace : `ios/Runner.xcworkspace`
3. Dans le navigateur de fichiers (panneau gauche), cliquez droit sur le dossier "Runner"
4. Sélectionnez "Add Files to Runner..."
5. Naviguez vers `ios/Runner/GoogleService-Info.plist`
6. Cochez "Copy items if needed" (si le fichier n'est pas déjà dans le dossier)
7. Cochez "Add to targets: Runner"
8. Cliquez sur "Add"

### 1.6 Vérification

Vérifiez que le fichier est présent :
```bash
ls -la "/Users/alexandreerrasti/Downloads/dailygrowth v2/ios/Runner/GoogleService-Info.plist"
```

**Résultat attendu** : Le fichier doit exister et avoir une taille > 0

---

## Étape 2 : Capabilities Xcode

### 2.1 Ouvrir le projet dans Xcode

1. Ouvrez Xcode
2. File → Open...
3. Naviguez vers : `/Users/alexandreerrasti/Downloads/dailygrowth v2/ios/`
4. Sélectionnez **`Runner.xcworkspace`** (⚠️ IMPORTANT : pas .xcodeproj)
5. Cliquez sur "Open"

### 2.2 Sélectionner le Target

1. Dans la barre latérale gauche, cliquez sur le projet "Runner" (icône bleue en haut)
2. Dans le panneau central, sélectionnez le target **"Runner"** (sous "TARGETS")

### 2.3 Ajouter Push Notifications Capability

1. Cliquez sur l'onglet **"Signing & Capabilities"** en haut
2. Cliquez sur le bouton **"+ Capability"** en haut à gauche
3. Dans la liste, cherchez **"Push Notifications"**
4. Double-cliquez dessus ou cliquez sur le bouton "+" à côté
5. ✅ La capability "Push Notifications" doit maintenant apparaître dans la liste

### 2.4 Ajouter Background Modes Capability

1. Toujours dans "Signing & Capabilities"
2. Si "Background Modes" n'existe pas déjà, cliquez sur **"+ Capability"**
3. Cherchez **"Background Modes"** et ajoutez-le
4. Une fois ajouté, cochez la case **"Remote notifications"** dans la liste des modes

### 2.5 Vérification

Vous devriez voir dans "Signing & Capabilities" :
- ✅ **Push Notifications** (sans case à cocher, c'est normal)
- ✅ **Background Modes** avec "Remote notifications" coché

### 2.6 Vérifier le Signing (Bonus)

Pendant que vous êtes dans "Signing & Capabilities" :
1. Vérifiez que "Automatically manage signing" est coché
2. Vérifiez que votre Team Apple Developer est sélectionnée
3. Si vous voyez des erreurs de provisioning, corrigez-les maintenant

---

## Étape 3 : Configuration APNs dans Firebase

### 3.1 Obtenir la Clé APNs depuis Apple Developer

**Option A : Si vous avez déjà une clé APNs**
1. Allez sur [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)
2. Connectez-vous avec votre compte Apple Developer
3. Trouvez votre clé APNs dans la liste
4. Notez :
   - Le **Key ID** (ex: ABC123DEF4)
   - L'équipe a un **Team ID** (visible en haut à droite, ex: XYZ987ABC6)
5. Si vous avez le fichier .p8, téléchargez-le (vous ne pourrez le télécharger qu'une fois)

**Option B : Créer une nouvelle clé APNs**
1. Allez sur [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)
2. Cliquez sur le bouton **"+"** en haut à droite
3. Remplissez le formulaire :
   - **Key Name** : "DailyGrowth APNs Key" (ou un nom de votre choix)
   - Cochez **"Apple Push Notifications service (APNs)"**
4. Cliquez sur "Continue" puis "Register"
5. **⚠️ IMPORTANT** : Téléchargez le fichier .p8 immédiatement (vous ne pourrez le faire qu'une fois)
6. Notez le **Key ID** affiché
7. Notez votre **Team ID** (visible en haut à droite du portail)

### 3.2 Uploader la clé dans Firebase

1. Retournez dans [Firebase Console](https://console.firebase.google.com/project/dailygrowth-pwa)
2. Cliquez sur ⚙️ (Settings) → **Project settings**
3. Allez dans l'onglet **"Cloud Messaging"**
4. Faites défiler jusqu'à la section **"Apple app configuration"**
5. Vous verrez votre app iOS listée
6. Cliquez sur **"Upload"** à côté de "APNs Authentication Key" (ou "APNs Certificates" si vous utilisez un certificat)

**Si vous utilisez une clé APNs (recommandé) :**
1. Cliquez sur "Upload" → "APNs Authentication Key"
2. Cliquez sur "Choose file" et sélectionnez votre fichier `.p8`
3. Entrez le **Key ID** (ex: ABC123DEF4)
4. Entrez le **Team ID** (ex: XYZ987ABC6)
5. Cliquez sur "Upload"

**Si vous utilisez un certificat APNs :**
1. Cliquez sur "Upload" → "APNs Certificates"
2. Sélectionnez votre fichier `.p12`
3. Entrez le mot de passe du certificat
4. Cliquez sur "Upload"

### 3.3 Vérification

Après l'upload, vous devriez voir :
- ✅ Un statut "Active" ou une coche verte
- La date d'upload
- Le Key ID ou le nom du certificat

---

## Étape 4 : Vérification et Tests

### 4.1 Vérifier la Configuration

**Vérifier GoogleService-Info.plist :**
```bash
cd "/Users/alexandreerrasti/Downloads/dailygrowth v2"
ls -la ios/Runner/GoogleService-Info.plist
```
✅ Le fichier doit exister

**Vérifier le Bundle ID correspond :**
```bash
# Ouvrir le fichier et vérifier le BUNDLE_ID
cat ios/Runner/GoogleService-Info.plist | grep -A 1 "BUNDLE_ID"
```
✅ Le BUNDLE_ID doit correspondre à celui de votre app dans Xcode

### 4.2 Nettoyer et Rebuild

```bash
cd "/Users/alexandreerrasti/Downloads/dailygrowth v2"

# Nettoyer
flutter clean

# Récupérer les dépendances
flutter pub get

# Installer les pods iOS
cd ios
pod install
cd ..

# Build iOS (sans signature, pour test)
flutter build ios --no-codesign
```

**Résultat attendu** : Build réussi sans erreurs liées à Firebase

### 4.3 Test sur Device iOS Réel

**Prérequis :**
- iPhone connecté en USB
- Mode développeur activé sur l'iPhone
- Certificat de développement configuré dans Xcode

**Étapes :**
1. Ouvrez Xcode
2. Ouvrez `ios/Runner.xcworkspace`
3. Sélectionnez votre iPhone dans la liste des devices (en haut)
4. Cliquez sur le bouton "Run" (▶️) ou appuyez sur `Cmd + R`
5. L'app se compile et s'installe sur l'iPhone

**Vérifier les logs :**
1. Dans Xcode, ouvrez la console (View → Debug Area → Activate Console)
2. Lancez l'app
3. Cherchez dans les logs :
   ```
   ✅ iOS Push Notifications: Permissions granted
   🔑 FCM Token iOS: ...
   ✅ FCM Token saved to database
   ```

### 4.4 Vérifier le Token en Base de Données

**Via Supabase Dashboard :**
1. Allez sur votre projet Supabase
2. SQL Editor → Nouvelle requête
3. Exécutez :
```sql
SELECT 
  id, 
  fcm_token, 
  notifications_enabled,
  created_at
FROM user_profiles 
WHERE fcm_token IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;
```

**Résultat attendu** : Vous devriez voir votre token FCM pour l'utilisateur iOS

### 4.5 Test d'Envoi de Notification

**Option A : Via Supabase Edge Function (Recommandé)**

1. Dans Supabase Dashboard → Edge Functions
2. Trouvez la fonction `send-push-notification`
3. Testez avec :
```json
{
  "user_id": "VOTRE_USER_ID",
  "title": "Test iOS Push",
  "body": "Ceci est un test de notification push iOS",
  "type": "test"
}
```

**Option B : Via SQL (si vous avez une fonction SQL)**

```sql
-- Remplacer USER_ID par votre ID utilisateur
SELECT * FROM send_push_notification(
  'USER_ID',
  'Test iOS Push',
  'Ceci est un test',
  'test'
);
```

**Résultat attendu** : 
- Notification reçue sur l'iPhone
- Logs Firebase montrent "sent: true"

---

## 🚨 Dépannage

### Problème : GoogleService-Info.plist introuvable

**Symptôme** : Erreur à l'exécution "FirebaseApp.configure() failed"

**Solution** :
1. Vérifiez que le fichier est dans `ios/Runner/`
2. Vérifiez qu'il est ajouté au target dans Xcode
3. Nettoyez et rebuild : `flutter clean && flutter pub get && cd ios && pod install`

### Problème : Token FCM null

**Symptôme** : Logs montrent "FCM Token is null"

**Solutions** :
1. Vérifiez que GoogleService-Info.plist est correct
2. Vérifiez que les permissions sont accordées (Settings → ChallengeMe → Notifications)
3. Vérifiez que Firebase est initialisé dans AppDelegate
4. Réinstallez l'app sur le device

### Problème : Notifications non reçues

**Symptôme** : Token présent mais notifications non reçues

**Solutions** :
1. Vérifiez APNs configuré dans Firebase Console
2. Vérifiez que le token est bien en base de données
3. Vérifiez que `notifications_enabled = true` pour l'utilisateur
4. Vérifiez les logs backend pour erreurs FCM
5. Testez avec un token web pour comparer

### Problème : Build échoue

**Symptôme** : Erreurs de compilation iOS

**Solutions** :
1. Vérifiez que les pods sont à jour : `cd ios && pod install`
2. Vérifiez que Firebase est dans Podfile.lock
3. Nettoyez : `flutter clean && flutter pub get`
4. Supprimez DerivedData : Xcode → Preferences → Locations → DerivedData → Delete

### Problème : Permissions refusées

**Symptôme** : "Permissions denied" dans les logs

**Solutions** :
1. Allez dans Settings → ChallengeMe → Notifications
2. Activez toutes les options
3. Réinstallez l'app
4. Réessayez

---

## ✅ Checklist Finale

Avant de considérer la configuration terminée :

- [ ] GoogleService-Info.plist présent et ajouté au projet Xcode
- [ ] Push Notifications capability ajoutée dans Xcode
- [ ] Background Modes → Remote notifications activé
- [ ] Clé APNs uploadée dans Firebase Console
- [ ] Build iOS réussi sans erreurs
- [ ] App installée sur device iOS réel
- [ ] Permissions notifications accordées
- [ ] Token FCM visible dans les logs
- [ ] Token sauvegardé en base de données
- [ ] Notification test reçue avec succès

---

## 📞 Support

Si vous rencontrez des problèmes :

1. **Vérifiez les logs** : Xcode Console, Flutter logs, Firebase Console
2. **Vérifiez la documentation** : `docs/IMPLEMENTATION_IOS_PUSH.md`
3. **Vérifiez Firebase Console** : Project Settings → Cloud Messaging
4. **Vérifiez Apple Developer** : Certificats et clés valides

---

**Bon courage ! 🚀**

Une fois toutes ces étapes complétées, votre système de notifications push iOS sera opérationnel.



