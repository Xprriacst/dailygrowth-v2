-- Debug : Pourquoi 0 notifications envoyées ?
-- Copier-coller dans Supabase SQL Editor

-- 1. Vérifier l'utilisateur
SELECT 
    '=== ÉTAT UTILISATEUR ===' as section,
    id,
    email,
    notifications_enabled,
    notification_time,
    notification_timezone_offset_minutes,
    last_notification_sent_at,
    fcm_token IS NOT NULL as has_fcm_token,
    SUBSTRING(fcm_token, 1, 30) || '...' as token_preview
FROM user_profiles 
WHERE email = 'expertiaen5min@gmail.com';

-- 2. Calculer l'heure actuelle UTC et l'heure cible
WITH time_info AS (
    SELECT 
        NOW() as now_utc,
        EXTRACT(HOUR FROM NOW()) as current_hour_utc,
        EXTRACT(MINUTE FROM NOW()) as current_minute_utc,
        TO_CHAR(NOW(), 'HH24:MI') as current_time_utc
),
user_config AS (
    SELECT 
        notification_time,
        COALESCE(notification_timezone_offset_minutes, 120) as offset_minutes,
        EXTRACT(HOUR FROM notification_time::time) as notif_hour,
        EXTRACT(MINUTE FROM notification_time::time) as notif_minute
    FROM user_profiles 
    WHERE email = 'expertiaen5min@gmail.com'
)
SELECT 
    '=== CALCUL TIMING ===' as section,
    ti.current_time_utc as heure_actuelle_utc,
    uc.notification_time as heure_config_locale,
    uc.offset_minutes as timezone_offset,
    
    -- Calculer l'heure cible en UTC
    (uc.notif_hour * 60 + uc.notif_minute - uc.offset_minutes) as target_minutes_raw,
    ((uc.notif_hour * 60 + uc.notif_minute - uc.offset_minutes) % 1440 + 1440) % 1440 as target_minutes_utc,
    
    LPAD(
        FLOOR(((uc.notif_hour * 60 + uc.notif_minute - uc.offset_minutes) % 1440 + 1440) % 1440 / 60)::text, 
        2, '0'
    ) || ':' ||
    LPAD(
        MOD(((uc.notif_hour * 60 + uc.notif_minute - uc.offset_minutes) % 1440 + 1440) % 1440, 60)::text, 
        2, '0'
    ) as heure_cible_utc,
    
    -- Différence en minutes
    ABS(
        (ti.current_hour_utc * 60 + ti.current_minute_utc) - 
        ((uc.notif_hour * 60 + uc.notif_minute - uc.offset_minutes) % 1440 + 1440) % 1440
    ) as diff_minutes,
    
    CASE 
        WHEN ABS(
            (ti.current_hour_utc * 60 + ti.current_minute_utc) - 
            ((uc.notif_hour * 60 + uc.notif_minute - uc.offset_minutes) % 1440 + 1440) % 1440
        ) <= 15 THEN '✅ DANS LA FENÊTRE (≤15 min)'
        ELSE '❌ HORS FENÊTRE (>15 min)'
    END as status_fenetre
FROM time_info ti, user_config uc;

-- 3. Vérifier tous les utilisateurs éligibles
SELECT 
    '=== TOUS UTILISATEURS ÉLIGIBLES ===' as section,
    COUNT(*) as total_users,
    COUNT(*) FILTER (WHERE notifications_enabled = true) as with_notifications_enabled,
    COUNT(*) FILTER (WHERE fcm_token IS NOT NULL) as with_fcm_token,
    COUNT(*) FILTER (WHERE notifications_enabled = true AND fcm_token IS NOT NULL) as eligible_for_notifications
FROM user_profiles;

-- 4. Détail des utilisateurs éligibles
SELECT 
    '=== DÉTAIL UTILISATEURS ÉLIGIBLES ===' as section,
    email,
    notification_time,
    notification_timezone_offset_minutes,
    DATE(last_notification_sent_at) = CURRENT_DATE as sent_today,
    fcm_token IS NOT NULL as has_token
FROM user_profiles 
WHERE notifications_enabled = true
  AND fcm_token IS NOT NULL
ORDER BY notification_time;
