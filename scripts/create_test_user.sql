-- Script pour créer un utilisateur de test dans Supabase
-- À exécuter dans l'éditeur SQL de Supabase Dashboard

-- 1. Créer un utilisateur de test dans auth.users
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
    '{"full_name": "Utilisateur Test", "selected_life_domains": ["sante", "developpement"]}'::jsonb,
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    false,
    false
);

-- 2. Le profil utilisateur sera créé automatiquement par le trigger
-- Vérifier que le profil a été créé
SELECT * FROM public.user_profiles WHERE email = 'test@dailygrowth.fr';
