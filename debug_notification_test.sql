-- Script de diagnostic complet pour tester les notifications
-- Exécute ce script dans Supabase SQL Editor

-- 1. Vérifier ton profil utilisateur
SELECT 
    id,
    email,
    notifications_enabled,
    notification_time,
    notification_timezone_offset_minutes,
    last_notification_sent_at,
    fcm_token IS NOT NULL as has_fcm_token,
    LENGTH(fcm_token) as token_length,
    created_at
FROM user_profiles 
WHERE email = 'expertiaen5min@gmail.com' OR email LIKE '%@gmail.com'
ORDER BY created_at DESC;

-- 2. Vérifier l'heure actuelle UTC vs ton heure locale
SELECT 
    NOW() as current_utc_time,
    NOW() + INTERVAL '120 minutes' as current_france_time,
    TO_CHAR(NOW(), 'HH24:MI:SS') as utc_time_string,
    TO_CHAR(NOW() + INTERVAL '120 minutes', 'HH24:MI:SS') as france_time_string;

-- 3. Vérifier les derniers logs de notifications (si la table existe)
SELECT 
    user_id,
    trigger_type,
    notification_sent,
    skip_reason,
    error_message,
    created_at
FROM notification_logs
WHERE created_at > NOW() - INTERVAL '2 hours'
ORDER BY created_at DESC
LIMIT 10;

-- 4. Vérifier les exécutions du cron job
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
WHERE j.jobname = 'daily-notifications-every-15min'
    AND r.start_time > NOW() - INTERVAL '2 hours'
ORDER BY r.start_time DESC
LIMIT 10;

-- 5. Calculer la différence de temps pour 17:03
SELECT 
    '17:03:00'::TIME as notification_time,
    TO_CHAR(NOW() + INTERVAL '120 minutes', 'HH24:MI:SS')::TIME as current_france_time,
    ABS(EXTRACT(EPOCH FROM ('17:03:00'::TIME - TO_CHAR(NOW() + INTERVAL '120 minutes', 'HH24:MI:SS')::TIME)) / 60) as diff_minutes;
