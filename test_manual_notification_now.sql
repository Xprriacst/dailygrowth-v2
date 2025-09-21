-- Test manuel d'envoi de notification push pour expertiaen5min@gmail.com
-- À exécuter dans Supabase SQL Editor après avoir vérifié les paramètres utilisateur

-- 1. Activer l'extension net si pas déjà fait
CREATE EXTENSION IF NOT EXISTS net;

-- 2. Test immédiat de la fonction de notification quotidienne
SELECT
  net.http_post(
    url:='https://hekdcsulxrukfturuone.supabase.co/functions/v1/send-daily-notifications',
    headers:='{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyNTU1MjkyMywiZXhwIjoyMDQxMTI4OTIzfQ.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk"}'::jsonb,
    body:=jsonb_build_object(
      'trigger', 'manual_test',
      'timestamp', now()::text,
      'test_user', 'expertiaen5min@gmail.com'
    )
  ) as response;

-- Alternative : Test direct avec send-push-notification pour cet utilisateur spécifique
-- (Remplacer TOKEN_FCM par le vrai token de l'utilisateur)
/*
SELECT
  net.http_post(
    url:='https://hekdcsulxrukfturuone.supabase.co/functions/v1/send-push-notification',
    headers:='{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyNTU1MjkyMywiZXhwIjoyMDQxMTI4OTIzfQ.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk"}'::jsonb,
    body:='{"token": "TOKEN_FCM", "title": "🧪 Test Notification", "body": "Test manuel pour expertiaen5min@gmail.com", "data": {"type": "test", "timestamp": "' || now()::text || '"}}'::jsonb
  ) as response;
*/