-- Fix user registration trigger to ensure proper user profile creation
-- This migration ensures that user profiles are properly created when users sign up

-- Update the handle_new_user function to be more robust
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
  -- Ensure we have the required data
  IF NEW.id IS NULL THEN
    RAISE EXCEPTION 'User ID cannot be null';
  END IF;
  
  IF NEW.email IS NULL OR NEW.email = '' THEN
    RAISE EXCEPTION 'User email cannot be null or empty';
  END IF;

  -- Insert into user_profiles with proper error handling
  BEGIN
    INSERT INTO public.user_profiles (
      id, 
      email, 
      full_name, 
      selected_life_domains,
      created_at,
      updated_at
    )
    VALUES (
      NEW.id,
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
      COALESCE(
        (SELECT ARRAY(SELECT jsonb_array_elements_text(NEW.raw_user_meta_data->'selected_life_domains'))::public.life_domain[]),
        ARRAY['sante', 'developpement']::public.life_domain[]
      ),
      COALESCE(NEW.created_at, CURRENT_TIMESTAMP),
      COALESCE(NEW.updated_at, CURRENT_TIMESTAMP)
    )
    ON CONFLICT (id) DO UPDATE SET
      email = EXCLUDED.email,
      full_name = EXCLUDED.full_name,
      selected_life_domains = EXCLUDED.selected_life_domains,
      updated_at = CURRENT_TIMESTAMP;
      
  EXCEPTION
    WHEN OTHERS THEN
      -- Log error but don't fail the user creation
      RAISE WARNING 'Failed to create user profile for user %: %', NEW.id, SQLERRM;
      -- Still return NEW to allow auth.users insertion to succeed
  END;
  
  RETURN NEW;
END;
$function$;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Add index to improve performance on user profile lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_email_lookup 
ON public.user_profiles(email) 
WHERE email IS NOT NULL;

-- Add a function to manually sync existing auth users who might not have profiles
CREATE OR REPLACE FUNCTION public.sync_missing_user_profiles()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  sync_count INTEGER := 0;
  user_record RECORD;
BEGIN
  -- Find auth.users who don't have corresponding user_profiles
  FOR user_record IN 
    SELECT au.id, au.email, au.raw_user_meta_data, au.created_at, au.updated_at
    FROM auth.users au
    LEFT JOIN public.user_profiles up ON au.id = up.id
    WHERE up.id IS NULL
      AND au.email IS NOT NULL
      AND au.email != ''
  LOOP
    -- Create missing user profile
    BEGIN
      INSERT INTO public.user_profiles (
        id, 
        email, 
        full_name, 
        selected_life_domains,
        created_at,
        updated_at
      )
      VALUES (
        user_record.id,
        user_record.email,
        COALESCE(user_record.raw_user_meta_data->>'full_name', split_part(user_record.email, '@', 1)),
        COALESCE(
          (SELECT ARRAY(SELECT jsonb_array_elements_text(user_record.raw_user_meta_data->'selected_life_domains'))::public.life_domain[]),
          ARRAY['sante', 'developpement']::public.life_domain[]
        ),
        COALESCE(user_record.created_at, CURRENT_TIMESTAMP),
        COALESCE(user_record.updated_at, CURRENT_TIMESTAMP)
      );
      
      sync_count := sync_count + 1;
      
    EXCEPTION
      WHEN OTHERS THEN
        RAISE WARNING 'Failed to sync user profile for user %: %', user_record.id, SQLERRM;
    END;
  END LOOP;
  
  RETURN sync_count;
END;
$function$;

-- Run the sync function to fix any existing users without profiles
SELECT public.sync_missing_user_profiles();