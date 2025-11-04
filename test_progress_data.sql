-- Script SQL pour tester le système de progression par problématique
-- À exécuter dans Supabase SQL Editor

-- 1. Vérifier les défis actuels de l'utilisateur
SELECT 
  user_id,
  problematique,
  COUNT(*) as total_challenges,
  SUM(CASE WHEN is_used_as_daily = true THEN 1 ELSE 0 END) as completed_challenges
FROM user_micro_challenges
WHERE user_id = '38118795-21a9-4b3d-afe9-b23c63936c9a' -- expertiaen5min@gmail.com
GROUP BY user_id, problematique;

-- 2. Voir le détail des défis par problématique
SELECT 
  problematique,
  numero,
  nom,
  is_used_as_daily,
  used_as_daily_date,
  created_at
FROM user_micro_challenges
WHERE user_id = '38118795-21a9-4b3d-afe9-b23c63936c9a'
ORDER BY problematique, numero;

-- 3. (OPTIONNEL) Ajouter des défis de test pour voir la progression
-- Décommenter et modifier si besoin de tester avec plus de données

-- INSERT INTO user_micro_challenges (
--   user_id,
--   problematique,
--   numero,
--   nom,
--   mission,
--   pourquoi,
--   duree_estimee,
--   niveau_detecte,
--   source,
--   is_used_as_daily,
--   used_as_daily_date
-- ) VALUES 
-- ('38118795-21a9-4b3d-afe9-b23c63936c9a', 'lacher-prise', 5, 'Défi test 5', 'Test mission', 'Test pourquoi', 10, 'débutant', 'fallback', true, CURRENT_DATE - 5),
-- ('38118795-21a9-4b3d-afe9-b23c63936c9a', 'lacher-prise', 6, 'Défi test 6', 'Test mission', 'Test pourquoi', 10, 'débutant', 'fallback', true, CURRENT_DATE - 4),
-- ('38118795-21a9-4b3d-afe9-b23c63936c9a', 'revenus', 3, 'Défi revenus 3', 'Test mission', 'Test pourquoi', 15, 'débutant', 'fallback', true, CURRENT_DATE - 3),
-- ('38118795-21a9-4b3d-afe9-b23c63936c9a', 'revenus', 4, 'Défi revenus 4', 'Test mission', 'Test pourquoi', 15, 'intermédiaire', 'fallback', true, CURRENT_DATE - 2);

-- 4. Simuler une progression à 80% pour une problématique (40/50 défis)
-- Pour tester l'affichage des couleurs selon le pourcentage
-- (Décommenter si vous voulez tester)

/*
DO $$
DECLARE
  i INT;
BEGIN
  FOR i IN 7..40 LOOP
    INSERT INTO user_micro_challenges (
      user_id,
      problematique,
      numero,
      nom,
      mission,
      pourquoi,
      duree_estimee,
      niveau_detecte,
      source,
      is_used_as_daily,
      used_as_daily_date
    ) VALUES (
      '38118795-21a9-4b3d-afe9-b23c63936c9a',
      'lacher-prise',
      i,
      'Défi automatique ' || i,
      'Mission test',
      'Test pourquoi',
      10,
      CASE 
        WHEN i < 10 THEN 'débutant'
        WHEN i < 30 THEN 'intermédiaire'
        ELSE 'avancé'
      END,
      'fallback',
      true,
      CURRENT_DATE - (40 - i)
    );
  END LOOP;
END $$;
*/

-- 5. Calculer les pourcentages actuels (ce que fait la méthode getProgressByProblematique)
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
  completed,
  50 as total,
  ROUND((completed::numeric / 50 * 100)::numeric, 0)::integer as percentage,
  (50 - completed) as remaining
FROM challenge_counts
ORDER BY percentage DESC;
