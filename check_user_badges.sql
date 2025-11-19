-- Vérifier les badges de l'utilisateur expertiaen5min@gmail.com

-- 1. Récupérer l'ID de l'utilisateur
SELECT id, email, full_name, streak_count, created_at
FROM auth.users
LEFT JOIN user_profiles ON auth.users.id = user_profiles.id
WHERE email = 'expertiaen5min@gmail.com';

-- 2. Vérifier les achievements attribués
SELECT
    ua.achievement_type,
    ua.achievement_name,
    ua.description,
    ua.icon_name,
    ua.points_earned,
    ua.unlocked_at,
    ua.created_at
FROM user_achievements ua
JOIN auth.users au ON ua.user_id = au.id
WHERE au.email = 'expertiaen5min@gmail.com'
ORDER BY ua.unlocked_at DESC;

-- 3. Vérifier le streak réel
SELECT
    up.streak_count,
    up.last_challenge_date,
    up.created_at,
    CURRENT_DATE - up.created_at::date as days_since_signup
FROM user_profiles up
JOIN auth.users au ON up.id = au.id
WHERE au.email = 'expertiaen5min@gmail.com';

-- 4. Compter les défis complétés
SELECT
    COUNT(*) as total_completed,
    MIN(completed_at) as first_completion,
    MAX(completed_at) as last_completion,
    COUNT(DISTINCT DATE(completed_at)) as unique_days_completed
FROM daily_challenges dc
JOIN auth.users au ON dc.user_id = au.id
WHERE au.email = 'expertiaen5min@gmail.com'
AND dc.status = 'completed';

-- 5. Historique des défis par jour
SELECT
    DATE(completed_at) as completion_date,
    COUNT(*) as challenges_completed,
    STRING_AGG(title, ', ') as challenge_titles
FROM daily_challenges dc
JOIN auth.users au ON dc.user_id = au.id
WHERE au.email = 'expertiaen5min@gmail.com'
AND dc.status = 'completed'
GROUP BY DATE(completed_at)
ORDER BY DATE(completed_at) DESC;
