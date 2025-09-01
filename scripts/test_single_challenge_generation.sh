#!/bin/bash

# Script de test pour la nouvelle logique de génération unique
# Usage: ./test_single_challenge_generation.sh

echo "🧪 Test de la nouvelle logique de génération de micro-défis"
echo "=================================================="

# Configuration
N8N_WEBHOOK_URL="https://polaris-ia.app.n8n.cloud/webhook/ui-defis-final"
PROJECT_DIR="/Users/alexandreerrasti/Downloads/dailygrowth v2"

echo ""
echo "1️⃣ Test du webhook n8n..."
echo "----------------------------"

# Test avec différents niveaux
test_webhook() {
    local problematique="$1"
    local nombre_defis="$2"
    local niveau="$3"
    
    echo "🎯 Test: $problematique (défis relevés: $nombre_defis, niveau: $niveau)"
    
    response=$(curl -s -X POST "$N8N_WEBHOOK_URL" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "Je veux...=Je veux travailler sur: $problematique&Combien de défi à tu relevé=$nombre_defis" \
        --max-time 30)
    
    if [ $? -eq 0 ]; then
        # Vérifier que la réponse contient exactement 1 défi
        defis_count=$(echo "$response" | jq '.defis | length' 2>/dev/null)
        if [ "$defis_count" = "1" ]; then
            echo "✅ Succès: 1 défi généré"
            echo "   Nom: $(echo "$response" | jq -r '.defis[0].nom' 2>/dev/null)"
        else
            echo "❌ Erreur: $defis_count défis générés au lieu de 1"
            echo "   Réponse: $response"
        fi
    else
        echo "❌ Erreur: Timeout ou échec de connexion"
    fi
    echo ""
}

# Tests avec différents scénarios
test_webhook "confiance en soi" "0" "débutant"
test_webhook "gestion des émotions" "3" "intermédiaire" 
test_webhook "leadership charismatique" "8" "avancé"

echo ""
echo "2️⃣ Test de l'application Flutter..."
echo "------------------------------------"

cd "$PROJECT_DIR"

# Vérifier que les fichiers modifiés existent
echo "📁 Vérification des fichiers modifiés:"
files_to_check=(
    "lib/services/n8n_challenge_service.dart"
    "lib/services/challenge_service.dart"
    "lib/presentation/challenge_selection/challenge_selection_screen.dart"
    "lib/presentation/onboarding_flow/widgets/life_domain_selection_widget.dart"
)

for file in "${files_to_check[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file manquant"
    fi
done

echo ""
echo "🔍 Vérification des nouvelles méthodes:"
echo "---------------------------------------"

# Vérifier que les nouvelles méthodes existent
if grep -q "generateSingleMicroChallenge" lib/services/n8n_challenge_service.dart; then
    echo "✅ generateSingleMicroChallenge trouvée"
else
    echo "❌ generateSingleMicroChallenge manquante"
fi

if grep -q "_generateNewMicroChallengeViaAI" lib/services/challenge_service.dart; then
    echo "✅ _generateNewMicroChallengeViaAI trouvée"
else
    echo "❌ _generateNewMicroChallengeViaAI manquante"
fi

if grep -q "generateSingleMicroChallengeWithFallback" lib/presentation/challenge_selection/challenge_selection_screen.dart; then
    echo "✅ UI mise à jour (challenge_selection)"
else
    echo "❌ UI non mise à jour (challenge_selection)"
fi

echo ""
echo "🏗️ Test de compilation Flutter..."
echo "--------------------------------"

# Test de compilation
if flutter analyze --no-fatal-infos > /dev/null 2>&1; then
    echo "✅ Analyse Flutter: OK"
else
    echo "❌ Analyse Flutter: Erreurs détectées"
    echo "   Lancez 'flutter analyze' pour plus de détails"
fi

echo ""
echo "📊 Résumé des tests"
echo "==================="
echo "✅ Tests terminés"
echo ""
echo "🔧 Prochaines étapes:"
echo "1. Modifier le workflow n8n selon docs/N8N_SINGLE_CHALLENGE_WORKFLOW.md"
echo "2. Tester avec un utilisateur réel"
echo "3. Vérifier les logs de génération"
echo "4. Déployer en production"
echo ""
echo "📖 Documentation:"
echo "- docs/TESTING_SINGLE_CHALLENGE_FLOW.md"
echo "- docs/DEPLOYMENT_CHECKLIST.md"
