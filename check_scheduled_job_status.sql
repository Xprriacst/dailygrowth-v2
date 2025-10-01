-- Vérifier si le scheduled job existe et est actif
-- Exécuter dans Supabase SQL Editor

-- 1. Lister tous les jobs pg_cron
SELECT 
    jobid,
    schedule,
    command,
    nodename,
    active,
    jobname
FROM cron.job
ORDER BY jobid;

-- 2. Voir les dernières exécutions
SELECT 
    jobid,
    runid,
    job_pid,
    status,
    return_message,
    start_time AT TIME ZONE 'Europe/Paris' as start_time_paris,
    end_time AT TIME ZONE 'Europe/Paris' as end_time_paris
FROM cron.job_run_details
WHERE start_time > NOW() - INTERVAL '24 hours'
ORDER BY start_time DESC
LIMIT 50;
