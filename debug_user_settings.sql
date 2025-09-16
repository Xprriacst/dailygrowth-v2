-- Debug des paramètres utilisateur pour les notifications
-- À exécuter dans Supabase SQL Editor

-- 1. Vérifier si l'utilisateur existe et ses paramètres
SELECT 
    id,
    email,
    notifications_enabled,
    reminder_notifications_enabled,
    notification_time,
    fcm_token IS NOT NULL as has_fcm_token,
    created_at
FROM user_profiles 
WHERE email = 'expertiaen5min@gmail.com';

-- 2. Vérifier tous les utilisateurs avec notifications activées
SELECT 
    id,
    email,
    notifications_enabled,
    reminder_notifications_enabled,
    notification_time,
    fcm_token IS NOT NULL as has_fcm_token
FROM user_profiles 
WHERE notifications_enabled = true 
AND reminder_notifications_enabled = true 
AND fcm_token IS NOT NULL;

-- 3. Vérifier la structure de la table
\d user_profiles;