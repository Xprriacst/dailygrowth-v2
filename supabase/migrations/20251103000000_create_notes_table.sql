-- Create notes table for user notes functionality
CREATE TABLE IF NOT EXISTS notes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  challenge_id TEXT,
  content TEXT NOT NULL,
  challenge_title TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_challenge_id ON notes(challenge_id);
CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes(created_at DESC);

-- Enable Row Level Security
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own notes
CREATE POLICY "Users can view their own notes"
  ON notes
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can only insert their own notes
CREATE POLICY "Users can insert their own notes"
  ON notes
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can only update their own notes
CREATE POLICY "Users can update their own notes"
  ON notes
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Users can only delete their own notes
CREATE POLICY "Users can delete their own notes"
  ON notes
  FOR DELETE
  USING (auth.uid() = user_id);

-- Comment on table
COMMENT ON TABLE notes IS 'Stores user notes associated with challenges or standalone';
COMMENT ON COLUMN notes.id IS 'Unique identifier for the note';
COMMENT ON COLUMN notes.user_id IS 'ID of the user who created the note';
COMMENT ON COLUMN notes.challenge_id IS 'Optional ID of the challenge this note is associated with';
COMMENT ON COLUMN notes.content IS 'The actual note content';
COMMENT ON COLUMN notes.challenge_title IS 'Optional title of the challenge for display purposes';
COMMENT ON COLUMN notes.created_at IS 'Timestamp when the note was created';
COMMENT ON COLUMN notes.updated_at IS 'Timestamp when the note was last updated';
