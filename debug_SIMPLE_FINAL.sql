-- 🔍 DIAGNOSTIC SIMPLE ET CORRIGÉ
-- User: 38118795-21a9-4b3d-afe9-b23c63936c9a
-- À exécuter dans Supabase SQL Editor

-- ======================================
-- 1. VOTRE CONFIGURATION
-- ======================================
SELECT
    'Configuration utilisateur' as section,
    notifications_enabled,
    notification_time,
    CASE
        WHEN fcm_token IS NULL THEN '❌ AUCUN TOKEN'
        WHEN fcm_token = '' THEN '❌ TOKEN VIDE'
        ELSE '✅ Token présent: ' || LEFT(fcm_token, 30) || '...'
    END as fcm_token_status,
    last_notification_sent_at
FROM user_profiles
WHERE id = '38118795-21a9-4b3d-afe9-b23c63936c9a';

-- ======================================
-- 2. LOGS DE NOTIFICATION (dernières 2 heures)
-- ======================================
SELECT
    'Logs notifications' as section,
    notification_sent,
    skip_reason,
    error_message,
    time_diff_minutes,
    created_at AT TIME ZONE 'Europe/Paris' as heure_paris
FROM notification_logs
WHERE user_id = '38118795-21a9-4b3d-afe9-b23c63936c9a'
  AND created_at > NOW() - INTERVAL '2 hours'
ORDER BY created_at DESC;

-- ======================================
-- 3. DÉFIS (créés aujourd'hui)
-- ======================================
SELECT
    'Défis aujourd''hui' as section,
    COUNT(*) as nombre_defis,
    MAX(created_at) as dernier_defi_cree
FROM daily_challenges
WHERE user_id = '38118795-21a9-4b3d-afe9-b23c63936c9a'
  AND DATE(created_at AT TIME ZONE 'Europe/Paris') = CURRENT_DATE;

-- ======================================
-- 4. EXÉCUTIONS DU CRON (17h20-17h50)
-- ======================================
SELECT
    'Exécutions cron 17h20-17h50' as section,
    r.start_time AT TIME ZONE 'Europe/Paris' as heure_execution,
    r.status,
    SUBSTRING(r.return_message, 1, 100) as message
FROM cron.job_run_details r
JOIN cron.job j ON r.jobid = j.jobid
WHERE j.jobname = 'challengeme-daily-notifications'
  AND r.start_time AT TIME ZONE 'Europe/Paris' >= '2025-11-11 17:20:00'
  AND r.start_time AT TIME ZONE 'Europe/Paris' <= '2025-11-11 17:50:00'
ORDER BY r.start_time DESC;

-- ======================================
-- 5. STATUT DU CRON JOB
-- ======================================
SELECT
    'Statut cron job' as section,
    jobid,
    jobname,
    active,
    schedule
FROM cron.job
WHERE jobname = 'challengeme-daily-notifications';
