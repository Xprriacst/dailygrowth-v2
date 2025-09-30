-- Vérifier que la notification a été envoyée à 19:30
-- Exécuter APRÈS 19:30

-- 1. Derniers logs
SELECT 
    created_at AT TIME ZONE 'Europe/Paris' as heure_paris,
    notification_sent,
    skip_reason,
    notification_time,
    target_utc_time,
    actual_utc_time,
    time_diff_minutes,
    challenge_name
FROM notification_logs
WHERE user_id = (SELECT id FROM user_profiles WHERE email = 'expertiaen5min@gmail.com')
ORDER BY created_at DESC
LIMIT 5;

-- 2. Si notification_sent = true → Reconfigurer pour 09:30 demain
UPDATE user_profiles 
SET notification_time = '09:30:00'
WHERE email = 'expertiaen5min@gmail.com';

-- 3. Vérifier la config
SELECT 
    email,
    notification_time,
    notifications_enabled,
    last_notification_sent_at
FROM user_profiles 
WHERE email = 'expertiaen5min@gmail.com';
