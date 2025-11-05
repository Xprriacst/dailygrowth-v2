-- VÉRIFICATION RAPIDE : Progression expertiaen5min@gmail.com

-- Ce que verra l'utilisateur dans son profil :
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
  '📊 PROGRESSION PAR PROBLÉMATIQUE' as section,
  problematique,
  completed || '/50 défis' as progression,
  ROUND((completed::numeric / 50 * 100)::numeric, 0)::integer || '%' as pourcentage,
  CASE 
    WHEN completed >= 40 THEN '🟢 Vert'
    WHEN completed >= 25 THEN '🔵 Bleu'
    WHEN completed >= 12 THEN '🟠 Orange'
    ELSE '🔴 Rouge'
  END as couleur
FROM challenge_counts
ORDER BY completed DESC;
