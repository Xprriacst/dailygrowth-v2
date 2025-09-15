-- Test manuel du système de notifications push
-- À exécuter dans Supabase SQL Editor

-- Au lieu d'appeler les fonctions depuis SQL, 
-- testons en regardant les données et les logs

-- MÉTHODE ALTERNATIVE : Tester via l'interface Supabase
-- 1. Aller dans Dashboard → Edge Functions → cron-daily-notifications
-- 2. Cliquer "Invoke" avec ce payload : {"trigger": "manual-test"}
-- 3. Observer les logs et la réponse

-- 3. D'abord ajouter la colonne fcm_token si elle n'existe pas
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- 4. Vérifier les utilisateurs avec notifications activées
SELECT 
  id,
  notification_time,
  notifications_enabled,
  reminder_notifications_enabled,
  fcm_token IS NOT NULL as has_fcm_token,
  created_at
FROM user_profiles 
WHERE notifications_enabled = true 
  AND reminder_notifications_enabled = true
ORDER BY notification_time;

-- 5. Vérifier les jobs cron actifs
SELECT 
  jobname,
  schedule,
  active,
  database
FROM cron.job;

-- 6. Heure actuelle pour référence
SELECT 
  now() as current_utc_time,
  EXTRACT(HOUR FROM now()) as current_hour,
  EXTRACT(MINUTE FROM now()) as current_minute,
  to_char(now(), 'HH24:MI') as current_time_formatted;