-- Diagnostic approfondi de la notification envoyée

-- 1. Logs détaillés de la dernière notification
SELECT 
    user_id,
    trigger_type,
    notification_sent,
    skip_reason,
    error_message,
    created_at
FROM notification_logs
WHERE user_id = (SELECT id FROM user_profiles WHERE email = 'expertiaen5min@gmail.com')
ORDER BY created_at DESC
LIMIT 5;

-- 2. Profil utilisateur avec FCM token complet
SELECT 
    id,
    email,
    fcm_token,
    notifications_enabled,
    notification_time,
    notification_timezone_offset_minutes,
    last_notification_sent_at
FROM user_profiles 
WHERE email = 'expertiaen5min@gmail.com';

-- 3. Vérifier si il y a des challenges actifs pour l'utilisateur
SELECT 
    id,
    user_id,
    nom,
    problematique,
    is_used_as_daily,
    used_as_daily_date,
    created_at,
    updated_at
FROM user_micro_challenges
WHERE user_id = (SELECT id FROM user_profiles WHERE email = 'expertiaen5min@gmail.com')
ORDER BY created_at DESC
LIMIT 5;

-- 4. Vérifier les exécutions du cron récentes
SELECT 
    r.jobid,
    j.jobname,
    r.status,
    r.start_time,
    r.end_time,
    r.return_message
FROM cron.job_run_details r
JOIN cron.job j ON r.jobid = j.jobid
WHERE j.jobname = 'daily-notifications-every-15min'
    AND r.start_time > NOW() - INTERVAL '1 hour'
ORDER BY r.start_time DESC
LIMIT 5;
