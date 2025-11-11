-- Configuration du cron job pour les notifications quotidiennes
-- Ce cron job appelle la Edge Function toutes les 15 minutes

-- 1. Activer l'extension pg_cron si pas déjà fait
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 2. Supprimer les anciens jobs de notifications s'ils existent
SELECT cron.unschedule(jobid)
FROM cron.job 
WHERE jobname LIKE '%notification%' OR jobname LIKE '%daily%';

-- 3. Créer le nouveau job (toutes les 15 minutes)
-- Note: Utilise cron-daily-notifications qui appelle ensuite send-daily-notifications
SELECT cron.schedule(
    'challengeme-daily-notifications',  -- Nom du job
    '*/15 * * * *',                     -- Toutes les 15 minutes
    $$
    SELECT
      net.http_post(
          url := 'https://hekdcsulxrukfturuone.supabase.co/functions/v1/cron-daily-notifications',
          headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk"}'::jsonb,
          body := ('{"trigger": "scheduled-cron", "timestamp": "' || now()::text || '"}')::jsonb
      ) AS request_id;
    $$
);

-- 4. Vérifier que le job a été créé et est actif
SELECT 
    jobid,
    schedule,
    jobname,
    active,
    command,
    nodename
FROM cron.job
WHERE jobname = 'challengeme-daily-notifications';

-- 5. Créer une vue pour faciliter le monitoring du cron job
CREATE OR REPLACE VIEW cron_job_status AS
SELECT 
    j.jobid,
    j.schedule,
    j.jobname,
    j.active,
    j.nodename,
    r.status,
    r.return_message,
    r.start_time,
    r.end_time
FROM cron.job j
LEFT JOIN cron.job_run_details r ON j.jobid = r.jobid
WHERE j.jobname = 'challengeme-daily-notifications'
ORDER BY r.start_time DESC
LIMIT 10;

COMMENT ON VIEW cron_job_status IS 'Vue pour monitorer le statut du cron job de notifications quotidiennes';
