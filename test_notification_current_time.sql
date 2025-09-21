-- Forcer temporairement l'heure de notification à l'heure actuelle pour tester
-- Exécuter dans Supabase SQL Editor

-- 1. Sauvegarder l'heure actuelle
SELECT 
    email,
    notification_time as original_time
FROM user_profiles 
WHERE email = 'expertiaen5min@gmail.com';

-- 2. Mettre l'heure de notification à maintenant (19:20 UTC)
UPDATE user_profiles 
SET notification_time = '19:20:00'
WHERE email = 'expertiaen5min@gmail.com';

-- 3. Vérifier la modification
SELECT 
    email,
    notification_time
FROM user_profiles 
WHERE email = 'expertiaen5min@gmail.com';

-- 4. IMPORTANT: Remettre l'heure d'origine après le test
-- UPDATE user_profiles 
-- SET notification_time = '09:43:00'
-- WHERE email = 'expertiaen5min@gmail.com';