-- Script pour nettoyer les badges incorrects attribués à tort
-- À exécuter dans Supabase SQL Editor

-- PARTIE 1 : DIAGNOSTIC
-- =====================

-- 1. Récupérer les utilisateurs avec leurs vrais stats
SELECT
    au.id,
    au.email,
    up.full_name,
    up.streak_count,
    up.created_at,
    CURRENT_DATE - up.created_at::date as days_since_signup,
    (SELECT COUNT(*) FROM daily_challenges dc
     WHERE dc.user_id = au.id AND dc.status = 'completed') as total_completed,
    (SELECT COUNT(DISTINCT DATE(completed_at)) FROM daily_challenges dc
     WHERE dc.user_id = au.id AND dc.status = 'completed') as unique_days_completed
FROM auth.users au
LEFT JOIN user_profiles up ON au.id = up.id
ORDER BY au.email;

-- 2. Vérifier les achievements attribués avec les vrais stats
SELECT
    au.email,
    ua.achievement_type,
    ua.achievement_name,
    ua.description,
    ua.unlocked_at,
    up.streak_count as current_streak,
    (SELECT COUNT(*) FROM daily_challenges dc
     WHERE dc.user_id = au.id AND dc.status = 'completed') as total_completed
FROM user_achievements ua
JOIN auth.users au ON ua.user_id = au.id
LEFT JOIN user_profiles up ON au.id = up.id
ORDER BY au.email, ua.unlocked_at DESC;

-- PARTIE 2 : IDENTIFICATION DES BADGES INCORRECTS
-- ================================================

-- 3. Badges de streak incorrects (ex: "Deux Mois de Constance" avec streak < 60)
SELECT
    au.email,
    ua.achievement_name,
    ua.description,
    up.streak_count as current_streak,
    ua.id as achievement_id
FROM user_achievements ua
JOIN auth.users au ON ua.user_id = au.id
LEFT JOIN user_profiles up ON au.id = up.id
WHERE ua.achievement_type = 'streak'
AND (
    (ua.achievement_name = 'Premier Élan' AND up.streak_count < 3)
    OR (ua.achievement_name = 'Semaine Parfaite' AND up.streak_count < 7)
    OR (ua.achievement_name = 'Deux Semaines de Force' AND up.streak_count < 14)
    OR (ua.achievement_name = 'Mois de Détermination' AND up.streak_count < 30)
    OR (ua.achievement_name = 'Deux Mois de Constance' AND up.streak_count < 60)
    OR (ua.achievement_name = 'Centurion' AND up.streak_count < 100)
    OR (ua.achievement_name = 'Année de Croissance' AND up.streak_count < 365)
);

-- 4. Badges de challenges incorrects (ex: "Expert" avec moins de 50 défis)
SELECT
    au.email,
    ua.achievement_name,
    ua.description,
    (SELECT COUNT(*) FROM daily_challenges dc
     WHERE dc.user_id = au.id AND dc.status = 'completed') as total_completed,
    ua.id as achievement_id
FROM user_achievements ua
JOIN auth.users au ON ua.user_id = au.id
WHERE ua.achievement_type = 'challenges'
AND (
    (ua.achievement_name = 'Premier Pas' AND
        (SELECT COUNT(*) FROM daily_challenges dc WHERE dc.user_id = au.id AND dc.status = 'completed') < 1)
    OR (ua.achievement_name = 'Débutant Motivé' AND
        (SELECT COUNT(*) FROM daily_challenges dc WHERE dc.user_id = au.id AND dc.status = 'completed') < 5)
    OR (ua.achievement_name = 'Explorateur' AND
        (SELECT COUNT(*) FROM daily_challenges dc WHERE dc.user_id = au.id AND dc.status = 'completed') < 10)
    OR (ua.achievement_name = 'Aventurier' AND
        (SELECT COUNT(*) FROM daily_challenges dc WHERE dc.user_id = au.id AND dc.status = 'completed') < 25)
    OR (ua.achievement_name = 'Expert' AND
        (SELECT COUNT(*) FROM daily_challenges dc WHERE dc.user_id = au.id AND dc.status = 'completed') < 50)
    OR (ua.achievement_name = 'Maître des Défis' AND
        (SELECT COUNT(*) FROM daily_challenges dc WHERE dc.user_id = au.id AND dc.status = 'completed') < 100)
    OR (ua.achievement_name = 'Légende' AND
        (SELECT COUNT(*) FROM daily_challenges dc WHERE dc.user_id = au.id AND dc.status = 'completed') < 250)
);

-- PARTIE 3 : NETTOYAGE
-- ====================

-- 5. SUPPRIMER tous les badges de streak incorrects
DELETE FROM user_achievements ua
USING auth.users au, user_profiles up
WHERE ua.user_id = au.id
AND ua.user_id = up.id
AND ua.achievement_type = 'streak'
AND (
    (ua.achievement_name = 'Premier Élan' AND up.streak_count < 3)
    OR (ua.achievement_name = 'Semaine Parfaite' AND up.streak_count < 7)
    OR (ua.achievement_name = 'Deux Semaines de Force' AND up.streak_count < 14)
    OR (ua.achievement_name = 'Mois de Détermination' AND up.streak_count < 30)
    OR (ua.achievement_name = 'Deux Mois de Constance' AND up.streak_count < 60)
    OR (ua.achievement_name = 'Centurion' AND up.streak_count < 100)
    OR (ua.achievement_name = 'Année de Croissance' AND up.streak_count < 365)
);

-- 6. SUPPRIMER tous les badges de challenges incorrects
DELETE FROM user_achievements ua
USING auth.users au
WHERE ua.user_id = au.id
AND ua.achievement_type = 'challenges'
AND (
    (ua.achievement_name = 'Premier Pas' AND
        (SELECT COUNT(*) FROM daily_challenges dc WHERE dc.user_id = au.id AND dc.status = 'completed') < 1)
    OR (ua.achievement_name = 'Débutant Motivé' AND
        (SELECT COUNT(*) FROM daily_challenges dc WHERE dc.user_id = au.id AND dc.status = 'completed') < 5)
    OR (ua.achievement_name = 'Explorateur' AND
        (SELECT COUNT(*) FROM daily_challenges dc WHERE dc.user_id = au.id AND dc.status = 'completed') < 10)
    OR (ua.achievement_name = 'Aventurier' AND
        (SELECT COUNT(*) FROM daily_challenges dc WHERE dc.user_id = au.id AND dc.status = 'completed') < 25)
    OR (ua.achievement_name = 'Expert' AND
        (SELECT COUNT(*) FROM daily_challenges dc WHERE dc.user_id = au.id AND dc.status = 'completed') < 50)
    OR (ua.achievement_name = 'Maître des Défis' AND
        (SELECT COUNT(*) FROM daily_challenges dc WHERE dc.user_id = au.id AND dc.status = 'completed') < 100)
    OR (ua.achievement_name = 'Légende' AND
        (SELECT COUNT(*) FROM daily_challenges dc WHERE dc.user_id = au.id AND dc.status = 'completed') < 250)
);

-- 7. Vérifier que les badges incorrects ont été supprimés
SELECT
    au.email,
    ua.achievement_type,
    ua.achievement_name,
    up.streak_count,
    (SELECT COUNT(*) FROM daily_challenges dc
     WHERE dc.user_id = au.id AND dc.status = 'completed') as total_completed
FROM user_achievements ua
JOIN auth.users au ON ua.user_id = au.id
LEFT JOIN user_profiles up ON au.id = up.id
ORDER BY au.email, ua.unlocked_at DESC;
