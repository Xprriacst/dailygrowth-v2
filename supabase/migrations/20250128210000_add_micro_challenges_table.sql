-- Migration pour ajouter la table des micro-défis générés lors de l'inscription
-- Ces défis seront utilisés comme source pour les défis quotidiens

-- Table pour stocker les micro-défis générés par le workflow n8n
CREATE TABLE public.user_micro_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    problematique TEXT NOT NULL, -- La problématique choisie lors de l'inscription
    numero INTEGER NOT NULL, -- Numéro du défi (1-15)
    nom TEXT NOT NULL, -- Nom du micro-défi
    mission TEXT NOT NULL, -- Description de la mission
    pourquoi TEXT, -- Explication du pourquoi
    bonus TEXT, -- Bonus optionnel
    duree_estimee TEXT DEFAULT '15', -- Durée estimée en minutes
    niveau_detecte TEXT, -- Niveau détecté par l'IA
    source TEXT DEFAULT 'n8n_workflow', -- Source de génération
    is_used_as_daily BOOLEAN DEFAULT false, -- Si ce défi a été utilisé comme défi quotidien
    used_as_daily_date DATE, -- Date à laquelle il a été utilisé comme défi quotidien
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Index pour optimiser les requêtes
CREATE INDEX idx_user_micro_challenges_user_id ON public.user_micro_challenges(user_id);
CREATE INDEX idx_user_micro_challenges_is_used ON public.user_micro_challenges(user_id, is_used_as_daily);
CREATE INDEX idx_user_micro_challenges_date ON public.user_micro_challenges(used_as_daily_date);

-- RLS (Row Level Security)
ALTER TABLE public.user_micro_challenges ENABLE ROW LEVEL SECURITY;

-- Politique pour que les utilisateurs ne voient que leurs propres micro-défis
CREATE POLICY "Users can view their own micro challenges" ON public.user_micro_challenges
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own micro challenges" ON public.user_micro_challenges
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own micro challenges" ON public.user_micro_challenges
    FOR UPDATE USING (auth.uid() = user_id);

-- Fonction pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour updated_at
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON public.user_micro_challenges
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();
