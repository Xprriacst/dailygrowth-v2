-- Script pour vérifier les paramètres de notification de l'utilisateur expertiaen5min@gmail.com
-- À exécuter dans Supabase SQL Editor

-- 1. Vérifier si l'utilisateur existe et ses paramètres complets
SELECT 
    id,
    email,
    full_name,
    notifications_enabled,
    reminder_notifications_enabled,
    notification_time,
    fcm_token IS NOT NULL as has_fcm_token,
    LENGTH(fcm_token) as token_length,
    status,
    created_at,
    updated_at
FROM user_profiles 
WHERE email = 'expertiaen5min@gmail.com';

-- 2. Si l'utilisateur n'existe pas, le créer avec les bons paramètres
INSERT INTO user_profiles (
    email,
    full_name,
    notifications_enabled,
    reminder_notifications_enabled,
    notification_time,
    status
) 
SELECT 
    'expertiaen5min@gmail.com',
    'Expert 5 Min',
    true,
    true,
    '09:43:00',
    'active'
WHERE NOT EXISTS (
    SELECT 1 FROM user_profiles WHERE email = 'expertiaen5min@gmail.com'
);

-- 3. Mettre à jour les paramètres si l'utilisateur existe déjà
UPDATE user_profiles 
SET 
    notifications_enabled = true,
    reminder_notifications_enabled = true,
    notification_time = '09:43:00',
    status = 'active',
    updated_at = now()
WHERE email = 'expertiaen5min@gmail.com';

-- 4. Vérifier le résultat final
SELECT 
    id,
    email,
    notifications_enabled,
    reminder_notifications_enabled,
    notification_time,
    fcm_token IS NOT NULL as has_fcm_token,
    status
FROM user_profiles 
WHERE email = 'expertiaen5min@gmail.com';

-- 5. Afficher tous les utilisateurs avec notifications activées (pour debug)
SELECT 
    id,
    email,
    notification_time,
    fcm_token IS NOT NULL as has_fcm_token,
    created_at
FROM user_profiles 
WHERE notifications_enabled = true 
AND reminder_notifications_enabled = true
ORDER BY notification_time;