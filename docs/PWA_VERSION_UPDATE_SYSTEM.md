# Système de Mise à Jour Automatique de la PWA

## 🎯 Problème Résolu

Les utilisateurs restaient bloqués sur d'anciennes versions de la PWA à cause de :
1. **Service Worker avec version hardcodée** qui ne changeait jamais
2. **Cache HTTP agressif** (5 minutes) retardant les mises à jour
3. **Pas de détection automatique** des nouvelles versions
4. **Pas de prompt utilisateur** pour recharger l'application

## ✅ Solution Implémentée

### 1. **Versioning Automatique du Service Worker**

**Fichier**: `web/sw.js`
- Version désormais dynamique : `__SW_VERSION__`
- Remplacée automatiquement par le build ID Netlify lors de chaque déploiement
- Force le navigateur à télécharger le nouveau Service Worker

```javascript
const CACHE_VERSION = '__SW_VERSION__'; // Remplacé par build
```

**Fichier**: `netlify.toml`
- Commande de build enrichie pour remplacer `__SW_VERSION__` dans `sw.js`
- Utilise `NETLIFY_BUILD_ID` comme version unique

```bash
sed -i.bak "s|__SW_VERSION__|$APP_BUILD_VERSION|g" build/web/sw.js
```

### 2. **Cache HTTP Réduit à Zéro**

**Fichier**: `netlify.toml`
```toml
[[headers]]
  for = "/*.js"
  [headers.values]
    Cache-Control = "public, max-age=0, must-revalidate"
```

- **Avant**: Cache de 5 minutes (300s) → utilisateurs bloqués
- **Après**: Cache de 0 secondes → vérification à chaque chargement

### 3. **Détection Automatique de Nouvelle Version**

**Fichier**: `lib/services/version_checker_service.dart`

Nouveau service qui :
- Vérifie toutes les 5 minutes si une nouvelle version est disponible
- Compare la version serveur vs version locale
- Déclenche un callback quand une mise à jour est détectée

```dart
_versionChecker.startVersionCheck(
  onNewVersionDetected: (newVersion) {
    // Afficher dialog de mise à jour
  },
);
```

**Workflow**:
1. Récupère `/index.html` du serveur (bypass cache)
2. Extrait `window.APP_BUILD_VERSION` via regex
3. Compare avec la version locale
4. Notifie si différente

### 4. **Dialog de Mise à Jour Utilisateur**

**Fichier**: `lib/widgets/update_available_dialog.dart`

Dialog moderne qui :
- Affiche version actuelle vs nouvelle version
- Bouton "Mettre à jour" pour recharger immédiatement
- Bouton "Plus tard" pour reporter

```dart
UpdateAvailableDialog.showIfNeeded(
  context,
  newVersion: "12345",
  currentVersion: "12340",
);
```

### 5. **Support SKIP_WAITING dans Service Worker**

**Fichier**: `web/sw.js`

Message handler ajouté pour activer immédiatement le nouveau SW :

```javascript
case 'SKIP_WAITING':
  console.log('[SW] 🚀 Activating new version immediately');
  self.skipWaiting();
  break;
```

## 📋 Workflow Complet

### Déploiement
1. Developer pousse sur `main`
2. Netlify build démarre
3. Build ID généré (ex: `6730a99b3aa8d600089a73b8`)
4. Remplace `__APP_BUILD_VERSION__` dans `index.html`
5. Remplace `__SW_VERSION__` dans `sw.js`
6. Déploie avec cache headers optimisés

### Mise à Jour Utilisateur
1. Utilisateur a l'app ouverte (version `12340`)
2. Nouveau déploiement arrive (version `12345`)
3. Après 10 secondes, `VersionCheckerService` démarre
4. Vérifie toutes les 5 minutes la version serveur
5. Détecte version `12345` ≠ `12340`
6. Affiche dialog "Mise à jour disponible"
7. Utilisateur clique "Mettre à jour"
8. Service Worker activé avec `SKIP_WAITING`
9. Page rechargée → nouvelle version

## 🔧 Fichiers Modifiés

```
web/
├── sw.js                              # Version dynamique
├── index.html                          # Version token injecté
netlify.toml                           # Build command + cache headers
lib/
├── main.dart                           # Intégration VersionChecker
├── services/
│   └── version_checker_service.dart    # Nouveau service
├── widgets/
│   └── update_available_dialog.dart    # Nouveau dialog
└── utils/
    └── build_version_helper.dart       # Lecture version
```

## 🎯 Résultats Attendus

### Avant
- ❌ Utilisateur bloqué 5 minutes minimum
- ❌ Service Worker jamais mis à jour
- ❌ Aucune visibilité sur la version
- ❌ Confusion utilisateur

### Après
- ✅ Détection automatique en 5 minutes max
- ✅ Service Worker forcé à se mettre à jour
- ✅ Dialog clair avec action simple
- ✅ Badge version visible dans l'app
- ✅ Expérience utilisateur fluide

## 🧪 Tests

### Test Manuel
1. Noter la version actuelle (badge en bas du dashboard)
2. Faire un déploiement sur Netlify
3. Attendre 10 secondes (démarrage vérificateur)
4. Attendre max 5 minutes
5. Dialog "Mise à jour disponible" devrait apparaître
6. Cliquer "Mettre à jour"
7. Vérifier nouveau badge version

### Test Hard Refresh
```bash
# Chrome/Edge
Ctrl+Shift+R (Windows)
Cmd+Shift+R (Mac)

# Safari iOS
Settings → Safari → Clear History and Website Data
```

## 📊 Monitoring

### Logs Console à Surveiller
```
[VersionChecker] Current version: 12340
[VersionChecker] ✅ Running latest version: 12340
[VersionChecker] 🆕 New version detected: 12345 (current: 12340)
[SW] 🚀 Activating new version immediately
[ChallengeMe] Build version: 12345
```

### Métriques Netlify
- Build ID visible dans les logs de déploiement
- Vérifier que `__SW_VERSION__` est bien remplacé
- Confirmer headers `Cache-Control` corrects

## ⚠️ Points d'Attention

### Cache Navigateur Agressif
Malgré `max-age=0`, certains navigateurs peuvent garder un cache temporaire. Solution : hard refresh.

### iOS Safari PWA
iOS peut être plus agressif sur le cache. Si bloqué :
1. Supprimer la PWA de l'écran d'accueil
2. Vider cache Safari
3. Réinstaller la PWA

### Service Worker Lifecycle
Le nouveau SW ne s'active pas immédiatement si des pages sont ouvertes. Le message `SKIP_WAITING` résout ce problème.

## 🚀 Améliorations Futures

### Option 1 : Mise à Jour Forcée
Si version trop ancienne (ex: >7 jours), forcer le rechargement sans dialog.

### Option 2 : Changelog
Afficher les nouveautés dans le dialog de mise à jour.

### Option 3 : Analytics
Tracker combien d'utilisateurs cliquent "Plus tard" vs "Mettre à jour".

### Option 4 : Background Update
Télécharger la nouvelle version en background, activer au prochain lancement.

## 📝 Checklist Déploiement

- [x] Version dynamique dans `sw.js`
- [x] Build command met à jour `sw.js`
- [x] Cache headers réduits à 0
- [x] `VersionCheckerService` créé
- [x] Dialog de mise à jour créé
- [x] Intégration dans `main.dart`
- [x] Support `SKIP_WAITING` dans SW
- [x] Badge version visible
- [x] Tests manuels effectués
- [ ] **Validation utilisateur réel**

## 🎉 Conclusion

Le système de mise à jour automatique est maintenant **complet et opérationnel**. Les utilisateurs ne seront plus bloqués sur d'anciennes versions et seront proactivement notifiés des mises à jour disponibles avec une action simple et claire.
