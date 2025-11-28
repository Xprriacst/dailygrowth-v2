#!/bin/bash

# Script de vérification de la configuration iOS Push Notifications
# Usage: ./scripts/check_ios_push_setup.sh

echo "🔍 Vérification de la configuration iOS Push Notifications"
echo "============================================================"
echo ""

PROJECT_ROOT="/Users/alexandreerrasti/Downloads/dailygrowth v2"
cd "$PROJECT_ROOT" || exit 1

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Compteur
PASSED=0
FAILED=0
WARNINGS=0

# Fonction de vérification
check() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ $2${NC}"
        ((FAILED++))
    fi
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARNINGS++))
}

echo "1. Vérification des fichiers..."
echo ""

# Vérifier GoogleService-Info.plist
if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    check 0 "GoogleService-Info.plist présent"
    
    # Vérifier le Bundle ID dans le fichier
    BUNDLE_ID=$(grep -A 1 "BUNDLE_ID" ios/Runner/GoogleService-Info.plist 2>/dev/null | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    if [ ! -z "$BUNDLE_ID" ]; then
        echo "   Bundle ID trouvé: $BUNDLE_ID"
    fi
else
    check 1 "GoogleService-Info.plist présent"
    echo "   → Action: Télécharger depuis Firebase Console"
    echo "   → Guide: docs/ETAPES_IMMEDIATES_IOS.md"
fi

# Vérifier AppDelegate.swift
if grep -q "FirebaseCore" ios/Runner/AppDelegate.swift 2>/dev/null; then
    check 0 "AppDelegate.swift configuré pour Firebase"
else
    check 1 "AppDelegate.swift configuré pour Firebase"
fi

# Vérifier IOSPushNotificationService
if [ -f "lib/services/ios_push_notification_service.dart" ]; then
    check 0 "IOSPushNotificationService créé"
else
    check 1 "IOSPushNotificationService créé"
fi

# Vérifier l'intégration dans NotificationService
if grep -q "IOSPushNotificationService" lib/services/notification_service.dart 2>/dev/null; then
    check 0 "NotificationService intègre IOSPushNotificationService"
else
    check 1 "NotificationService intègre IOSPushNotificationService"
fi

echo ""
echo "2. Vérification de la configuration Xcode..."
echo ""
warn "Les capabilities Xcode doivent être vérifiées manuellement"
echo "   → Ouvrir ios/Runner.xcworkspace dans Xcode"
echo "   → Target Runner → Signing & Capabilities"
echo "   → Vérifier: Push Notifications capability"
echo "   → Vérifier: Background Modes → Remote notifications"
echo ""

echo "3. Vérification Firebase/APNs..."
echo ""
warn "La configuration APNs doit être vérifiée dans Firebase Console"
echo "   → https://console.firebase.google.com/project/dailygrowth-pwa"
echo "   → Settings → Cloud Messaging → Apple app configuration"
echo "   → Vérifier que la clé APNs est uploadée"
echo ""

echo "4. Vérification des dépendances..."
echo ""

# Vérifier Firebase dans Podfile.lock
if grep -q "FirebaseMessaging" ios/Podfile.lock 2>/dev/null; then
    check 0 "FirebaseMessaging dans Podfile.lock"
else
    check 1 "FirebaseMessaging dans Podfile.lock"
    echo "   → Action: cd ios && pod install"
fi

# Vérifier firebase_messaging dans pubspec.yaml
if grep -q "firebase_messaging" pubspec.yaml 2>/dev/null; then
    check 0 "firebase_messaging dans pubspec.yaml"
else
    check 1 "firebase_messaging dans pubspec.yaml"
fi

echo ""
echo "============================================================"
echo "📊 Résumé"
echo "============================================================"
echo -e "${GREEN}✅ Réussis: $PASSED${NC}"
echo -e "${RED}❌ Échecs: $FAILED${NC}"
echo -e "${YELLOW}⚠️  Avertissements: $WARNINGS${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 Toutes les vérifications automatiques sont passées !${NC}"
    echo ""
    echo "Prochaines étapes:"
    echo "1. Vérifier les capabilities dans Xcode (voir avertissements)"
    echo "2. Configurer APNs dans Firebase Console (voir avertissements)"
    echo "3. Tester sur device iOS réel"
else
    echo -e "${YELLOW}⚠️  Certaines vérifications ont échoué${NC}"
    echo ""
    echo "Consultez les guides:"
    echo "- docs/ETAPES_IMMEDIATES_IOS.md (démarrage rapide)"
    echo "- docs/GUIDE_CONFIGURATION_IOS_PUSH.md (guide complet)"
fi

echo ""



