-- Script pour supprimer le défi d'aujourd'hui et forcer une régénération
-- Cela permettra de tester si le webhook n8n fonctionne

-- 1. Vérifier d'abord quel défi existe pour aujourd'hui
SELECT 
  id,
  user_id,
  title,
  date_assigned,
  status,
  created_at
FROM daily_challenges
WHERE date_assigned = CURRENT_DATE
ORDER BY created_at DESC;

-- 2. Supprimer le défi d'aujourd'hui (décommente la ligne suivante après vérification)
-- DELETE FROM daily_challenges WHERE date_assigned = CURRENT_DATE;

-- 3. Vérifier que c'est bien supprimé
-- SELECT COUNT(*) FROM daily_challenges WHERE date_assigned = CURRENT_DATE;
