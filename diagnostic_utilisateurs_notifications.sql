-- 🔍 DIAGNOSTIC COMPLET : Pourquoi les notifications ne sont pas envoyées
-- À exécuter dans Supabase SQL Editor

-- ======================================
-- 1. ÉTAT DES UTILISATEURS
-- ======================================

SELECT
    id,
    email,
    notifications_enabled,
    notification_time,
    fcm_token IS NOT NULL as has_fcm_token,
    LENGTH(fcm_token) as token_length,
    last_notification_sent_at,
    created_at
FROM profiles
ORDER BY notifications_enabled DESC, notification_time;

-- ======================================
-- 2. LOGS DES DERNIÈRES TENTATIVES (24h)
-- ======================================

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
LIMIT 30;

-- ======================================
-- 3. STATISTIQUES PAR RAISON DE SKIP
-- ======================================

SELECT
    skip_reason,
    COUNT(*) as count,
    MIN(created_at) as first_occurrence,
    MAX(created_at) as last_occurrence
FROM notification_logs
WHERE created_at > NOW() - INTERVAL '7 days'
    AND skip_reason IS NOT NULL
GROUP BY skip_reason
ORDER BY count DESC;

-- ======================================
-- 4. HEURE ACTUELLE ET UTILISATEURS ÉLIGIBLES
-- ======================================

WITH current_time_info AS (
    SELECT
        NOW() as utc_now,
        NOW() AT TIME ZONE 'Europe/Paris' as paris_now,
        EXTRACT(HOUR FROM (NOW() AT TIME ZONE 'Europe/Paris')) as paris_hour,
        EXTRACT(MINUTE FROM (NOW() AT TIME ZONE 'Europe/Paris')) as paris_minute
)
SELECT
    cti.*,
    (SELECT COUNT(*)
     FROM profiles
     WHERE notifications_enabled = true
       AND fcm_token IS NOT NULL
       AND notification_time IS NOT NULL) as total_eligible_users,
    (SELECT COUNT(*)
     FROM profiles p
     WHERE p.notifications_enabled = true
       AND p.fcm_token IS NOT NULL
       AND p.notification_time IS NOT NULL
       AND ABS(EXTRACT(HOUR FROM p.notification_time) - cti.paris_hour) * 60 +
           ABS(EXTRACT(MINUTE FROM p.notification_time) - cti.paris_minute) <= 15
    ) as users_in_window_now
FROM current_time_info cti;

-- ======================================
-- 5. DÉTAIL DES UTILISATEURS AVEC FENÊTRE
-- ======================================

WITH current_paris_time AS (
    SELECT
        NOW() AT TIME ZONE 'Europe/Paris' as now,
        EXTRACT(HOUR FROM (NOW() AT TIME ZONE 'Europe/Paris')) as hour,
        EXTRACT(MINUTE FROM (NOW() AT TIME ZONE 'Europe/Paris')) as minute
)
SELECT
    p.id,
    p.email,
    p.notifications_enabled,
    p.notification_time,
    EXTRACT(HOUR FROM p.notification_time) as notif_hour,
    EXTRACT(MINUTE FROM p.notification_time) as notif_minute,
    p.fcm_token IS NOT NULL as has_token,
    cpt.hour as current_hour,
    cpt.minute as current_minute,
    ABS(EXTRACT(HOUR FROM p.notification_time) - cpt.hour) * 60 +
    ABS(EXTRACT(MINUTE FROM p.notification_time) - cpt.minute) as minutes_diff,
    CASE
        WHEN ABS(EXTRACT(HOUR FROM p.notification_time) - cpt.hour) * 60 +
             ABS(EXTRACT(MINUTE FROM p.notification_time) - cpt.minute) <= 15
        THEN '✅ Dans la fenêtre'
        ELSE '❌ Hors fenêtre'
    END as status
FROM profiles p
CROSS JOIN current_paris_time cpt
WHERE p.notifications_enabled = true
ORDER BY minutes_diff;

-- ======================================
-- 6. DERNIÈRES EXÉCUTIONS DU CRON JOB
-- ======================================

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
ORDER BY r.start_time DESC
LIMIT 10;

-- ======================================
-- 7. VÉRIFIER SI DES DÉFIS EXISTENT AUJOURD'HUI
-- ======================================

SELECT
    user_id,
    challenge_date,
    problematique,
    challenge_name,
    completed,
    created_at
FROM daily_challenges
WHERE challenge_date = CURRENT_DATE
ORDER BY created_at DESC;

-- ======================================
-- 8. RÉSUMÉ COMPLET
-- ======================================

SELECT
    'Total utilisateurs' as metric,
    COUNT(*) as value
FROM profiles
UNION ALL
SELECT
    'Utilisateurs avec notifications activées',
    COUNT(*)
FROM profiles
WHERE notifications_enabled = true
UNION ALL
SELECT
    'Utilisateurs avec FCM token',
    COUNT(*)
FROM profiles
WHERE fcm_token IS NOT NULL
UNION ALL
SELECT
    'Utilisateurs avec notification_time configurée',
    COUNT(*)
FROM profiles
WHERE notification_time IS NOT NULL
UNION ALL
SELECT
    'Utilisateurs ÉLIGIBLES (tout configuré)',
    COUNT(*)
FROM profiles
WHERE notifications_enabled = true
  AND fcm_token IS NOT NULL
  AND notification_time IS NOT NULL
UNION ALL
SELECT
    'Notifications envoyées (dernières 24h)',
    COUNT(*)
FROM notification_logs
WHERE notification_sent = true
  AND created_at > NOW() - INTERVAL '24 hours'
UNION ALL
SELECT
    'Tentatives totales (dernières 24h)',
    COUNT(*)
FROM notification_logs
WHERE created_at > NOW() - INTERVAL '24 hours';
