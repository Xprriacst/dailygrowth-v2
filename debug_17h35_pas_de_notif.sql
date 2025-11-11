-- 🚨 DIAGNOSTIC : Pourquoi aucune notification à 17h35 ?
-- À exécuter dans Supabase SQL Editor

-- ======================================
-- 1. HEURE ACTUELLE
-- ======================================
SELECT
    NOW() as utc_now,
    NOW() AT TIME ZONE 'Europe/Paris' as paris_now;

-- ======================================
-- 2. VOTRE CONFIGURATION
-- ======================================
-- IMPORTANT: Remplacez 'votre-email@example.com' par votre vrai email
SELECT
    id,
    email,
    notifications_enabled,
    notification_time,
    fcm_token IS NOT NULL as has_fcm_token,
    CASE
        WHEN fcm_token IS NOT NULL THEN CONCAT(LEFT(fcm_token, 20), '...')
        ELSE NULL
    END as fcm_token_preview,
    last_notification_sent_at,
    created_at
FROM profiles
WHERE email = 'votre-email@example.com';  -- ⚠️ REMPLACEZ ICI

-- ======================================
-- 3. LOGS AUTOUR DE 17h35 (±1 heure)
-- ======================================
SELECT
    nl.id,
    nl.user_id,
    p.email,
    nl.trigger_type,
    nl.notification_sent,
    nl.skip_reason,
    nl.error_message,
    nl.notification_time,
    nl.actual_send_time,
    nl.time_diff_minutes,
    nl.created_at AT TIME ZONE 'Europe/Paris' as created_at_paris
FROM notification_logs nl
JOIN profiles p ON nl.user_id = p.id
WHERE nl.created_at AT TIME ZONE 'Europe/Paris' >= '2025-11-11 16:35:00'
  AND nl.created_at AT TIME ZONE 'Europe/Paris' <= '2025-11-11 18:35:00'
ORDER BY nl.created_at DESC;

-- ======================================
-- 4. EXÉCUTIONS DU CRON entre 17h20 et 17h50
-- ======================================
SELECT
    r.jobid,
    j.jobname,
    r.runid,
    r.status,
    r.start_time AT TIME ZONE 'Europe/Paris' as start_time_paris,
    r.end_time AT TIME ZONE 'Europe/Paris' as end_time_paris,
    r.return_message,
    EXTRACT(EPOCH FROM (r.end_time - r.start_time)) AS duration_seconds
FROM cron.job_run_details r
JOIN cron.job j ON r.jobid = j.jobid
WHERE j.jobname = 'challengeme-daily-notifications'
  AND r.start_time AT TIME ZONE 'Europe/Paris' >= '2025-11-11 17:20:00'
  AND r.start_time AT TIME ZONE 'Europe/Paris' <= '2025-11-11 17:50:00'
ORDER BY r.start_time DESC;

-- ======================================
-- 5. AVEZ-VOUS UN DÉFI AUJOURD'HUI ?
-- ======================================
-- IMPORTANT: Remplacez 'votre-email@example.com' par votre vrai email
SELECT
    dc.id,
    dc.user_id,
    p.email,
    dc.challenge_date,
    dc.problematique,
    dc.challenge_name,
    dc.completed,
    dc.created_at
FROM daily_challenges dc
JOIN profiles p ON dc.user_id = p.id
WHERE p.email = 'votre-email@example.com'  -- ⚠️ REMPLACEZ ICI
  AND dc.challenge_date = CURRENT_DATE
ORDER BY dc.created_at DESC;

-- ======================================
-- 6. TOUS VOS LOGS (dernières 24h)
-- ======================================
-- IMPORTANT: Remplacez 'votre-email@example.com' par votre vrai email
SELECT
    nl.id,
    nl.trigger_type,
    nl.notification_sent,
    nl.skip_reason,
    nl.error_message,
    nl.notification_time,
    nl.actual_send_time,
    nl.time_diff_minutes,
    nl.created_at AT TIME ZONE 'Europe/Paris' as created_at_paris
FROM notification_logs nl
JOIN profiles p ON nl.user_id = p.id
WHERE p.email = 'votre-email@example.com'  -- ⚠️ REMPLACEZ ICI
  AND nl.created_at > NOW() - INTERVAL '24 hours'
ORDER BY nl.created_at DESC;

-- ======================================
-- 7. TOUS LES UTILISATEURS ET LEUR CONFIG
-- ======================================
SELECT
    id,
    email,
    notifications_enabled,
    notification_time,
    fcm_token IS NOT NULL as has_fcm_token,
    last_notification_sent_at
FROM profiles
ORDER BY notifications_enabled DESC, notification_time;

-- ======================================
-- 8. VÉRIFIER SI LE CRON EST TOUJOURS ACTIF
-- ======================================
SELECT
    jobid,
    schedule,
    jobname,
    active,
    nodename
FROM cron.job
WHERE jobname = 'challengeme-daily-notifications';
