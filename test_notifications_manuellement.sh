#!/bin/bash

# Script de test manuel des notifications ChallengeMe
# Ce script permet de déclencher manuellement l'envoi de notifications

set -e

echo "🧪 TEST MANUEL DES NOTIFICATIONS CHALLENGEME"
echo "=============================================="
echo ""

# Couleurs pour l'affichage
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SUPABASE_URL="https://hekdcsulxrukfturuone.supabase.co"
SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk"

echo -e "${YELLOW}Étape 1/3 : Déclenchement du cron job...${NC}"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  "${SUPABASE_URL}/functions/v1/cron-daily-notifications" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"trigger\":\"manual-test\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "Réponse HTTP : $HTTP_CODE"
echo "Corps de la réponse :"
echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✅ Cron job déclenché avec succès !${NC}"
else
    echo -e "${RED}❌ Erreur lors du déclenchement du cron job (HTTP $HTTP_CODE)${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Étape 2/3 : Attendre 5 secondes pour que les notifications soient traitées...${NC}"
sleep 5

echo ""
echo -e "${YELLOW}Étape 3/3 : Vérification des logs de notifications...${NC}"
echo ""
echo "Pour vérifier les logs, exécutez cette requête SQL dans Supabase :"
echo ""
echo -e "${GREEN}SELECT * FROM notification_logs ORDER BY created_at DESC LIMIT 10;${NC}"
echo ""

echo "=============================================="
echo -e "${GREEN}✅ Test terminé !${NC}"
echo ""
echo "Prochaines étapes :"
echo "1. Aller sur Supabase SQL Editor : https://supabase.com/dashboard/project/hekdcsulxrukfturuone/sql"
echo "2. Exécuter la requête SQL ci-dessus pour voir les logs"
echo "3. Vérifier que des notifications ont été envoyées (notification_sent = true)"
echo ""
