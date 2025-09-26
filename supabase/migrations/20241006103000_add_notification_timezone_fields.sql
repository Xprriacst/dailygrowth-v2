-- Add timezone offset and last notification timestamp for precise scheduling
ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS notification_timezone_offset_minutes INTEGER;

ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS last_notification_sent_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_user_profiles_last_notification_sent_at
ON public.user_profiles (last_notification_sent_at);
