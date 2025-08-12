-- Location: supabase/migrations/20250801160000_add_admin_content_validation.sql
-- Schema Analysis: Existing DailyGrowth schema with user_profiles, daily_challenges, daily_quotes
-- Integration Type: Addition - Adding admin content validation functionality
-- Dependencies: user_profiles, daily_challenges, daily_quotes

-- 1. Create enum for content validation status
CREATE TYPE public.validation_status AS ENUM ('pending', 'approved', 'rejected');

-- 2. Create admin content validation table
CREATE TABLE public.admin_content_validations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_type TEXT NOT NULL CHECK (content_type IN ('challenge', 'quote')),
    content_id UUID NOT NULL,
    admin_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    status public.validation_status DEFAULT 'pending'::public.validation_status,
    feedback TEXT,
    validated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Add validation status columns to existing tables
ALTER TABLE public.daily_challenges
ADD COLUMN validation_status public.validation_status DEFAULT 'pending'::public.validation_status,
ADD COLUMN admin_feedback TEXT,
ADD COLUMN validated_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
ADD COLUMN validated_at TIMESTAMPTZ;

ALTER TABLE public.daily_quotes
ADD COLUMN validation_status public.validation_status DEFAULT 'pending'::public.validation_status,
ADD COLUMN admin_feedback TEXT,
ADD COLUMN validated_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
ADD COLUMN validated_at TIMESTAMPTZ;

-- 4. Add admin role field to user_profiles
ALTER TABLE public.user_profiles
ADD COLUMN is_admin BOOLEAN DEFAULT false;

-- 5. Create indexes for performance
CREATE INDEX idx_admin_content_validations_content_type ON public.admin_content_validations(content_type);
CREATE INDEX idx_admin_content_validations_status ON public.admin_content_validations(status);
CREATE INDEX idx_admin_content_validations_admin_id ON public.admin_content_validations(admin_id);
CREATE INDEX idx_daily_challenges_validation_status ON public.daily_challenges(validation_status);
CREATE INDEX idx_daily_quotes_validation_status ON public.daily_quotes(validation_status);
CREATE INDEX idx_user_profiles_is_admin ON public.user_profiles(is_admin);

-- 6. Helper function for admin role checking
CREATE OR REPLACE FUNCTION public.is_admin_user()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = auth.uid() AND up.is_admin = true
)
$$;

-- 7. Enable RLS on new table
ALTER TABLE public.admin_content_validations ENABLE ROW LEVEL SECURITY;

-- 8. RLS Policies using safe patterns

-- Pattern 2: Simple user ownership for validations
CREATE POLICY "users_manage_own_admin_content_validations"
ON public.admin_content_validations
FOR ALL
TO authenticated
USING (admin_id = auth.uid())
WITH CHECK (admin_id = auth.uid());

-- Admin access to all validations (for non-user table)
CREATE POLICY "admin_full_access_admin_content_validations"
ON public.admin_content_validations
FOR ALL
TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

-- 9. Function to validate content
CREATE OR REPLACE FUNCTION public.validate_content(
    p_content_type TEXT,
    p_content_id UUID,
    p_status TEXT,
    p_feedback TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_admin_id UUID;
BEGIN
    -- Check if user is admin
    SELECT id INTO v_admin_id 
    FROM public.user_profiles 
    WHERE id = auth.uid() AND is_admin = true;
    
    IF v_admin_id IS NULL THEN
        RETURN false;
    END IF;
    
    -- Update the content based on type
    IF p_content_type = 'challenge' THEN
        UPDATE public.daily_challenges 
        SET validation_status = p_status::public.validation_status,
            admin_feedback = p_feedback,
            validated_by = v_admin_id,
            validated_at = CURRENT_TIMESTAMP
        WHERE id = p_content_id;
    ELSIF p_content_type = 'quote' THEN
        UPDATE public.daily_quotes 
        SET validation_status = p_status::public.validation_status,
            admin_feedback = p_feedback,
            validated_by = v_admin_id,
            validated_at = CURRENT_TIMESTAMP
        WHERE id = p_content_id;
    END IF;
    
    -- Insert validation record
    INSERT INTO public.admin_content_validations (
        content_type,
        content_id,
        admin_id,
        status,
        feedback,
        validated_at
    ) VALUES (
        p_content_type,
        p_content_id,
        v_admin_id,
        p_status::public.validation_status,
        p_feedback,
        CURRENT_TIMESTAMP
    );
    
    RETURN true;
END;
$$;

-- 10. Mock data for testing (create an admin user)
DO $$
DECLARE
    existing_user_id UUID;
    admin_user_id UUID := gen_random_uuid();
    sample_challenge_id UUID;
    sample_quote_id UUID;
BEGIN
    -- Get existing user or create admin
    SELECT id INTO existing_user_id FROM public.user_profiles LIMIT 1;
    
    IF existing_user_id IS NOT NULL THEN
        -- Make existing user an admin
        UPDATE public.user_profiles 
        SET is_admin = true 
        WHERE id = existing_user_id;
        admin_user_id := existing_user_id;
    ELSE
        -- Create complete admin user if no users exist
        INSERT INTO auth.users (
            id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
            created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
            is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
            recovery_token, recovery_sent_at, email_change_token_new, email_change,
            email_change_sent_at, email_change_token_current, email_change_confirm_status,
            reauthentication_token, reauthentication_sent_at, phone, phone_change,
            phone_change_token, phone_change_sent_at
        ) VALUES (
            admin_user_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
            'admin@dailygrowth.com', crypt('admin123', gen_salt('bf', 10)), now(), now(), now(),
            '{"full_name": "Admin User"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
            false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
        );
        
        -- Create user profile for admin
        INSERT INTO public.user_profiles (
            id, email, full_name, is_admin, selected_life_domains
        ) VALUES (
            admin_user_id, 'admin@dailygrowth.com', 'Admin User', true, '{"sante", "developpement"}'::life_domain[]
        );
    END IF;
    
    -- Create sample challenges and quotes that need validation
    INSERT INTO public.daily_challenges (user_id, title, description, life_domain, validation_status)
    VALUES 
        (admin_user_id, 'Test Challenge', 'This is a test challenge for validation', 'sante'::life_domain, 'pending'::public.validation_status)
    RETURNING id INTO sample_challenge_id;
    
    INSERT INTO public.daily_quotes (user_id, quote_text, author, life_domain, validation_status)
    VALUES 
        (admin_user_id, 'Test quote for validation purposes', 'Test Author', 'developpement'::life_domain, 'pending'::public.validation_status)
    RETURNING id INTO sample_quote_id;
    
    -- Create sample validation records
    INSERT INTO public.admin_content_validations (content_type, content_id, admin_id, status)
    VALUES 
        ('challenge', sample_challenge_id, admin_user_id, 'pending'::public.validation_status),
        ('quote', sample_quote_id, admin_user_id, 'pending'::public.validation_status);

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Migration completed with notice: %', SQLERRM;
END $$;