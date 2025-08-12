# Créer un utilisateur de test pour DailyGrowth

## 🎯 Objectif
Créer un utilisateur de test pour pouvoir tester l'authentification dans l'application DailyGrowth.

## 📋 Méthode 1: Via Supabase Dashboard (Recommandée)

### Étapes :

1. **Aller sur Supabase Dashboard**
   - URL : https://supabase.com/dashboard
   - Se connecter avec votre compte

2. **Sélectionner votre projet**
   - Projet : `hekdcsulxrukfturuone` (visible dans l'URL de votre env.json)

3. **Aller dans Authentication > Users**
   - Menu latéral : Authentication
   - Onglet : Users

4. **Créer un nouvel utilisateur**
   - Cliquer sur "Add user"
   - **Email :** `test@dailygrowth.fr`
   - **Mot de passe :** `test123`
   - **Confirm email :** ✅ (cocher cette case)
   - Cliquer sur "Create user"

5. **Vérifier la création**
   - L'utilisateur devrait apparaître dans la liste
   - Status : "Confirmed"

## 📋 Méthode 2: Via SQL Editor

Si vous préférez utiliser SQL :

1. **Aller dans SQL Editor**
   - Menu latéral : SQL Editor

2. **Exécuter le script**
   ```sql
   -- Créer un utilisateur de test
   INSERT INTO auth.users (
       id,
       instance_id,
       aud,
       role,
       email,
       encrypted_password,
       email_confirmed_at,
       created_at,
       updated_at,
       raw_user_meta_data,
       raw_app_meta_data,
       is_sso_user,
       is_anonymous
   ) VALUES (
       gen_random_uuid(),
       '00000000-0000-0000-0000-000000000000',
       'authenticated',
       'authenticated',
       'test@dailygrowth.fr',
       crypt('test123', gen_salt('bf')),
       now(),
       now(),
       now(),
       '{"full_name": "Utilisateur Test"}'::jsonb,
       '{"provider": "email", "providers": ["email"]}'::jsonb,
       false,
       false
   );
   ```

## 🔐 Identifiants de test

Une fois créé, utilisez ces identifiants dans l'application :

- **Email :** `test@dailygrowth.fr`
- **Mot de passe :** `test123`

## ✅ Test de connexion

1. Retourner sur l'application : http://localhost:8080
2. Essayer de se connecter avec les identifiants ci-dessus
3. La connexion devrait maintenant fonctionner !

## 🛠️ En cas de problème

Si la connexion ne fonctionne toujours pas :

1. **Vérifier dans Supabase Dashboard > Authentication > Users**
   - L'utilisateur est-il présent ?
   - Son status est-il "Confirmed" ?

2. **Vérifier dans Database > public > user_profiles**
   - Un profil a-t-il été créé automatiquement ?

3. **Vérifier les logs de l'application**
   - Ouvrir les DevTools du navigateur (F12)
   - Onglet Console
   - Chercher les messages d'erreur

## 🔄 Alternative rapide

Si vous voulez tester rapidement, vous pouvez aussi :

1. **Créer un compte via l'interface de l'app**
   - Aller sur "S'inscrire" dans l'application
   - Utiliser un email temporaire
   - Confirmer l'email si nécessaire

2. **Utiliser un compte existant**
   - Les logs montrent que `expertiaen5min@gmail.com` fonctionne
   - Vous pouvez utiliser ce compte pour tester
