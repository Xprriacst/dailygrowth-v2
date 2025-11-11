-- 🔍 DIAGNOSTIC CORRIGÉ pour user 38118795-21a9-4b3d-afe9-b23c63936c9a
-- Table correcte: user_profiles (pas profiles)
-- À exécuter dans Supabase SQL Editor

-- ======================================
-- 1. VOTRE CONFIGURATION
-- ======================================
SELECT
    id,
    email,
    notifications_enabled,
    notification_time,
    fcm_token,
    notification_timezone_offset_minutes,
    last_notification_sent_at,
    created_at
FROM user_profiles
WHERE id = '38118795-21a9-4b3d-afe9-b23c63936c9a';

-- ======================================
-- 2. LOGS AUTOUR DE 17h35 (±30 minutes)
-- ======================================
SELECT
    id,
    user_id,
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
  AND created_at AT TIME ZONE 'Europe/Paris' >= '2025-11-11 17:00:00'
  AND created_at AT TIME ZONE 'Europe/Paris' <= '2025-11-11 18:00:00'
ORDER BY created_at DESC;

-- ======================================
-- 3. TOUS VOS LOGS (dernières 24h)
-- ======================================
SELECT
    id,
    trigger_type,
    notification_sent,
    skip_reason,
    error_message,
    time_diff_minutes,
    created_at AT TIME ZONE 'Europe/Paris' as created_at_paris
FROM notification_logs
WHERE user_id = '38118795-21a9-4b3d-afe9-b23c63936c9a'
  AND created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;

-- ======================================
-- 4. DÉFIS AUJOURD'HUI
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
-- 5. EXÉCUTIONS DU CRON ENTRE 17h20 et 17h50
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
-- 6. TOUTES LES EXÉCUTIONS DU CRON (dernière heure)
-- ======================================
SELECT
    r.jobid,
    j.jobname,
    r.status,
    r.start_time AT TIME ZONE 'Europe/Paris' as start_time_paris,
    r.return_message
FROM cron.job_run_details r
JOIN cron.job j ON r.jobid = j.jobid
WHERE j.jobname = 'challengeme-daily-notifications'
  AND r.start_time > NOW() - INTERVAL '1 hour'
ORDER BY r.start_time DESC;

-- ======================================
-- 7. VÉRIFIER LE CRON EST TOUJOURS ACTIF
-- ======================================
SELECT
    jobid,
    schedule,
    jobname,
    active
FROM cron.job
WHERE jobname = 'challengeme-daily-notifications';
