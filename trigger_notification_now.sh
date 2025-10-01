#!/bin/bash

echo "🚀 Déclenchement manuel des notifications avec logging..."
echo "Heure actuelle : $(date '+%H:%M:%S')"
echo ""

curl -X POST \
  'https://hekdcsulxrukfturuone.supabase.co/functions/v1/cron-daily-notifications' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk' \
  -d '{"trigger": "manual-debug-test", "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'"}' \
  | jq .

echo ""
echo "✅ Maintenant vérifie les logs avec check_notification_logs.sql"
