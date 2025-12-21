-- ============================================================================
-- Migration: Create users table
-- Description: Creates the users table with RLS policies and auth.users sync trigger
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: users
-- Description: Stores user profiles linked to Supabase auth.users
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('root', 'admin', 'user')),
    full_name TEXT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add table comment
COMMENT ON TABLE public.users IS 'User profiles linked to Supabase authentication';
COMMENT ON COLUMN public.users.id IS 'References auth.users(id), cascades on delete';
COMMENT ON COLUMN public.users.email IS 'User email address';
COMMENT ON COLUMN public.users.role IS 'User role: root, admin, or user';
COMMENT ON COLUMN public.users.full_name IS 'Optional full name of the user';
COMMENT ON COLUMN public.users.is_active IS 'Whether the user account is active';
COMMENT ON COLUMN public.users.created_at IS 'Timestamp when the user was created';
COMMENT ON COLUMN public.users.updated_at IS 'Timestamp when the user was last updated';

-- ----------------------------------------------------------------------------
-- Function: handle_new_user()
-- Description: Trigger function to sync new auth.users to public.users
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.users (id, email, role, full_name, is_active, created_at, updated_at)
    VALUES (
        NEW.id,
        NEW.email,
        'user',
        COALESCE(NEW.raw_user_meta_data->>'full_name', NULL),
        true,
        NOW(),
        NOW()
    );
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.handle_new_user() IS 'Trigger function to create a user profile when a new auth user is created';

-- ----------------------------------------------------------------------------
-- Trigger: on_auth_user_created
-- Description: Automatically creates a user profile when a new auth user signs up
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ----------------------------------------------------------------------------
-- Row Level Security (RLS) for users table
-- ----------------------------------------------------------------------------

-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Policy: Allow authenticated users to read all users
DROP POLICY IF EXISTS "users_select_authenticated" ON public.users;
CREATE POLICY "users_select_authenticated"
    ON public.users
    FOR SELECT
    TO authenticated
    USING (true);

-- Policy: Allow service_role to update users
DROP POLICY IF EXISTS "users_update_service_role" ON public.users;
CREATE POLICY "users_update_service_role"
    ON public.users
    FOR UPDATE
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Policy: Allow service_role to delete users
DROP POLICY IF EXISTS "users_delete_service_role" ON public.users;
CREATE POLICY "users_delete_service_role"
    ON public.users
    FOR DELETE
    TO service_role
    USING (true);

-- Policy: Allow service_role to insert users (for manual creation)
DROP POLICY IF EXISTS "users_insert_service_role" ON public.users;
CREATE POLICY "users_insert_service_role"
    ON public.users
    FOR INSERT
    TO service_role
    WITH CHECK (true);
