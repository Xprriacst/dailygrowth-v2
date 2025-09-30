-- Créer le scheduled job pour les notifications quotidiennes
-- Exécuter dans Supabase SQL Editor

-- 1. D'abord, supprimer l'ancien s'il existe
SELECT cron.unschedule(jobid)
FROM cron.job 
WHERE jobname LIKE '%notification%';

-- 2. Créer le nouveau job (toutes les 15 minutes)
SELECT cron.schedule(
    'daily-notifications-every-15min',  -- Nom du job
    '*/15 * * * *',                      -- Toutes les 15 minutes
    $$
    SELECT
      net.http_post(
          url := 'https://hekdcsulxrukfturuone.supabase.co/functions/v1/send-daily-notifications',
          headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk"}'::jsonb,
          body := ('{"trigger": "scheduled-cron", "timestamp": "' || now()::text || '"}')::jsonb
      ) AS request_id;
    $$
);

-- 3. Vérifier que le job a été créé
SELECT 
    jobid,
    schedule,
    jobname,
    active,
    command
FROM cron.job
WHERE jobname = 'daily-notifications-every-15min';
