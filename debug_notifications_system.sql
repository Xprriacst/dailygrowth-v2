-- Script de diagnostic complet du système de notifications
-- Pour l'utilisateur expertiaen5min@gmail.com
-- Date: 2025-09-29

-- ===================================
-- 1. VÉRIFIER L'UTILISATEUR
-- ===================================
SELECT 
    id,
    email,
    notifications_enabled,
    notification_time,
    notification_timezone_offset_minutes,
    last_notification_sent_at,
    fcm_token IS NOT NULL as has_fcm_token,
    SUBSTRING(fcm_token, 1, 30) as token_preview,
    created_at,
    updated_at
FROM user_profiles 
WHERE email = 'expertiaen5min@gmail.com';

-- ===================================
-- 2. VÉRIFIER L'HEURE ACTUELLE UTC ET LOCALE
-- ===================================
SELECT 
    NOW() as current_utc_time,
    EXTRACT(HOUR FROM NOW()) as current_utc_hour,
    EXTRACT(MINUTE FROM NOW()) as current_utc_minute,
    TO_CHAR(NOW(), 'HH24:MI:SS') as current_utc_time_formatted;

-- ===================================
-- 3. CALCULER L'HEURE DE NOTIFICATION EN UTC
-- ===================================
-- Pour un utilisateur avec notification_time = '14:30:00' et timezone_offset = 120 (UTC+2)
-- L'heure locale 14:30 = 12:30 UTC
WITH user_config AS (
    SELECT 
        id,
        email,
        notification_time,
        COALESCE(notification_timezone_offset_minutes, 120) as offset_minutes
    FROM user_profiles 
    WHERE email = 'expertiaen5min@gmail.com'
)
SELECT 
    email,
    notification_time as local_time,
    offset_minutes as timezone_offset,
    
    -- Extraire heures et minutes
    EXTRACT(HOUR FROM notification_time::time) as local_hour,
    EXTRACT(MINUTE FROM notification_time::time) as local_minute,
    
    -- Calculer les minutes totales en local
    (EXTRACT(HOUR FROM notification_time::time) * 60 + EXTRACT(MINUTE FROM notification_time::time)) as local_total_minutes,
    
    -- Calculer les minutes totales en UTC
    ((EXTRACT(HOUR FROM notification_time::time) * 60 + EXTRACT(MINUTE FROM notification_time::time) - offset_minutes) % 1440 + 1440) % 1440 as utc_total_minutes,
    
    -- Convertir en heure UTC
    LPAD(FLOOR(((EXTRACT(HOUR FROM notification_time::time) * 60 + EXTRACT(MINUTE FROM notification_time::time) - offset_minutes) % 1440 + 1440) % 1440 / 60)::text, 2, '0') || ':' ||
    LPAD(MOD(((EXTRACT(HOUR FROM notification_time::time) * 60 + EXTRACT(MINUTE FROM notification_time::time) - offset_minutes) % 1440 + 1440) % 1440, 60)::text, 2, '0') as target_utc_time,
    
    -- Heure actuelle UTC
    TO_CHAR(NOW(), 'HH24:MI') as current_utc_time,
    
    -- Différence en minutes
    ABS(
        (EXTRACT(HOUR FROM NOW()) * 60 + EXTRACT(MINUTE FROM NOW())) - 
        ((EXTRACT(HOUR FROM notification_time::time) * 60 + EXTRACT(MINUTE FROM notification_time::time) - offset_minutes) % 1440 + 1440) % 1440
    ) as diff_minutes
FROM user_config;

-- ===================================
-- 4. VÉRIFIER SI LA NOTIFICATION A ÉTÉ ENVOYÉE AUJOURD'HUI
-- ===================================
WITH user_config AS (
    SELECT 
        id,
        email,
        last_notification_sent_at
    FROM user_profiles 
    WHERE email = 'expertiaen5min@gmail.com'
)
SELECT 
    email,
    last_notification_sent_at,
    DATE(last_notification_sent_at) as last_sent_date,
    CURRENT_DATE as today_date,
    DATE(last_notification_sent_at) = CURRENT_DATE as sent_today,
    CASE 
        WHEN DATE(last_notification_sent_at) = CURRENT_DATE THEN '❌ Déjà envoyée aujourd''hui - sera bloquée'
        ELSE '✅ Pas encore envoyée aujourd''hui - peut être envoyée'
    END as status
FROM user_config;

-- ===================================
-- 5. TOUS LES UTILISATEURS AVEC NOTIFICATIONS ACTIVÉES
-- ===================================
SELECT 
    id,
    email,
    notification_time,
    COALESCE(notification_timezone_offset_minutes, 120) as offset_minutes,
    fcm_token IS NOT NULL as has_token,
    DATE(last_notification_sent_at) = CURRENT_DATE as sent_today
FROM user_profiles 
WHERE notifications_enabled = true
AND fcm_token IS NOT NULL
ORDER BY notification_time;

-- ===================================
-- 6. VÉRIFIER LES EDGE FUNCTIONS DISPONIBLES
-- ===================================
-- Cette requête peut ne pas fonctionner, c'est juste pour référence
-- SELECT * FROM pg_functions WHERE proname LIKE '%notification%';
