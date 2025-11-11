-- Test d'envoi direct de notification via HTTP depuis PostgreSQL
-- Ceci permet de tester l'envoi réel sans attendre le cron

-- 1. D'abord, récupère le token FCM de l'utilisateur
SELECT 
    'Token FCM pour expertiaen5min@gmail.com:' as info,
    SUBSTRING(fcm_token, 1, 50) || '...' as token_preview,
    LENGTH(fcm_token) as token_length
FROM user_profiles 
WHERE email = 'expertiaen5min@gmail.com';

-- 2. Appeler send-push-notification avec le token
-- Note: Remplace YOUR_FCM_TOKEN_HERE par le vrai token depuis la requête ci-dessus
SELECT net.http_post(
    url := 'https://hekdcsulxrukfturuone.supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhla2Rjc3VseHJ1a2Z0dXJ1b25lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDA1MTIwNCwiZXhwIjoyMDY5NjI3MjA0fQ.sEy3z7nvaQ-k9KrXUa47ATyfRrEtvmzdxusgfjVPylk'
    ),
    body := jsonb_build_object(
        'fcmToken', (SELECT fcm_token FROM user_profiles WHERE email = 'expertiaen5min@gmail.com'),
        'title', '🧪 Test Direct SQL',
        'body', 'Notification de test envoyée depuis SQL',
        'url', '/#/challenges'
    )
) as http_response;
