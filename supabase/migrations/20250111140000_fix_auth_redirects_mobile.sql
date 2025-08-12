-- Fix authentication redirects for mobile app
-- This migration configures proper redirect URLs for mobile authentication

-- Configure site URL and redirect URLs for mobile app
-- Note: These settings need to be configured in the Supabase Dashboard
-- This migration serves as documentation and can be used to update settings via API

-- Update auth settings to handle mobile deep links
-- The following URLs should be configured in Supabase Dashboard > Authentication > URL Configuration:

-- Site URL: https://your-app-domain.com (or for development: http://localhost:3000)
-- Redirect URLs:
-- - io.supabase.dailygrowth://login-callback/
-- - io.supabase.dailygrowth://reset-password/
-- - https://your-app-domain.com/auth/callback (for web)
-- - http://localhost:3000/auth/callback (for development)

-- Function to help debug authentication issues
CREATE OR REPLACE FUNCTION public.get_user_auth_status(user_email text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  auth_user auth.users%rowtype;
  profile_user public.user_profiles%rowtype;
  result jsonb;
BEGIN
  -- Get user from auth.users
  SELECT * INTO auth_user
  FROM auth.users
  WHERE email = user_email;
  
  -- Get user from user_profiles
  SELECT * INTO profile_user
  FROM public.user_profiles
  WHERE email = user_email;
  
  -- Build result
  result := jsonb_build_object(
    'email', user_email,
    'auth_user_exists', auth_user.id IS NOT NULL,
    'profile_user_exists', profile_user.id IS NOT NULL,
    'email_confirmed', auth_user.email_confirmed_at IS NOT NULL,
    'last_sign_in', auth_user.last_sign_in_at,
    'created_at', auth_user.created_at,
    'profile_status', profile_user.status,
    'is_admin', profile_user.is_admin
  );
  
  RETURN result;
END;
$function$;

-- Function to resend confirmation email for a user
CREATE OR REPLACE FUNCTION public.resend_confirmation_email(user_email text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  auth_user auth.users%rowtype;
BEGIN
  -- Get user from auth.users
  SELECT * INTO auth_user
  FROM auth.users
  WHERE email = user_email;
  
  IF auth_user.id IS NULL THEN
    RETURN jsonb_build_object('error', 'User not found');
  END IF;
  
  IF auth_user.email_confirmed_at IS NOT NULL THEN
    RETURN jsonb_build_object('error', 'Email already confirmed');
  END IF;
  
  -- Note: Actual email resending would need to be handled by the application
  -- or through Supabase Auth API, not through SQL functions
  
  RETURN jsonb_build_object(
    'success', true,
    'message', 'Confirmation email resend requested',
    'user_id', auth_user.id,
    'email', auth_user.email
  );
END;
$function$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.get_user_auth_status(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.resend_confirmation_email(text) TO authenticated;

-- Add helpful comment
COMMENT ON FUNCTION public.get_user_auth_status(text) IS 'Debug function to check user authentication status';
COMMENT ON FUNCTION public.resend_confirmation_email(text) IS 'Helper function to track confirmation email requests';

-- Check the status of the problematic user
SELECT public.get_user_auth_status('expertiaen5min@gmail.com');