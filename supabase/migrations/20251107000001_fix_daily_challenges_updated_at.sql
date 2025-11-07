-- Fix daily_challenges table: ensure updated_at column and trigger exist
-- This fixes the error: record "new" has no field "updated_at"

-- Add updated_at column if it doesn't exist
ALTER TABLE public.daily_challenges 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

-- Create or replace the trigger function for updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_daily_challenges_updated_at ON public.daily_challenges;

-- Create trigger for daily_challenges
CREATE TRIGGER trigger_daily_challenges_updated_at
    BEFORE UPDATE ON public.daily_challenges
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Add comment
COMMENT ON COLUMN public.daily_challenges.updated_at IS 'Timestamp when the challenge was last updated';
