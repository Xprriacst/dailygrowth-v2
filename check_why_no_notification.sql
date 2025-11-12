-- Diagnostic complet pour comprendre pourquoi aucune notification n'est envoyée

-- 1. Vérifier ton profil complet
SELECT 
    email,
    notifications_enabled,
    notification_time,
    notification_timezone_offset_minutes,
    last_notification_sent_at,
    fcm_token IS NOT NULL as has_fcm_token,
    SUBSTRING(fcm_token, 1, 30) as token_preview,
    created_at
FROM user_profiles 
WHERE email = 'expertiaen5min@gmail.com';

-- 2. Calculer l'heure actuelle selon ton fuseau
SELECT 
    NOW() as utc_now,
    NOW() + INTERVAL '60 minutes' as france_time_utc1,
    TO_CHAR(NOW() + INTERVAL '60 minutes', 'HH24:MI:SS') as france_time_string;

-- 3. Vérifier si l'heure 17:20 est dans la fenêtre ±15 minutes
WITH user_time AS (
    SELECT TO_CHAR(NOW() + INTERVAL '60 minutes', 'HH24:MI:SS')::TIME as france_time
),
notification_config AS (
    SELECT '17:20:00'::TIME as notif_time
)
SELECT 
    france_time,
    notif_time,
    ABS(EXTRACT(EPOCH FROM (france_time - notif_time)) / 60) as diff_minutes,
    CASE 
        WHEN ABS(EXTRACT(EPOCH FROM (france_time - notif_time)) / 60) <= 15 
        THEN '✅ DANS LA FENÊTRE' 
        ELSE '❌ HORS FENÊTRE' 
    END as status
FROM user_time, notification_config;

-- 4. Vérifier les logs de notifications (dernière heure)
SELECT 
    user_id,
    trigger_type,
    notification_sent,
    skip_reason,
    error_message,
    created_at
FROM notification_logs
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 20;

-- 5. Vérifier tous les utilisateurs avec notifications activées
SELECT 
    email,
    notifications_enabled,
    notification_time,
    notification_timezone_offset_minutes,
    fcm_token IS NOT NULL as has_token,
    last_notification_sent_at
FROM user_profiles
WHERE notifications_enabled = true
ORDER BY email;
