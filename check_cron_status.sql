-- Script pour vérifier le statut du cron job
-- À exécuter dans Supabase SQL Editor

-- 1. Vérifier que le job existe et est actif
SELECT 
    jobid,
    schedule,
    jobname,
    active,
    command
FROM cron.job
WHERE jobname = 'challengeme-daily-notifications';

-- 2. Vérifier les dernières exécutions (dernières 24h)
SELECT 
    r.jobid,
    j.jobname,
    r.runid,
    r.status,
    r.start_time,
    r.end_time,
    r.return_message,
    EXTRACT(EPOCH FROM (r.end_time - r.start_time)) AS duration_seconds
FROM cron.job_run_details r
JOIN cron.job j ON r.jobid = j.jobid
WHERE j.jobname = 'challengeme-daily-notifications'
    AND r.start_time > NOW() - INTERVAL '24 hours'
ORDER BY r.start_time DESC
LIMIT 20;

-- 3. Vérifier les logs de notifications (dernières 24h)
SELECT 
    user_id,
    trigger_type,
    notification_sent,
    skip_reason,
    error_message,
    notification_time,
    actual_send_time,
    time_diff_minutes,
    created_at
FROM notification_logs
WHERE created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC
LIMIT 20;

-- 4. Compter les notifications envoyées aujourd'hui
SELECT 
    COUNT(*) AS total_attempts,
    SUM(CASE WHEN notification_sent THEN 1 ELSE 0 END) AS successful_sends,
    SUM(CASE WHEN NOT notification_sent THEN 1 ELSE 0 END) AS failed_sends
FROM notification_logs
WHERE DATE(created_at) = CURRENT_DATE;
