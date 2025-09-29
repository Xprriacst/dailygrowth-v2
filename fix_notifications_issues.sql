-- ════════════════════════════════════════════════════════════════════
-- CORRECTIONS SYSTÈME NOTIFICATIONS DAILYGROWTH
-- Date: 29 septembre 2025
-- ════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════
-- ÉTAPE 1 : DIAGNOSTIC INITIAL
-- ═══════════════════════════════════════════════════════════════════

-- Voir l'état actuel du système
SELECT 
    'État actuel du système de notifications' as info,
    COUNT(*) FILTER (WHERE notifications_enabled = true) as users_with_notifications_enabled,
    COUNT(*) FILTER (WHERE fcm_token IS NOT NULL) as users_with_fcm_token,
    COUNT(*) FILTER (WHERE notifications_enabled = true AND fcm_token IS NOT NULL) as users_ready_for_notifications
FROM user_profiles;

-- Voir l'utilisateur de test
SELECT 
    '═══ UTILISATEUR TEST: expertiaen5min@gmail.com ═══' as section;
    
SELECT 
    id,
    email,
    notifications_enabled,
    notification_time,
    notification_timezone_offset_minutes,
    last_notification_sent_at,
    DATE(last_notification_sent_at) = CURRENT_DATE as notification_sent_today,
    fcm_token IS NOT NULL as has_fcm_token,
    SUBSTRING(fcm_token, 1, 40) || '...' as token_preview
FROM user_profiles 
WHERE email = 'expertiaen5min@gmail.com';

-- ═══════════════════════════════════════════════════════════════════
-- ÉTAPE 2 : VÉRIFIER LE CRON JOB
-- ═══════════════════════════════════════════════════════════════════

SELECT 
    '═══ CRON JOBS ACTIFS ═══' as section;

-- Vérifier si pg_cron est installé
SELECT * FROM pg_extension WHERE extname = 'pg_cron';

-- Voir tous les cron jobs (si pg_cron est installé)
SELECT 
    jobid,
    jobname,
    schedule,
    command,
    active,
    jobid IN (SELECT jobid FROM cron.job_run_details ORDER BY start_time DESC LIMIT 1) as recently_run
FROM cron.job 
WHERE jobname LIKE '%notification%';

-- Voir les dernières exécutions
SELECT 
    job_id,
    status,
    start_time,
    end_time,
    return_message
FROM cron.job_run_details 
WHERE job_id IN (SELECT jobid FROM cron.job WHERE jobname LIKE '%notification%')
ORDER BY start_time DESC 
LIMIT 10;

-- ═══════════════════════════════════════════════════════════════════
-- ÉTAPE 3 : CORRECTIONS
-- ═══════════════════════════════════════════════════════════════════

-- CORRECTION 1 : Réinitialiser last_notification_sent_at pour les tests
-- ⚠️ À exécuter seulement si vous voulez permettre un nouvel envoi aujourd'hui
UPDATE user_profiles 
SET last_notification_sent_at = NULL
WHERE email = 'expertiaen5min@gmail.com'
  AND DATE(last_notification_sent_at) = CURRENT_DATE;

SELECT 'CORRECTION 1 : last_notification_sent_at réinitialisé' as status;

-- CORRECTION 2 : Vérifier/définir le timezone offset
-- Pour la France (UTC+2 en été, UTC+1 en hiver)
UPDATE user_profiles 
SET notification_timezone_offset_minutes = 120  -- UTC+2
WHERE email = 'expertiaen5min@gmail.com'
  AND notification_timezone_offset_minutes IS NULL;

SELECT 'CORRECTION 2 : timezone offset configuré' as status;

-- CORRECTION 3 : Activer les notifications si désactivées
UPDATE user_profiles 
SET 
    notifications_enabled = true,
    reminder_notifications_enabled = true
WHERE email = 'expertiaen5min@gmail.com'
  AND notifications_enabled = false;

SELECT 'CORRECTION 3 : notifications activées' as status;

-- ═══════════════════════════════════════════════════════════════════
-- ÉTAPE 4 : CONFIGURATION HEURE DE TEST
-- ═══════════════════════════════════════════════════════════════════

-- Option A : Définir l'heure actuelle + 5 minutes pour test immédiat
-- ⚠️ Décommenter et ajuster l'heure selon votre besoin
/*
UPDATE user_profiles 
SET 
    notification_time = '21:05:00',  -- Ajuster selon l'heure actuelle + 5 min
    notification_timezone_offset_minutes = 120,
    last_notification_sent_at = NULL
WHERE email = 'expertiaen5min@gmail.com';

SELECT 'HEURE DE TEST : configurée pour ' || notification_time as status
FROM user_profiles 
WHERE email = 'expertiaen5min@gmail.com';
*/

-- Option B : Configuration pour une heure spécifique demain
-- Exemple : 09:00 du matin
/*
UPDATE user_profiles 
SET 
    notification_time = '09:00:00',
    notification_timezone_offset_minutes = 120,
    last_notification_sent_at = NULL
WHERE email = 'expertiaen5min@gmail.com';
*/

-- ═══════════════════════════════════════════════════════════════════
-- ÉTAPE 5 : CRÉER CRON JOB SI MANQUANT
-- ═══════════════════════════════════════════════════════════════════

-- Vérifier si le cron existe déjà
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM cron.job WHERE jobname = 'daily-notifications-check'
    ) THEN
        -- Créer le cron job
        PERFORM cron.schedule(
            'daily-notifications-check',
            '*/15 * * * *',  -- Toutes les 15 minutes
            $$
            SELECT
                net.http_post(
                    url := 'https://hekdcsulxrukfturuone.supabase.co/functions/v1/cron-daily-notifications',
                    headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk"}'::jsonb,
                    body := ('{"trigger": "cron", "timestamp": "' || now()::text || '"}')::jsonb
                );
            $$
        );
        
        RAISE NOTICE 'Cron job créé avec succès';
    ELSE
        RAISE NOTICE 'Cron job existe déjà';
    END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════════
-- ÉTAPE 6 : VÉRIFICATION FINALE
-- ═══════════════════════════════════════════════════════════════════

SELECT 
    '═══ VÉRIFICATION FINALE ═══' as section;

-- État final de l'utilisateur
SELECT 
    email,
    notifications_enabled,
    notification_time,
    notification_timezone_offset_minutes as timezone_offset,
    last_notification_sent_at,
    fcm_token IS NOT NULL as has_fcm_token,
    CASE 
        WHEN NOT notifications_enabled THEN '❌ Notifications désactivées'
        WHEN fcm_token IS NULL THEN '❌ Pas de FCM token'
        WHEN DATE(last_notification_sent_at) = CURRENT_DATE THEN '⚠️ Déjà envoyée aujourd''hui'
        ELSE '✅ Prêt pour envoi'
    END as status
FROM user_profiles 
WHERE email = 'expertiaen5min@gmail.com';

-- Calcul de la prochaine opportunité d'envoi
WITH user_config AS (
    SELECT 
        notification_time,
        COALESCE(notification_timezone_offset_minutes, 120) as offset_minutes
    FROM user_profiles 
    WHERE email = 'expertiaen5min@gmail.com'
),
time_calc AS (
    SELECT 
        EXTRACT(HOUR FROM notification_time::time) as local_hour,
        EXTRACT(MINUTE FROM notification_time::time) as local_minute,
        offset_minutes
    FROM user_config
)
SELECT 
    TO_CHAR(CURRENT_TIMESTAMP, 'HH24:MI:SS') as heure_actuelle_utc,
    notification_time as heure_notification_locale,
    offset_minutes as timezone_offset_minutes,
    -- Calculer l'heure UTC cible
    LPAD(
        FLOOR(
            ((EXTRACT(HOUR FROM notification_time::time) * 60 + EXTRACT(MINUTE FROM notification_time::time) - offset_minutes) % 1440 + 1440) % 1440 / 60
        )::text, 
        2, '0'
    ) || ':' ||
    LPAD(
        MOD(
            ((EXTRACT(HOUR FROM notification_time::time) * 60 + EXTRACT(MINUTE FROM notification_time::time) - offset_minutes) % 1440 + 1440) % 1440, 
            60
        )::text, 
        2, '0'
    ) as heure_notification_utc,
    '✅ La notification sera envoyée quand cron passera dans la fenêtre de ±15 minutes' as info
FROM user_profiles, user_config
WHERE email = 'expertiaen5min@gmail.com';

-- ═══════════════════════════════════════════════════════════════════
-- RÉSUMÉ DES ACTIONS EFFECTUÉES
-- ═══════════════════════════════════════════════════════════════════

SELECT 
    '✅ Script de correction exécuté avec succès' as resultat,
    NOW() as timestamp;
