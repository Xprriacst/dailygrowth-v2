-- Create missing RPC functions for streak and points management
-- These functions are called from the Dart code but were never created

-- =====================================================
-- 0. DROP EXISTING FUNCTIONS IF THEY EXIST
-- =====================================================
-- This prevents errors if functions already exist with different signatures

DROP FUNCTION IF EXISTS public.add_user_points(UUID, INTEGER);
DROP FUNCTION IF EXISTS public.update_user_streak(UUID);
DROP FUNCTION IF EXISTS public.get_user_longest_streak(UUID);

-- =====================================================
-- 1. ADD_USER_POINTS FUNCTION
-- =====================================================
-- Adds points to a user's total_points counter
-- Called from: lib/services/user_service.dart:173

CREATE FUNCTION public.add_user_points(
    user_uuid UUID,
    points INTEGER
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update user's total points
    UPDATE public.user_profiles
    SET
        total_points = COALESCE(total_points, 0) + points,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = user_uuid;

    -- Log the points addition for debugging
    RAISE NOTICE 'Added % points to user %', points, user_uuid;
END;
$$;

-- =====================================================
-- 2. UPDATE_USER_STREAK FUNCTION
-- =====================================================
-- Calculates and updates the user's current streak
-- Called from: lib/services/user_service.dart:145
--
-- Logic:
-- - Checks completed challenges going backwards from today
-- - A streak continues if there's a completed challenge on consecutive days
-- - Streak breaks if a day is missed

CREATE FUNCTION public.update_user_streak(
    user_uuid UUID
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_streak INTEGER := 0;
    check_date DATE;
    has_challenge BOOLEAN;
    today DATE := CURRENT_DATE;
BEGIN
    -- Check if user completed today's challenge
    SELECT EXISTS(
        SELECT 1
        FROM public.daily_challenges
        WHERE user_id = user_uuid
        AND date_assigned = today
        AND status = 'completed'
    ) INTO has_challenge;

    -- If no challenge completed today, streak is 0
    IF NOT has_challenge THEN
        current_streak := 0;
    ELSE
        -- Start counting from today
        current_streak := 1;
        check_date := today - INTERVAL '1 day';

        -- Count backwards to find consecutive days
        FOR i IN 1..365 LOOP
            SELECT EXISTS(
                SELECT 1
                FROM public.daily_challenges
                WHERE user_id = user_uuid
                AND date_assigned = check_date
                AND status = 'completed'
            ) INTO has_challenge;

            -- If we find a completed challenge, increment streak
            IF has_challenge THEN
                current_streak := current_streak + 1;
                check_date := check_date - INTERVAL '1 day';
            ELSE
                -- Streak is broken, stop counting
                EXIT;
            END IF;
        END LOOP;
    END IF;

    -- Update the user's streak_count
    UPDATE public.user_profiles
    SET
        streak_count = current_streak,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = user_uuid;

    -- Log the streak update
    RAISE NOTICE 'Updated streak for user % to %', user_uuid, current_streak;

    RETURN current_streak;
END;
$$;

-- =====================================================
-- 3. HELPER FUNCTION: GET_USER_LONGEST_STREAK
-- =====================================================
-- Returns the longest streak the user has ever achieved
-- Useful for statistics and achievements

CREATE FUNCTION public.get_user_longest_streak(
    user_uuid UUID
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    longest_streak INTEGER := 0;
    temp_streak INTEGER := 1;
    prev_date DATE;
    curr_date DATE;
    challenge_dates DATE[];
BEGIN
    -- Get all completed challenge dates, sorted
    SELECT ARRAY_AGG(date_assigned ORDER BY date_assigned)
    INTO challenge_dates
    FROM public.daily_challenges
    WHERE user_id = user_uuid
    AND status = 'completed'
    AND date_assigned IS NOT NULL;

    -- If no challenges, return 0
    IF challenge_dates IS NULL OR array_length(challenge_dates, 1) = 0 THEN
        RETURN 0;
    END IF;

    -- If only one challenge, return 1
    IF array_length(challenge_dates, 1) = 1 THEN
        RETURN 1;
    END IF;

    -- Calculate longest streak by checking consecutive dates
    prev_date := challenge_dates[1];

    FOR i IN 2..array_length(challenge_dates, 1) LOOP
        curr_date := challenge_dates[i];

        -- If dates are consecutive (1 day apart)
        IF curr_date = prev_date + INTERVAL '1 day' THEN
            temp_streak := temp_streak + 1;
            longest_streak := GREATEST(longest_streak, temp_streak);
        ELSE
            -- Streak broken, reset
            temp_streak := 1;
        END IF;

        prev_date := curr_date;
    END LOOP;

    -- Make sure we capture the final streak
    longest_streak := GREATEST(longest_streak, temp_streak);

    RETURN longest_streak;
END;
$$;

-- =====================================================
-- 4. ADD date_assigned COLUMN TO daily_challenges
-- =====================================================
-- The streak calculation needs to know which date each challenge was assigned
-- This column may already exist, so we use IF NOT EXISTS

ALTER TABLE public.daily_challenges
ADD COLUMN IF NOT EXISTS date_assigned DATE DEFAULT CURRENT_DATE;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_daily_challenges_date_assigned
ON public.daily_challenges(date_assigned);

CREATE INDEX IF NOT EXISTS idx_daily_challenges_user_date
ON public.daily_challenges(user_id, date_assigned);

-- =====================================================
-- 5. TRIGGER: Auto-update date_assigned on insert
-- =====================================================
-- Automatically set date_assigned when a new challenge is created

CREATE OR REPLACE FUNCTION public.set_challenge_date_assigned()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.date_assigned IS NULL THEN
        NEW.date_assigned := CURRENT_DATE;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_set_challenge_date_assigned ON public.daily_challenges;

CREATE TRIGGER trigger_set_challenge_date_assigned
    BEFORE INSERT ON public.daily_challenges
    FOR EACH ROW
    EXECUTE FUNCTION public.set_challenge_date_assigned();

-- =====================================================
-- 6. GRANT PERMISSIONS
-- =====================================================
-- Allow authenticated users to execute these functions

GRANT EXECUTE ON FUNCTION public.add_user_points TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_user_streak TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_longest_streak TO authenticated;

-- =====================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON FUNCTION public.add_user_points IS
'Adds points to a user''s total_points counter. Called when completing challenges or earning achievements.';

COMMENT ON FUNCTION public.update_user_streak IS
'Calculates and updates the user''s current streak by checking consecutive days of completed challenges. Returns the current streak count.';

COMMENT ON FUNCTION public.get_user_longest_streak IS
'Returns the longest streak the user has ever achieved across all their challenge history.';

COMMENT ON COLUMN public.daily_challenges.date_assigned IS
'The date this challenge was assigned to the user. Used for streak calculation.';
