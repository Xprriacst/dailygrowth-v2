-- Add icon_name column to user_achievements table
-- This fixes the issue where badges were not displaying properly on the dashboard

ALTER TABLE public.user_achievements
ADD COLUMN IF NOT EXISTS icon_name TEXT;

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_user_achievements_icon_name ON public.user_achievements(icon_name);

-- Comment for documentation
COMMENT ON COLUMN public.user_achievements.icon_name IS 'Material icon name to display for this achievement';
