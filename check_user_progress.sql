-- Vérification complète de la progression pour expertiaen5min@gmail.com
-- ID utilisateur : 38118795-21a9-4b3d-afe9-b23c63936c9a

-- 1. Informations de base de l'utilisateur
SELECT 
  id,
  email,
  full_name,
  selected_problematiques,
  created_at
FROM user_profiles
WHERE email = 'expertiaen5min@gmail.com';

-- 2. Tous les défis de l'utilisateur (complétés et en cours)
SELECT 
  id,
  problematique,
  numero,
  nom,
  is_used_as_daily,
  used_as_daily_date,
  created_at
FROM user_micro_challenges
WHERE user_id = '38118795-21a9-4b3d-afe9-b23c63936c9a'
ORDER BY problematique, numero;

-- 3. Comptage des défis par problématique (ce que verra l'utilisateur dans l'app)
SELECT 
  problematique,
  COUNT(*) as total_defis,
  SUM(CASE WHEN is_used_as_daily = true THEN 1 ELSE 0 END) as defis_completes
FROM user_micro_challenges
WHERE user_id = '38118795-21a9-4b3d-afe9-b23c63936c9a'
GROUP BY problematique
ORDER BY problematique;

-- 4. Calcul exact de la progression (identique à getProgressByProblematique)
WITH challenge_counts AS (
  SELECT 
    problematique,
    COUNT(*) as completed
  FROM user_micro_challenges
  WHERE user_id = '38118795-21a9-4b3d-afe9-b23c63936c9a'
    AND is_used_as_daily = true
  GROUP BY problematique
)
SELECT 
  problematique,
  completed as defis_completes,
  50 as total_max,
  ROUND((completed::numeric / 50 * 100)::numeric, 0)::integer as pourcentage,
  (50 - completed) as restants,
  CASE 
    WHEN completed >= 40 THEN '🟢 Vert (80%+)'
    WHEN completed >= 25 THEN '🔵 Bleu (50-79%)'
    WHEN completed >= 12 THEN '🟠 Orange (25-49%)'
    ELSE '🔴 Rouge (0-24%)'
  END as couleur_affichee
FROM challenge_counts
ORDER BY pourcentage DESC;

-- 5. Vérification de la cohérence des données
SELECT 
  'Total défis créés' as metric,
  COUNT(*) as value
FROM user_micro_challenges
WHERE user_id = '38118795-21a9-4b3d-afe9-b23c63936c9a'

UNION ALL

SELECT 
  'Défis marqués is_used_as_daily=true',
  COUNT(*)
FROM user_micro_challenges
WHERE user_id = '38118795-21a9-4b3d-afe9-b23c63936c9a'
  AND is_used_as_daily = true

UNION ALL

SELECT 
  'Défis avec date d''utilisation',
  COUNT(*)
FROM user_micro_challenges
WHERE user_id = '38118795-21a9-4b3d-afe9-b23c63936c9a'
  AND used_as_daily_date IS NOT NULL

UNION ALL

SELECT 
  'Problématiques distinctes',
  COUNT(DISTINCT problematique)
FROM user_micro_challenges
WHERE user_id = '38118795-21a9-4b3d-afe9-b23c63936c9a';
