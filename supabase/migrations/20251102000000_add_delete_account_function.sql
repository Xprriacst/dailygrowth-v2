-- Fonction RPC pour supprimer un compte utilisateur
-- Cette fonction supprime toutes les données de l'utilisateur de manière sécurisée

-- Créer la fonction de suppression de compte
CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id uuid;
  deleted_count int := 0;
BEGIN
  -- Récupérer l'ID de l'utilisateur authentifié
  current_user_id := auth.uid();
  
  -- Vérifier que l'utilisateur est authentifié
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Non autorisé: utilisateur non authentifié';
  END IF;

  -- Supprimer les données dans l'ordre pour respecter les contraintes de clés étrangères
  
  -- 1. Supprimer les achievements
  DELETE FROM user_achievements WHERE user_id = current_user_id;
  
  -- 2. Supprimer les daily challenges
  DELETE FROM daily_challenges WHERE user_id = current_user_id;
  
  -- 3. Supprimer les micro challenges
  DELETE FROM user_micro_challenges WHERE user_id = current_user_id;
  
  -- 4. Supprimer les logs de notifications
  DELETE FROM notification_logs WHERE user_id = current_user_id;
  
  -- 5. Supprimer le profil utilisateur
  DELETE FROM user_profiles WHERE id = current_user_id;
  
  -- 6. Supprimer l'utilisateur de auth.users (ceci supprimera aussi la session)
  DELETE FROM auth.users WHERE id = current_user_id;
  
  -- Retourner un message de succès
  RETURN json_build_object(
    'success', true,
    'message', 'Compte supprimé avec succès',
    'user_id', current_user_id
  );
  
EXCEPTION
  WHEN OTHERS THEN
    -- En cas d'erreur, retourner les détails
    RETURN json_build_object(
      'success', false,
      'message', 'Erreur lors de la suppression du compte',
      'error', SQLERRM
    );
END;
$$;

-- Accorder les permissions d'exécution aux utilisateurs authentifiés
GRANT EXECUTE ON FUNCTION delete_user_account() TO authenticated;

-- Ajouter un commentaire pour documentation
COMMENT ON FUNCTION delete_user_account() IS 'Supprime le compte utilisateur et toutes ses données associées. Peut uniquement être appelé par l''utilisateur lui-même.';
