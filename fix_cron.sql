-- Fix pour le cron job avec syntaxe JSON correcte
-- À exécuter dans Supabase SQL Editor

-- 1. Supprimer l'ancien cron défaillant
SELECT cron.unschedule('daily-notifications-check');

-- 2. Recréer avec syntaxe JSON corrigée
SELECT cron.schedule(
  'daily-notifications-fixed',
  '*/1 * * * *',  -- Toutes les minutes pour test
  $$
  SELECT
    net.http_post(
      url := 'https://hekdcsulxrukfturuone.supabase.co/functions/v1/cron-daily-notifications',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk"}'::jsonb,
      body := ('{"trigger": "cron", "timestamp": "' || now()::text || '"}')::jsonb
    );
  $$
);

-- 3. Vérifier la création
SELECT * FROM cron.job WHERE jobname = 'daily-notifications-fixed';