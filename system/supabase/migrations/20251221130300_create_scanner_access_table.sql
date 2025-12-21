-- ============================================================================
-- Migration: Create scanner_access table
-- Description: Creates the scanner_access table with RLS policies
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: scanner_access
-- Description: Stores access permissions linking users to scanners
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.scanner_access (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    scanner_id UUID NOT NULL REFERENCES public.scanners(id) ON DELETE CASCADE,
    granted_by UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NULL,
    UNIQUE (user_id, scanner_id)
);

-- Add table comment
COMMENT ON TABLE public.scanner_access IS 'Access permissions linking users to scanners they can use';
COMMENT ON COLUMN public.scanner_access.id IS 'Unique identifier for the access permission';
COMMENT ON COLUMN public.scanner_access.user_id IS 'Reference to the user who has access';
COMMENT ON COLUMN public.scanner_access.scanner_id IS 'Reference to the scanner the user can access';
COMMENT ON COLUMN public.scanner_access.granted_by IS 'Reference to the user who granted this access';
COMMENT ON COLUMN public.scanner_access.is_active IS 'Whether the access permission is currently active';
COMMENT ON COLUMN public.scanner_access.created_at IS 'Timestamp when the access was granted';
COMMENT ON COLUMN public.scanner_access.expires_at IS 'Optional expiration timestamp for temporary access';

-- ----------------------------------------------------------------------------
-- Row Level Security (RLS) for scanner_access table
-- ----------------------------------------------------------------------------

-- Enable RLS
ALTER TABLE public.scanner_access ENABLE ROW LEVEL SECURITY;

-- Policy: Allow authenticated users to read all scanner_access
DROP POLICY IF EXISTS "scanner_access_select_authenticated" ON public.scanner_access;
CREATE POLICY "scanner_access_select_authenticated"
    ON public.scanner_access
    FOR SELECT
    TO authenticated
    USING (true);

-- Policy: Allow service_role to insert scanner_access
DROP POLICY IF EXISTS "scanner_access_insert_service_role" ON public.scanner_access;
CREATE POLICY "scanner_access_insert_service_role"
    ON public.scanner_access
    FOR INSERT
    TO service_role
    WITH CHECK (true);

-- Policy: Allow service_role to update scanner_access
DROP POLICY IF EXISTS "scanner_access_update_service_role" ON public.scanner_access;
CREATE POLICY "scanner_access_update_service_role"
    ON public.scanner_access
    FOR UPDATE
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Policy: Allow service_role to delete scanner_access
DROP POLICY IF EXISTS "scanner_access_delete_service_role" ON public.scanner_access;
CREATE POLICY "scanner_access_delete_service_role"
    ON public.scanner_access
    FOR DELETE
    TO service_role
    USING (true);
