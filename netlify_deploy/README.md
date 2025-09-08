# 🔥 DailyGrowth PWA - Test Suite Netlify

## 🚀 Déploiement Netlify

Ce dossier contient une version standalone optimisée pour tester les notifications PWA DailyGrowth.

### 📁 Fichiers
- `index.html` - Interface de test complète
- `manifest.json` - Configuration PWA 
- `_headers` - Headers Netlify pour PWA
- `README.md` - Cette documentation

### 🌐 Déploiement

**Option 1 - Netlify Drop (Recommandé)**
1. Aller sur https://app.netlify.com/drop
2. Glisser-déposer tout le dossier `netlify_deploy`
3. Obtenir l'URL générée
4. Tester sur iOS Safari

**Option 2 - Git Deploy**
1. Push sur GitHub dans la branche `feature/pwa-notifications-push`
2. Connecter le repo à Netlify
3. Déploiement automatique

### 📱 Fonctionnalités Testables

#### ✅ Notifications Web
- Notifications natives iOS Safari
- Différents types : défis, succès, séries
- Gestion des permissions
- Click-to-focus

#### ✅ Badge API iOS Safari 16.4+
- Compteurs sur icône PWA
- setBadge() / clearAppBadge()
- Tests avec différentes valeurs
- Compatible mode standalone uniquement

#### ✅ Détection Environnement  
- iOS vs Desktop
- Safari vs autres navigateurs
- Mode PWA vs Web
- Support des APIs

### 🧪 Instructions de Test

1. **Ouvrir l'URL** sur iOS Safari
2. **Autoriser notifications** avec le bouton
3. **Ajouter à l'écran d'accueil** : Partager → "Ajouter à l'écran d'accueil"
4. **Lancer depuis l'icône PWA** (pas Safari)
5. **Tester notifications et badges**

### 🎯 Résultats Attendus

**iOS Safari 16.4+ en mode PWA :**
- ✅ Notifications popup natives
- ✅ Badge rouge avec compteur sur icône
- ✅ Détection correcte de l'environnement
- ✅ Logs détaillés des tests

**Autres environnements :**  
- ✅ Notifications web standard
- ❌ Pas de badge (non supporté)
- ✅ Interface de test fonctionnelle

---

**Cette version Netlify garantit le fonctionnement avec HTTPS et toutes les APIs Web modernes !**