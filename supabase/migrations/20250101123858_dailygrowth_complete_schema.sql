-- Location: supabase/migrations/20250101123858_dailygrowth_complete_schema.sql
-- DailyGrowth - Complete Personal Development App Schema
-- French personal development app with daily challenges, quotes, and progress tracking

-- 1. Custom Types
CREATE TYPE public.user_status AS ENUM ('active', 'inactive', 'suspended');
CREATE TYPE public.challenge_status AS ENUM ('pending', 'completed', 'skipped');
CREATE TYPE public.life_domain AS ENUM ('sante', 'relations', 'carriere', 'finances', 'developpement', 'spiritualite', 'loisirs', 'famille');

-- 2. Core Tables

-- User profiles (intermediary for auth relationships)
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    status public.user_status DEFAULT 'active'::public.user_status,
    notification_time TIME DEFAULT '09:00:00',
    notifications_enabled BOOLEAN DEFAULT true,
    selected_life_domains public.life_domain[] DEFAULT '{}',
    streak_count INTEGER DEFAULT 0,
    total_points INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Daily challenges
CREATE TABLE public.daily_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    life_domain public.life_domain NOT NULL,
    status public.challenge_status DEFAULT 'pending'::public.challenge_status,
    points_reward INTEGER DEFAULT 10,
    date_assigned DATE DEFAULT CURRENT_DATE,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Inspirational quotes
CREATE TABLE public.daily_quotes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    quote_text TEXT NOT NULL,
    author TEXT NOT NULL,
    life_domain public.life_domain NOT NULL,
    date_assigned DATE DEFAULT CURRENT_DATE,
    is_favorite BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- User achievements
CREATE TABLE public.user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    achievement_type TEXT NOT NULL,
    achievement_name TEXT NOT NULL,
    description TEXT NOT NULL,
    icon_name TEXT NOT NULL,
    points_earned INTEGER DEFAULT 0,
    unlocked_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Challenge history
CREATE TABLE public.challenge_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    challenge_id UUID REFERENCES public.daily_challenges(id) ON DELETE CASCADE,
    completed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    points_earned INTEGER DEFAULT 10,
    notes TEXT
);

-- 3. Essential Indexes
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_daily_challenges_user_date ON public.daily_challenges(user_id, date_assigned);
CREATE INDEX idx_daily_challenges_status ON public.daily_challenges(status);
CREATE INDEX idx_daily_quotes_user_date ON public.daily_quotes(user_id, date_assigned);
CREATE INDEX idx_user_achievements_user_id ON public.user_achievements(user_id);
CREATE INDEX idx_challenge_history_user_id ON public.challenge_history(user_id);

-- 4. Row Level Security Setup
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenge_history ENABLE ROW LEVEL SECURITY;

-- 5. Helper Functions for RLS
CREATE OR REPLACE FUNCTION public.is_profile_owner(profile_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = profile_id AND up.id = auth.uid()
)
$$;

CREATE OR REPLACE FUNCTION public.owns_challenge(challenge_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.daily_challenges dc
    WHERE dc.id = challenge_id AND dc.user_id = auth.uid()
)
$$;

CREATE OR REPLACE FUNCTION public.owns_quote(quote_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.daily_quotes dq
    WHERE dq.id = quote_id AND dq.user_id = auth.uid()
)
$$;

-- 6. RLS Policies
CREATE POLICY "users_manage_own_profile"
ON public.user_profiles
FOR ALL
TO authenticated
USING (public.is_profile_owner(id))
WITH CHECK (public.is_profile_owner(id));

CREATE POLICY "users_manage_own_challenges"
ON public.daily_challenges
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_quotes"
ON public.daily_quotes
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_view_own_achievements"
ON public.user_achievements
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_view_own_history"
ON public.challenge_history
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 7. Automatic profile creation trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.user_profiles (
    id, 
    email, 
    full_name, 
    selected_life_domains
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(
      (NEW.raw_user_meta_data->>'selected_life_domains')::public.life_domain[],
      ARRAY['sante', 'developpement']::public.life_domain[]
    )
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 8. Utility functions for streak and points updates
CREATE OR REPLACE FUNCTION public.update_user_streak(user_uuid UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.user_profiles
  SET streak_count = streak_count + 1,
      updated_at = CURRENT_TIMESTAMP
  WHERE id = user_uuid;
END;
$$;

CREATE OR REPLACE FUNCTION public.add_user_points(user_uuid UUID, points INTEGER)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.user_profiles
  SET total_points = total_points + points,
      updated_at = CURRENT_TIMESTAMP
  WHERE id = user_uuid;
END;
$$;

-- 9. Mock Data for Development
DO $$
DECLARE
    demo_user_id UUID := gen_random_uuid();
    admin_user_id UUID := gen_random_uuid();
    challenge1_id UUID := gen_random_uuid();
    challenge2_id UUID := gen_random_uuid();
    quote1_id UUID := gen_random_uuid();
BEGIN
    -- Create auth users with complete field structure
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (demo_user_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'demo@dailygrowth.fr', crypt('demo123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Utilisateur Demo", "selected_life_domains": ["sante", "developpement"]}'::jsonb, 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (admin_user_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'admin@dailygrowth.fr', crypt('admin123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Admin User", "selected_life_domains": ["carriere", "finances", "developpement"]}'::jsonb, 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Sample daily challenges
    INSERT INTO public.daily_challenges (id, user_id, title, description, life_domain, status, date_assigned)
    VALUES
        (challenge1_id, demo_user_id, 
         'Marche de 15 minutes', 
         'Prenez 15 minutes aujourd''hui pour une marche relaxante à l''extérieur', 
         'sante'::public.life_domain, 
         'pending'::public.challenge_status, 
         CURRENT_DATE),
        (challenge2_id, demo_user_id,
         'Méditation de 5 minutes',
         'Accordez-vous 5 minutes de méditation pour commencer la journée en pleine conscience',
         'developpement'::public.life_domain,
         'completed'::public.challenge_status,
         CURRENT_DATE - INTERVAL '1 day');

    -- Sample daily quotes
    INSERT INTO public.daily_quotes (id, user_id, quote_text, author, life_domain, date_assigned, is_favorite)
    VALUES
        (quote1_id, demo_user_id,
         'La seule façon de faire du bon travail est d''aimer ce que vous faites.',
         'Steve Jobs',
         'carriere'::public.life_domain,
         CURRENT_DATE,
         true),
        (gen_random_uuid(), demo_user_id,
         'Le succès n''est pas final, l''échec n''est pas fatal : c''est le courage de continuer qui compte.',
         'Winston Churchill',
         'developpement'::public.life_domain,
         CURRENT_DATE - INTERVAL '1 day',
         false);

    -- Sample achievements
    INSERT INTO public.user_achievements (user_id, achievement_type, achievement_name, description, icon_name, points_earned)
    VALUES
        (demo_user_id, 'streak', 'Premier Pas', 'Complétez votre premier défi', 'star', 50),
        (demo_user_id, 'challenge', 'Débutant Motivé', 'Complétez 5 défis au total', 'trophy', 100);

    -- Sample challenge history
    INSERT INTO public.challenge_history (user_id, challenge_id, points_earned, notes)
    VALUES
        (demo_user_id, challenge2_id, 10, 'Excellente session de méditation ce matin');

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
END $$;

-- 10. Cleanup function for development
CREATE OR REPLACE FUNCTION public.cleanup_demo_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    demo_user_ids UUID[];
BEGIN
    -- Get demo user IDs
    SELECT ARRAY_AGG(id) INTO demo_user_ids
    FROM auth.users
    WHERE email LIKE '%@dailygrowth.fr';

    -- Delete in dependency order
    DELETE FROM public.challenge_history WHERE user_id = ANY(demo_user_ids);
    DELETE FROM public.user_achievements WHERE user_id = ANY(demo_user_ids);
    DELETE FROM public.daily_quotes WHERE user_id = ANY(demo_user_ids);
    DELETE FROM public.daily_challenges WHERE user_id = ANY(demo_user_ids);
    DELETE FROM public.user_profiles WHERE id = ANY(demo_user_ids);
    DELETE FROM auth.users WHERE id = ANY(demo_user_ids);

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint prevents deletion: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Cleanup failed: %', SQLERRM;
END;
$$;