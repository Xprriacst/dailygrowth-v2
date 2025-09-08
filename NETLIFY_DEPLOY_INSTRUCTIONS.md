# 🚀 Déploiement DailyGrowth PWA sur Netlify

## 📦 Fichiers Prêts
- ✅ **App complète** : `dailygrowth-pwa-complete.zip` sur le bureau
- ✅ **Branche GitHub** : `feature/pwa-notifications-push` 
- ✅ **Configuration Netlify** : netlify.toml, _headers, _redirects

## 🌐 Option 1 - Déploiement Git (Recommandé)

### Étapes :
1. **Aller sur Netlify** : https://app.netlify.com
2. **New site from Git** → **GitHub**
3. **Sélectionner le repo** : `dailygrowth-v2` (ou ton nom de repo)
4. **Configuration** :
   - **Branch to deploy** : `feature/pwa-notifications-push`
   - **Build command** : `flutter build web`
   - **Publish directory** : `build/web`
5. **Deploy site**

### Avantages :
- ✅ Déploiement automatique à chaque push
- ✅ Gestion des versions
- ✅ Preview des PR
- ✅ Rollback facile

## 📂 Option 2 - Deploy Manuel

### Étapes :
1. **Netlify Drop** : https://app.netlify.com/drop
2. **Glisser** `dailygrowth-pwa-complete.zip`
3. **Attendre le déploiement**

## ⚙️ Configuration Post-Déploiement

### 1. Nom du Site (Optionnel)
- **Site settings** → **Change site name**
- Suggestion : `dailygrowth-pwa` ou `dailygrowth-app`

### 2. Domaine Personnalisé (Optionnel)
- **Domain management** → **Add custom domain**
- Ex: `app.dailygrowth.com`

### 3. Variables d'Environnement (Si nécessaire)
- **Site settings** → **Environment variables**
- Ajouter clés API Supabase si différentes

## 🔥 Fonctionnalités PWA Disponibles

### ✅ Après Déploiement
- **Notifications Push** : iOS Safari 16.4+ (mode PWA)
- **Badge API** : Compteurs sur icône PWA
- **Service Workers** : Firebase FCM intégré
- **Installation PWA** : "Ajouter à l'écran d'accueil"
- **Mode Offline** : Cache des ressources
- **HTTPS** : Automatique avec Netlify

### 🧪 Tests à Effectuer
1. **Ouvrir l'URL** sur différents appareils
2. **iOS Safari** : Tester PWA + notifications + badges
3. **Desktop** : Tester notifications web
4. **Android Chrome** : Tester installation PWA

## 🎯 URLs Finales

Après déploiement, tu auras :
- **URL principale** : `https://site-name.netlify.app`
- **URL personnalisée** : `https://dailygrowth-pwa.netlify.app` (si configuré)
- **Domaine custom** : `https://app.dailygrowth.com` (si configuré)

## 🔧 Debugging

### Logs Netlify
- **Site settings** → **Functions** → **Function logs**
- Voir les erreurs de build si problème

### Tests PWA
- **Chrome DevTools** → **Application** → **Service Workers**
- **Lighthouse** → **PWA Score**
- **Manifest** validation

## 🚀 Mise à Jour Continue

### Workflow Git
1. **Développer** sur branche `feature/pwa-notifications-push`
2. **Push** → Déploiement automatique Netlify
3. **Merger** vers `main` quand prêt
4. **Production** deploy sur branche main

---

**🎉 Une fois déployé, tu auras une PWA complète avec notifications push iOS Safari ! 🔥**