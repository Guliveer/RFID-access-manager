-- ============================================================================
-- Migration: Create tokens table
-- Description: Creates the tokens table with RLS policies
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: tokens
-- Description: Stores RFID tokens/cards assigned to users
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rfid_uid TEXT NOT NULL UNIQUE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_used_at TIMESTAMPTZ NULL
);

-- Add table comment
COMMENT ON TABLE public.tokens IS 'RFID tokens/cards assigned to users for access control';
COMMENT ON COLUMN public.tokens.id IS 'Unique identifier for the token';
COMMENT ON COLUMN public.tokens.rfid_uid IS 'Unique RFID UID of the token/card';
COMMENT ON COLUMN public.tokens.user_id IS 'Reference to the user who owns this token';
COMMENT ON COLUMN public.tokens.name IS 'Display name for the token (e.g., "Main Card", "Backup Key")';
COMMENT ON COLUMN public.tokens.is_active IS 'Whether the token is currently active';
COMMENT ON COLUMN public.tokens.created_at IS 'Timestamp when the token was created';
COMMENT ON COLUMN public.tokens.updated_at IS 'Timestamp when the token was last updated';
COMMENT ON COLUMN public.tokens.last_used_at IS 'Timestamp when the token was last used for access';

-- ----------------------------------------------------------------------------
-- Row Level Security (RLS) for tokens table
-- ----------------------------------------------------------------------------

-- Enable RLS
ALTER TABLE public.tokens ENABLE ROW LEVEL SECURITY;

-- Policy: Allow authenticated users to read all tokens
DROP POLICY IF EXISTS "tokens_select_authenticated" ON public.tokens;
CREATE POLICY "tokens_select_authenticated"
    ON public.tokens
    FOR SELECT
    TO authenticated
    USING (true);

-- Policy: Allow service_role to insert tokens
DROP POLICY IF EXISTS "tokens_insert_service_role" ON public.tokens;
CREATE POLICY "tokens_insert_service_role"
    ON public.tokens
    FOR INSERT
    TO service_role
    WITH CHECK (true);

-- Policy: Allow service_role to update tokens
DROP POLICY IF EXISTS "tokens_update_service_role" ON public.tokens;
CREATE POLICY "tokens_update_service_role"
    ON public.tokens
    FOR UPDATE
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Policy: Allow service_role to delete tokens
DROP POLICY IF EXISTS "tokens_delete_service_role" ON public.tokens;
CREATE POLICY "tokens_delete_service_role"
    ON public.tokens
    FOR DELETE
    TO service_role
    USING (true);
