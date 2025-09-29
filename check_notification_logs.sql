-- Vérifier les logs de notifications
-- Il est maintenant 21:17, le cron devrait avoir tourné à 21:15

-- 1. Voir tous les logs récents
SELECT 
    '=== DERNIERS LOGS (TOUS) ===' as section,
    created_at AT TIME ZONE 'Europe/Paris' as heure_locale,
    trigger_type,
    notification_sent,
    skip_reason,
    error_message,
    target_utc_time,
    actual_utc_time,
    time_diff_minutes
FROM notification_logs
ORDER BY created_at DESC
LIMIT 20;

-- 2. Logs spécifiques à ton utilisateur
SELECT 
    '=== LOGS UTILISATEUR expertiaen5min ===' as section,
    created_at AT TIME ZONE 'Europe/Paris' as heure_locale,
    trigger_type,
    notification_sent,
    skip_reason,
    notification_time as heure_config,
    target_utc_time as heure_cible_utc,
    actual_utc_time as heure_execution_utc,
    time_diff_minutes as difference_minutes,
    fcm_token_present,
    error_message
FROM notification_logs
WHERE user_id = (SELECT id FROM user_profiles WHERE email = 'expertiaen5min@gmail.com')
ORDER BY created_at DESC
LIMIT 10;

-- 3. Résumé
SELECT 
    '=== RÉSUMÉ ===' as section,
    COUNT(*) as total_logs,
    COUNT(*) FILTER (WHERE notification_sent = true) as envoyees,
    COUNT(*) FILTER (WHERE notification_sent = false) as non_envoyees,
    MAX(created_at) AT TIME ZONE 'Europe/Paris' as derniere_tentative
FROM notification_logs
WHERE user_id = (SELECT id FROM user_profiles WHERE email = 'expertiaen5min@gmail.com');

-- 4. Si aucun log, vérifier que la table existe bien
SELECT 
    '=== VÉRIFICATION TABLE ===' as section,
    COUNT(*) as nombre_total_logs
FROM notification_logs;
