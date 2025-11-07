-- Add problematique column to daily_challenges table
-- This allows each daily challenge to store which problematique it's related to

ALTER TABLE public.daily_challenges 
ADD COLUMN IF NOT EXISTS problematique TEXT;

-- Add index for filtering challenges by problematique
CREATE INDEX IF NOT EXISTS idx_daily_challenges_problematique ON public.daily_challenges(problematique);

-- Add comment
COMMENT ON COLUMN public.daily_challenges.problematique IS 'The user problematique this challenge is related to (e.g., "lâcher-prise", "maîtriser", etc.)';
