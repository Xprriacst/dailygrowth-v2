#!/bin/bash

# Script pour tester manuellement les notifications quotidiennes
echo "🧪 Test manuel de la fonction send-daily-notifications"
echo "=================================================="

# URL de la fonction Edge
FUNCTION_URL="https://hekdcsulxrukfturuone.supabase.co/functions/v1/send-daily-notifications"

# Headers nécessaires (utiliser la clé service)
echo "📡 Envoi de la requête POST..."

curl -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SERVICE_KEY_HERE" \
  -d '{
    "trigger": "manual-test",
    "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"
  }' \
  -v

echo -e "\n\n✅ Test terminé. Vérifiez les logs pour les détails."