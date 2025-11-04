-- ========================================
-- DIAGNOSTIC COMPTEUR PROBLÉMATIQUES
-- Utilisateur: contact.polaris.ia@gmail.com
-- ========================================

-- 1. Trouver l'ID de l'utilisateur
SELECT 
    id,
    email,
    selected_problematiques,
    selected_life_domains,
    total_points,
    streak_count
FROM user_profiles
WHERE email = 'contact.polaris.ia@gmail.com';

-- 2. Vérifier tous les micro-défis créés pour cet utilisateur
SELECT 
    id,
    problematique,
    numero,
    nom,
    is_used_as_daily,
    used_as_daily_date,
    source,
    created_at
FROM user_micro_challenges
WHERE user_id = (SELECT id FROM user_profiles WHERE email = 'contact.polaris.ia@gmail.com')
ORDER BY created_at DESC;

-- 3. Compter les micro-défis par statut is_used_as_daily
SELECT 
    is_used_as_daily,
    COUNT(*) as count
FROM user_micro_challenges
WHERE user_id = (SELECT id FROM user_profiles WHERE email = 'contact.polaris.ia@gmail.com')
GROUP BY is_used_as_daily;

-- 4. Compter les micro-défis par problématique (ceux marqués is_used_as_daily = true)
-- C'est exactement ce que fait getProgressByProblematique()
SELECT 
    problematique,
    COUNT(*) as completed,
    ROUND((COUNT(*) * 100.0 / 50), 0) as percentage
FROM user_micro_challenges
WHERE user_id = (SELECT id FROM user_profiles WHERE email = 'contact.polaris.ia@gmail.com')
  AND is_used_as_daily = true
GROUP BY problematique;

-- 5. Vérifier les défis quotidiens (daily_challenges)
SELECT 
    id,
    title,
    status,
    date_assigned,
    completed_at,
    life_domain,
    points_reward
FROM daily_challenges
WHERE user_id = (SELECT id FROM user_profiles WHERE email = 'contact.polaris.ia@gmail.com')
ORDER BY date_assigned DESC;

-- 6. Compter les défis par statut
SELECT 
    status,
    COUNT(*) as count
FROM daily_challenges
WHERE user_id = (SELECT id FROM user_profiles WHERE email = 'contact.polaris.ia@gmail.com')
GROUP BY status;

-- 7. Vérifier si les micro-défis générés sont bien liés aux daily_challenges
-- (diagnostic pour voir si le lien entre les deux tables fonctionne)
SELECT 
    dc.id as daily_challenge_id,
    dc.title as daily_title,
    dc.status as daily_status,
    dc.date_assigned,
    umc.id as micro_challenge_id,
    umc.nom as micro_nom,
    umc.is_used_as_daily,
    umc.used_as_daily_date
FROM daily_challenges dc
LEFT JOIN user_micro_challenges umc 
    ON umc.nom = dc.title 
    AND umc.user_id = dc.user_id
WHERE dc.user_id = (SELECT id FROM user_profiles WHERE email = 'contact.polaris.ia@gmail.com')
ORDER BY dc.date_assigned DESC;

-- 8. Vérifier les défis du jour actuel
SELECT 
    dc.id,
    dc.title,
    dc.status,
    dc.date_assigned,
    umc.is_used_as_daily,
    umc.problematique
FROM daily_challenges dc
LEFT JOIN user_micro_challenges umc 
    ON umc.nom = dc.title 
    AND umc.user_id = dc.user_id
WHERE dc.user_id = (SELECT id FROM user_profiles WHERE email = 'contact.polaris.ia@gmail.com')
  AND dc.date_assigned = CURRENT_DATE
ORDER BY dc.created_at DESC;
