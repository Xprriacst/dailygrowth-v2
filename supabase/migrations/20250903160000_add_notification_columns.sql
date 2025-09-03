-- Add notification columns to existing user_profiles table
-- This migration adds support for reminder notifications and selected problematiques

-- Add reminder_notifications_enabled column
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS reminder_notifications_enabled BOOLEAN DEFAULT false;

-- Add selected_problematiques column
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS selected_problematiques TEXT[] DEFAULT '{}';

-- Add index for performance on selected_problematiques
CREATE INDEX IF NOT EXISTS idx_user_profiles_selected_problematiques 
ON public.user_profiles USING GIN (selected_problematiques);

-- Add comment for documentation
COMMENT ON COLUMN public.user_profiles.reminder_notifications_enabled IS 'Whether user wants 6-hour reminder notifications';
COMMENT ON COLUMN public.user_profiles.selected_problematiques IS 'User-selected specific problems/goals for personalized challenge generation';
