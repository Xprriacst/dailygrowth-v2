#!/bin/bash

# Test direct d'envoi FCM au token de expertiaen5min@gmail.com
# Ce script va appeler send-push-notification directement avec ton FCM token

echo "🧪 Test direct FCM pour expertiaen5min@gmail.com"
echo ""

# Note: Le token sera récupéré depuis la base de données
# Pour l'instant, on va tester avec un appel direct

curl -X POST 'https://hekdcsulxrukfturuone.supabase.co/functions/v1/send-push-notification' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk' \
  -H 'Content-Type: application/json' \
  -d '{
    "fcmToken": "REPLACE_WITH_REAL_TOKEN",
    "title": "🧪 Test Direct ChallengeMe",
    "body": "Test manuel depuis le script de diagnostic",
    "url": "/#/challenges"
  }'

echo ""
echo "✅ Test envoyé - Vérifie ton iPhone"
