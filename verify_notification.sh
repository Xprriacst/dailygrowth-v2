#!/bin/bash

echo "🔍 Vérification des logs de notification..."
echo ""

curl -s 'https://hekdcsulxrukfturuone.supabase.co/rest/v1/notification_logs?user_id=eq.38118795-21a9-4b3d-afe9-b23c63936c9a&order=created_at.desc&limit=3' \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk" \
  | jq 'map({
      heure: .created_at,
      envoyee: .notification_sent,
      raison_skip: .skip_reason,
      diff_minutes: .time_diff_minutes,
      defi: .challenge_name
    })'

echo ""
echo "✅ Si notification_sent = true → Tout fonctionne !"
echo "❌ Si notification_sent = false → Partage le skip_reason"
