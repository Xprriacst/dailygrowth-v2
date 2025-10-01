-- Test d'insertion directe dans notification_logs
-- Pour vérifier si c'est un problème de permissions

INSERT INTO notification_logs (
    user_id,
    trigger_type,
    notification_sent,
    skip_reason,
    notification_time,
    timezone_offset_minutes,
    target_utc_time,
    actual_utc_time,
    time_diff_minutes,
    fcm_token_present
) VALUES (
    (SELECT id FROM user_profiles WHERE email = 'expertiaen5min@gmail.com'),
    'manual-test',
    false,
    'test_insertion',
    '21:11:00',
    120,
    '19:11:00',
    '19:21:00',
    10,
    true
);

-- Vérifier
SELECT * FROM notification_logs ORDER BY created_at DESC LIMIT 1;
