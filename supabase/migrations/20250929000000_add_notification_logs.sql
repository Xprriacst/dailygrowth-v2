-- Migration: Ajouter table de logs pour les notifications
-- Date: 2025-09-29
-- Description: Permet de tracer toutes les tentatives d'envoi de notifications

-- Créer la table notification_logs
CREATE TABLE IF NOT EXISTS notification_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    trigger_type TEXT NOT NULL, -- 'cron', 'manual-test', 'manual-invoke'
    notification_sent BOOLEAN NOT NULL DEFAULT false,
    skip_reason TEXT, -- Raison du skip si notification_sent = false
    error_message TEXT, -- Message d'erreur FCM si échec
    
    -- Détails de timing
    notification_time TIME, -- Heure configurée par l'utilisateur
    timezone_offset_minutes INTEGER, -- Offset timezone de l'utilisateur
    target_utc_time TIME, -- Heure cible calculée en UTC
    actual_utc_time TIME, -- Heure réelle d'exécution en UTC
    time_diff_minutes INTEGER, -- Différence en minutes
    
    -- Détails de la notification
    fcm_token_present BOOLEAN,
    fcm_response JSONB, -- Réponse complète de FCM
    challenge_id UUID, -- ID du challenge envoyé (si applicable)
    challenge_name TEXT, -- Nom du challenge envoyé (si applicable)
    
    -- Métadonnées
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Index pour recherches rapides
    INDEX idx_notification_logs_user_id (user_id),
    INDEX idx_notification_logs_created_at (created_at DESC),
    INDEX idx_notification_logs_sent (notification_sent),
    INDEX idx_notification_logs_trigger (trigger_type)
);

-- Ajouter RLS (Row Level Security)
ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Les utilisateurs peuvent voir leurs propres logs
CREATE POLICY "Users can view their own notification logs"
    ON notification_logs
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Service role peut tout faire
CREATE POLICY "Service role has full access to notification logs"
    ON notification_logs
    FOR ALL
    USING (auth.jwt()->>'role' = 'service_role');

-- Fonction helper pour nettoyer les vieux logs (optionnel)
CREATE OR REPLACE FUNCTION cleanup_old_notification_logs()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Supprimer les logs de plus de 30 jours
    DELETE FROM notification_logs
    WHERE created_at < NOW() - INTERVAL '30 days';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$$;

-- Commentaires pour documentation
COMMENT ON TABLE notification_logs IS 'Logs de toutes les tentatives d''envoi de notifications push';
COMMENT ON COLUMN notification_logs.trigger_type IS 'Type de déclenchement: cron, manual-test, manual-invoke';
COMMENT ON COLUMN notification_logs.skip_reason IS 'Raison du skip: already_sent_today, out_of_window, no_fcm_token, notifications_disabled';
COMMENT ON COLUMN notification_logs.time_diff_minutes IS 'Différence en minutes entre l''heure cible et l''heure réelle';

-- Vue helper pour analyser les performances
CREATE OR REPLACE VIEW notification_logs_summary AS
SELECT 
    DATE(created_at) as log_date,
    trigger_type,
    COUNT(*) as total_attempts,
    COUNT(*) FILTER (WHERE notification_sent = true) as successful_sends,
    COUNT(*) FILTER (WHERE notification_sent = false) as failed_sends,
    COUNT(*) FILTER (WHERE skip_reason = 'already_sent_today') as skipped_already_sent,
    COUNT(*) FILTER (WHERE skip_reason = 'out_of_window') as skipped_out_of_window,
    COUNT(*) FILTER (WHERE skip_reason = 'no_fcm_token') as skipped_no_token,
    AVG(time_diff_minutes) FILTER (WHERE notification_sent = true) as avg_time_diff_minutes,
    MAX(created_at) as last_execution
FROM notification_logs
GROUP BY DATE(created_at), trigger_type
ORDER BY log_date DESC, trigger_type;

COMMENT ON VIEW notification_logs_summary IS 'Vue résumée des performances du système de notifications par jour';
