# Guide de déploiement DailyGrowth sur Netlify

## 🎯 Stratégie de déploiement

### Option 1: Déploiement automatisé avec netlify.toml (Recommandé)

Le fichier `netlify.toml` est déjà configuré dans le projet avec:
- Build command optimisée pour Flutter
- Redirections SPA automatiques
- Headers de sécurité et cache
- Configuration des variables d'environnement

### Option 2: Script de build personnalisé

Utilisez le script `scripts/build_for_netlify.sh` pour un build local:

```bash
./scripts/build_for_netlify.sh
```

## 🔧 Configuration Netlify

### 1. Variables d'environnement à configurer

Dans l'interface Netlify > Site settings > Environment variables:

```
SUPABASE_URL=https://votre-projet.supabase.co
SUPABASE_ANON_KEY=votre_clé_anon
OPENAI_API_KEY=sk-proj-votre_clé
GEMINI_API_KEY=votre_clé_gemini (optionnel)
ANTHROPIC_API_KEY=votre_clé_anthropic (optionnel)
PERPLEXITY_API_KEY=votre_clé_perplexity (optionnel)
```

### 2. Paramètres de build

Si vous n'utilisez pas `netlify.toml`:

**Build command:**
```bash
if [ -d "flutter" ]; then cd flutter && git pull && cd ..; else git clone https://github.com/flutter/flutter.git; fi; flutter/bin/flutter config --enable-web && flutter/bin/flutter build web --release --dart-define-from-file=env.json && echo '/*    /index.html   200' > build/web/_redirects
```

**Publish directory:**
```
build/web
```

## 🚀 Étapes de déploiement

### 1. Préparer le repository

```bash
# Sécuriser les variables d'environnement
echo "env.json" >> .gitignore

# Committer la configuration
git add netlify.toml scripts/ docs/ .env.example .gitignore
git commit -m "Add Netlify deployment configuration"
git push origin main
```

### 2. Connecter à Netlify

1. Aller sur [Netlify](https://netlify.com)
2. "New site from Git" > Choisir votre provider Git
3. Sélectionner le repository DailyGrowth
4. Netlify détectera automatiquement `netlify.toml`
5. Ajouter les variables d'environnement
6. Déployer

### 3. Vérifications post-déploiement

- ✅ Page d'accueil se charge
- ✅ Navigation entre les routes fonctionne
- ✅ Refresh sur une route profonde ne donne pas 404
- ✅ Authentification Supabase fonctionne
- ✅ Génération de contenu OpenAI fonctionne

## 🛠️ Résolution de problèmes courants

### Problème: 404 sur les routes

**Solution:** Vérifiez que le fichier `_redirects` est présent dans `build/web/`:
```
/*    /index.html   200
```

### Problème: Variables d'environnement non reconnues

**Solution:** 
1. Vérifiez qu'elles sont définies dans Netlify
2. Redéployez le site
3. Utilisez `--dart-define` dans la build command

### Problème: Build Flutter échoue

**Solution:** 
1. Vérifiez que Flutter est compatible web
2. Testez localement: `flutter build web --release`
3. Vérifiez les dépendances dans `pubspec.yaml`

### Problème: Authentification Supabase ne fonctionne pas

**Solution:**
1. Vérifiez les URLs de redirection dans Supabase
2. Ajoutez l'URL Netlify aux domaines autorisés
3. Vérifiez les variables `SUPABASE_URL` et `SUPABASE_ANON_KEY`

## 📊 Optimisations de performance

### Headers de cache configurés

- Assets statiques: cache 1 an
- JS/CSS: cache 1 an avec immutable
- HTML: pas de cache (pour les mises à jour)

### Optimisations Flutter

- Build en mode `--release`
- Compression automatique par Netlify
- Service worker pour le cache offline

## 🔒 Sécurité

### Variables sensibles

- ❌ Ne jamais committer `env.json`
- ✅ Utiliser les variables d'environnement Netlify
- ✅ Rotation régulière des clés API

### Headers de sécurité

Configurés dans `netlify.toml`:
- X-Frame-Options: DENY
- X-XSS-Protection: 1; mode=block
- X-Content-Type-Options: nosniff
- Referrer-Policy: strict-origin-when-cross-origin

## 📱 Support multi-plateforme

Cette configuration déploie uniquement la version web. Pour mobile:
- Android: Google Play Store / Firebase App Distribution
- iOS: App Store / TestFlight

## 🔄 CI/CD automatique

Avec cette configuration:
- Push sur `main` → Déploiement automatique
- Preview deployments sur les PRs
- Rollback facile via l'interface Netlify
