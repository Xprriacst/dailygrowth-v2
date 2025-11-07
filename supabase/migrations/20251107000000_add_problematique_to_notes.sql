-- Add problematique column to notes table
-- This allows each note to store which problematique it's related to

ALTER TABLE public.notes 
ADD COLUMN IF NOT EXISTS problematique TEXT;

-- Add index for filtering notes by problematique
CREATE INDEX IF NOT EXISTS idx_notes_problematique ON public.notes(problematique);

-- Add comment
COMMENT ON COLUMN public.notes.problematique IS 'The user problematique this note is related to (e.g., "lâcher-prise", "maîtriser", etc.)';
