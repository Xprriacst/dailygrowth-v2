-- 🔍 DIAGNOSTIC SPÉCIFIQUE pour utilisateur 38118795-21a9-4b3d-afe9-b23c63936c9a
-- À exécuter dans Supabase SQL Editor

-- ======================================
-- 1. CONFIGURATION DE CET UTILISATEUR
-- ======================================
SELECT
    id,
    email,
    notifications_enabled,
    notification_time,
    fcm_token,
    last_notification_sent_at,
    created_at
FROM profiles
WHERE id = '38118795-21a9-4b3d-afe9-b23c63936c9a';

-- ======================================
-- 2. TOUS LES LOGS DE NOTIFICATION POUR CET UTILISATEUR (dernières 48h)
-- ======================================
SELECT
    id,
    trigger_type,
    notification_sent,
    skip_reason,
    error_message,
    notification_time,
    actual_send_time,
    time_diff_minutes,
    challenge_name,
    created_at AT TIME ZONE 'Europe/Paris' as created_at_paris
FROM notification_logs
WHERE user_id = '38118795-21a9-4b3d-afe9-b23c63936c9a'
  AND created_at > NOW() - INTERVAL '48 hours'
ORDER BY created_at DESC;

-- ======================================
-- 3. DÉFIS POUR AUJOURD'HUI
-- ======================================
SELECT
    id,
    challenge_date,
    problematique,
    challenge_name,
    completed,
    created_at
FROM daily_challenges
WHERE user_id = '38118795-21a9-4b3d-afe9-b23c63936c9a'
  AND challenge_date = CURRENT_DATE;

-- ======================================
-- 4. EXÉCUTIONS DU CRON ENTRE 17h20 et 17h50
-- ======================================
SELECT
    r.jobid,
    j.jobname,
    r.status,
    r.start_time AT TIME ZONE 'Europe/Paris' as start_time_paris,
    r.end_time AT TIME ZONE 'Europe/Paris' as end_time_paris,
    r.return_message
FROM cron.job_run_details r
JOIN cron.job j ON r.jobid = j.jobid
WHERE j.jobname = 'challengeme-daily-notifications'
  AND r.start_time AT TIME ZONE 'Europe/Paris' >= '2025-11-11 17:20:00'
  AND r.start_time AT TIME ZONE 'Europe/Paris' <= '2025-11-11 17:50:00'
ORDER BY r.start_time DESC;

-- ======================================
-- 5. HEURE ACTUELLE ET FENÊTRE
-- ======================================
WITH current_paris_time AS (
    SELECT
        NOW() AT TIME ZONE 'Europe/Paris' as now,
        EXTRACT(HOUR FROM (NOW() AT TIME ZONE 'Europe/Paris')) as hour,
        EXTRACT(MINUTE FROM (NOW() AT TIME ZONE 'Europe/Paris')) as minute
),
user_config AS (
    SELECT
        notification_time,
        EXTRACT(HOUR FROM notification_time) as notif_hour,
        EXTRACT(MINUTE FROM notification_time) as notif_minute
    FROM profiles
    WHERE id = '38118795-21a9-4b3d-afe9-b23c63936c9a'
)
SELECT
    cpt.now as heure_actuelle_paris,
    uc.notification_time as heure_configuree,
    ABS(EXTRACT(HOUR FROM uc.notification_time) - cpt.hour) * 60 +
    ABS(EXTRACT(MINUTE FROM uc.notification_time) - cpt.minute) as minutes_diff,
    CASE
        WHEN ABS(EXTRACT(HOUR FROM uc.notification_time) - cpt.hour) * 60 +
             ABS(EXTRACT(MINUTE FROM uc.notification_time) - cpt.minute) <= 15
        THEN '✅ DANS LA FENÊTRE - devrait recevoir notification'
        ELSE '❌ HORS FENÊTRE - pas de notification'
    END as status
FROM current_paris_time cpt, user_config uc;

-- ======================================
-- 6. VÉRIFIER SI LE FCM TOKEN EST BIEN SAUVEGARDÉ
-- ======================================
SELECT
    CASE
        WHEN fcm_token IS NULL THEN '❌ Token manquant'
        WHEN fcm_token = '' THEN '❌ Token vide'
        WHEN fcm_token LIKE 'd6CmUdi5HYhtaDfUPnyV%' THEN '✅ Token correct (commence par d6CmUdi5HYhtaDfUPnyV)'
        ELSE '⚠️ Token présent mais différent'
    END as token_status,
    LENGTH(fcm_token) as token_length,
    LEFT(fcm_token, 30) as token_preview
FROM profiles
WHERE id = '38118795-21a9-4b3d-afe9-b23c63936c9a';
