-- Configuration du cron job pour les notifications quotidiennes
-- À exécuter dans Supabase SQL Editor

-- 1. Activer l'extension pg_cron si pas déjà fait
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 2. Créer le cron job qui s'exécute toutes les 15 minutes
SELECT cron.schedule(
  'daily-notifications-check',
  '*/15 * * * *',  -- Toutes les 15 minutes
  $$
  SELECT
    net.http_post(
      url:='https://hekdcsulxrukfturuone.supabase.co/functions/v1/cron-daily-notifications',
      headers:='{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk"}'::jsonb,
      body:='{"trigger": "cron", "timestamp": "' || now()::text || '"}'::jsonb
    );
  $$
);

-- 3. Vérifier que le cron job a été créé
SELECT * FROM cron.job;

-- 4. Pour supprimer le cron job si besoin (ne pas exécuter maintenant)
-- SELECT cron.unschedule('daily-notifications-check');
