#!/bin/bash

# Script de build pour Netlify avec support SPA
echo "🚀 Building Flutter web app for Netlify..."

# Build l'application Flutter web
flutter build web --release --dart-define-from-file=env.json

# Créer le fichier _redirects pour le support SPA
echo "📝 Creating _redirects file for SPA support..."
cat > build/web/_redirects << EOF
# SPA fallback - redirige toutes les routes vers index.html
/*    /index.html   200

# Redirections spécifiques pour les assets (optionnel)
/assets/*  /assets/:splat  200
/icons/*   /icons/:splat   200
EOF

echo "✅ Build completed successfully!"
echo "📁 Output directory: build/web"
echo "🔗 _redirects file created for SPA routing"
