-- Configuration notification quotidienne pour 9h30
-- Réinitialise le blocage pour permettre l'envoi demain matin

UPDATE user_profiles 
SET 
    notification_time = '09:30:00',
    notification_timezone_offset_minutes = 120,  -- UTC+2 France
    last_notification_sent_at = NULL  -- Réinitialise le blocage
WHERE email = 'expertiaen5min@gmail.com';

-- Vérification
SELECT 
    email,
    notification_time,
    notification_timezone_offset_minutes,
    last_notification_sent_at
FROM user_profiles 
WHERE email = 'expertiaen5min@gmail.com';
