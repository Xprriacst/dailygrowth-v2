-- Create missing tables for DailyGrowth application
-- Based on code analysis of expected database schema

-- 1. USER_MICRO_CHALLENGES TABLE
-- Used by challenge_service.dart and n8n_challenge_service.dart
CREATE TABLE IF NOT EXISTS public.user_micro_challenges (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    problematique TEXT NOT NULL,
    numero INTEGER NOT NULL,
    nom TEXT NOT NULL,
    mission TEXT NOT NULL,
    pourquoi TEXT,
    bonus TEXT,
    duree_estimee TEXT,
    niveau_detecte TEXT,
    source TEXT DEFAULT 'n8n_workflow',
    is_used_as_daily BOOLEAN DEFAULT FALSE,
    used_as_daily_date DATE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2. USER_ACHIEVEMENTS TABLE
-- Used by user_service.dart and gamification_service.dart
CREATE TABLE IF NOT EXISTS public.user_achievements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    achievement_type TEXT NOT NULL,
    achievement_name TEXT NOT NULL,
    description TEXT,
    icon_name TEXT,
    points_earned INTEGER DEFAULT 0,
    unlocked_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. DAILY_CHALLENGES TABLE
-- Used by challenge_service.dart
CREATE TABLE IF NOT EXISTS public.daily_challenges (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    points INTEGER DEFAULT 10,
    difficulty TEXT DEFAULT 'easy',
    category TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. USER_CHALLENGES TABLE (alias/view for compatibility)
-- Used by send-daily-notifications Edge Function
-- This can be a view that points to daily_challenges for compatibility
CREATE OR REPLACE VIEW public.user_challenges AS 
SELECT 
    id,
    user_id,
    title,
    description,
    status,
    created_at,
    completed_at
FROM public.daily_challenges;

-- 5. ADD MISSING COLUMNS TO USER_PROFILES
-- Based on code analysis
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS total_points INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS streak_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS fcm_token TEXT,
ADD COLUMN IF NOT EXISTS selected_life_domains TEXT[] DEFAULT '{}';

-- INDEXES FOR PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_user_micro_challenges_user_id ON public.user_micro_challenges(user_id);
CREATE INDEX IF NOT EXISTS idx_user_micro_challenges_is_used_as_daily ON public.user_micro_challenges(is_used_as_daily);
CREATE INDEX IF NOT EXISTS idx_user_micro_challenges_used_as_daily_date ON public.user_micro_challenges(used_as_daily_date);

CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON public.user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_achievement_type ON public.user_achievements(achievement_type);
CREATE INDEX IF NOT EXISTS idx_user_achievements_unlocked_at ON public.user_achievements(unlocked_at);
CREATE INDEX IF NOT EXISTS idx_user_achievements_icon_name ON public.user_achievements(icon_name);

CREATE INDEX IF NOT EXISTS idx_daily_challenges_user_id ON public.daily_challenges(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_challenges_status ON public.daily_challenges(status);
CREATE INDEX IF NOT EXISTS idx_daily_challenges_created_at ON public.daily_challenges(created_at);

CREATE INDEX IF NOT EXISTS idx_user_profiles_fcm_token ON public.user_profiles(fcm_token);
CREATE INDEX IF NOT EXISTS idx_user_profiles_notifications_enabled ON public.user_profiles(notifications_enabled);

-- RLS POLICIES FOR SECURITY
ALTER TABLE public.user_micro_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_challenges ENABLE ROW LEVEL SECURITY;

-- Users can only see their own data
CREATE POLICY "Users can view own micro challenges" ON public.user_micro_challenges
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own achievements" ON public.user_achievements
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own daily challenges" ON public.daily_challenges
    FOR ALL USING (auth.uid() = user_id);

-- TRIGGERS FOR UPDATED_AT
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_user_micro_challenges_updated_at
    BEFORE UPDATE ON public.user_micro_challenges
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trigger_daily_challenges_updated_at
    BEFORE UPDATE ON public.daily_challenges
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- COMMENTS FOR DOCUMENTATION
COMMENT ON TABLE public.user_micro_challenges IS 'Micro-challenges generated for users via n8n workflow';
COMMENT ON TABLE public.user_achievements IS 'User achievements and gamification data';
COMMENT ON TABLE public.daily_challenges IS 'Daily challenges assigned to users';
COMMENT ON VIEW public.user_challenges IS 'Compatibility view for legacy code pointing to daily_challenges';
