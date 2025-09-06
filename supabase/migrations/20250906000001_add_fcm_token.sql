-- Ajouter colonne FCM token pour notifications push
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;