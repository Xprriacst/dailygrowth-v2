-- LOGS RAPIDE
SELECT 
    created_at AT TIME ZONE 'Europe/Paris' as heure_paris,
    notification_sent,
    skip_reason,
    target_utc_time,
    actual_utc_time,
    time_diff_minutes
FROM notification_logs
ORDER BY created_at DESC
LIMIT 10;
