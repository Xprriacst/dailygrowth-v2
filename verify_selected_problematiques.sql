-- Vérifier les problématiques affichées dans "Domaines de vie" vs les défis réels

-- 1. Ce qui est dans le profil utilisateur (colonne selected_problematiques)
SELECT 
  '🏷️ PROFIL UTILISATEUR' as section,
  email,
  selected_problematiques,
  jsonb_array_length(selected_problematiques::jsonb) as nombre_problematiques_selectionnees
FROM user_profiles
WHERE email = 'expertiaen5min@gmail.com';

-- 2. Décomposer le tableau des problématiques sélectionnées
SELECT 
  '📋 PROBLÉMATIQUES DANS LE PROFIL' as section,
  jsonb_array_elements_text(selected_problematiques::jsonb) as problematique
FROM user_profiles
WHERE email = 'expertiaen5min@gmail.com';

-- 3. Problématiques qui ont des défis associés (réelles)
SELECT 
  '✅ PROBLÉMATIQUES AVEC DÉFIS' as section,
  problematique,
  COUNT(*) as nombre_defis
FROM user_micro_challenges
WHERE user_id = '38118795-21a9-4b3d-afe9-b23c63936c9a'
  AND is_used_as_daily = true
GROUP BY problematique
ORDER BY nombre_defis DESC;

-- 4. COMPARAISON : Problématiques dans le profil mais SANS défis
SELECT 
  '⚠️ DANS PROFIL MAIS SANS DÉFIS' as alerte,
  p.problematique as problematique_profil
FROM (
  SELECT jsonb_array_elements_text(selected_problematiques::jsonb) as problematique
  FROM user_profiles
  WHERE email = 'expertiaen5min@gmail.com'
) p
LEFT JOIN (
  SELECT DISTINCT problematique
  FROM user_micro_challenges
  WHERE user_id = '38118795-21a9-4b3d-afe9-b23c63936c9a'
    AND is_used_as_daily = true
) c ON p.problematique = c.problematique
WHERE c.problematique IS NULL;

-- 5. COMPARAISON : Défis existants mais problématique ABSENTE du profil
SELECT 
  '⚠️ DÉFIS EXISTANTS MAIS ABSENTS DU PROFIL' as alerte,
  c.problematique
FROM (
  SELECT DISTINCT problematique
  FROM user_micro_challenges
  WHERE user_id = '38118795-21a9-4b3d-afe9-b23c63936c9a'
    AND is_used_as_daily = true
) c
LEFT JOIN (
  SELECT jsonb_array_elements_text(selected_problematiques::jsonb) as problematique
  FROM user_profiles
  WHERE email = 'expertiaen5min@gmail.com'
) p ON c.problematique = p.problematique
WHERE p.problematique IS NULL;
