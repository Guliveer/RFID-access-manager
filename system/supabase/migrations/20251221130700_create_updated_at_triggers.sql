-- ============================================================================
-- Migration: Create updated_at triggers
-- Description: Creates the trigger function and triggers for automatic updated_at
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Function: update_updated_at_column()
-- Description: Trigger function to automatically update the updated_at column
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.update_updated_at_column() IS 'Trigger function to automatically update the updated_at column on row update';

-- ----------------------------------------------------------------------------
-- Trigger: update_users_updated_at
-- Description: Automatically updates updated_at on users table
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- ----------------------------------------------------------------------------
-- Trigger: update_scanners_updated_at
-- Description: Automatically updates updated_at on scanners table
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS update_scanners_updated_at ON public.scanners;
CREATE TRIGGER update_scanners_updated_at
    BEFORE UPDATE ON public.scanners
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- ----------------------------------------------------------------------------
-- Trigger: update_tokens_updated_at
-- Description: Automatically updates updated_at on tokens table
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS update_tokens_updated_at ON public.tokens;
CREATE TRIGGER update_tokens_updated_at
    BEFORE UPDATE ON public.tokens
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();
