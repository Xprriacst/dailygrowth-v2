-- Script pour nettoyer les données utilisateurs pour les tests
-- ATTENTION: Ceci supprimera TOUTES les données utilisateurs

-- Supprimer les micro-défis utilisateurs
DELETE FROM user_micro_challenges;

-- Supprimer les défis quotidiens
DELETE FROM daily_challenges;

-- Supprimer les citations quotidiennes
DELETE FROM daily_quotes;

-- Supprimer les profils utilisateurs
DELETE FROM user_profiles;

-- Supprimer les utilisateurs de l'auth (nécessite des privilèges admin)
-- Cette partie doit être exécutée depuis le dashboard Supabase
-- DELETE FROM auth.users;

-- Réinitialiser les séquences si nécessaire
-- ALTER SEQUENCE user_micro_challenges_id_seq RESTART WITH 1;
-- ALTER SEQUENCE daily_challenges_id_seq RESTART WITH 1;
-- ALTER SEQUENCE daily_quotes_id_seq RESTART WITH 1;

-- Confirmation
SELECT 'Nettoyage terminé - Toutes les données utilisateurs ont été supprimées' as status;
