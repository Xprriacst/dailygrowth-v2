-- Vérifier l'état du cron job pg_cron
-- Copier-coller dans Supabase SQL Editor

-- 1. Vérifier si l'extension pg_cron est installée
SELECT 
    '=== EXTENSION PG_CRON ===' as section,
    extname,
    extversion,
    'Extension installée' as status
FROM pg_extension 
WHERE extname = 'pg_cron';

-- 2. Lister tous les cron jobs actifs
SELECT 
    '=== CRON JOBS ACTIFS ===' as section,
    jobid,
    schedule,
    command,
    nodename,
    nodeport,
    database,
    username,
    active,
    jobname
FROM cron.job
ORDER BY jobid;

-- 3. Voir les dernières exécutions (si elles existent)
SELECT 
    '=== DERNIÈRES EXÉCUTIONS ===' as section,
    jobid,
    runid,
    job_pid,
    database,
    username,
    command,
    status,
    return_message,
    start_time AT TIME ZONE 'Europe/Paris' as start_time_paris,
    end_time AT TIME ZONE 'Europe/Paris' as end_time_paris
FROM cron.job_run_details
ORDER BY start_time DESC
LIMIT 20;

-- 4. Si pas de cron job, en créer un
-- ⚠️ Décommenter seulement si aucun job n'existe
/*
SELECT cron.schedule(
    'daily-notifications-cron',
    '*/15 * * * *',
    $$
    SELECT net.http_post(
        url := 'https://hekdcsulxrukfturuone.supabase.co/functions/v1/cron-daily-notifications',
        headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk"}'::jsonb,
        body := ('{"trigger": "cron", "timestamp": "' || now()::text || '"}')::jsonb
    ) as request_id;
    $$
);
*/
