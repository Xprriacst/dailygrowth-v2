-- Création rapide de la table notification_logs
-- Copier-coller dans Supabase SQL Editor

CREATE TABLE IF NOT EXISTS notification_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    trigger_type TEXT NOT NULL,
    notification_sent BOOLEAN NOT NULL DEFAULT false,
    skip_reason TEXT,
    error_message TEXT,
    notification_time TIME,
    timezone_offset_minutes INTEGER,
    target_utc_time TIME,
    actual_utc_time TIME,
    time_diff_minutes INTEGER,
    fcm_token_present BOOLEAN,
    fcm_response JSONB,
    challenge_id UUID,
    challenge_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour recherches rapides
CREATE INDEX IF NOT EXISTS idx_notification_logs_user_id ON notification_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_logs_created_at ON notification_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notification_logs_sent ON notification_logs(notification_sent);

-- Activer RLS
ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;

-- Policy pour les utilisateurs
DROP POLICY IF EXISTS "Users can view their own notification logs" ON notification_logs;
CREATE POLICY "Users can view their own notification logs"
    ON notification_logs
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy pour service role
DROP POLICY IF EXISTS "Service role has full access to notification logs" ON notification_logs;
CREATE POLICY "Service role has full access to notification logs"
    ON notification_logs
    FOR ALL
    USING (auth.jwt()->>'role' = 'service_role');

-- Vérification
SELECT 'Table notification_logs créée avec succès !' as status;
SELECT COUNT(*) as table_exists FROM information_schema.tables 
WHERE table_name = 'notification_logs';
