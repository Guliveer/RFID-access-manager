-- ============================================================================
-- Migration: Create scanners table
-- Description: Creates the scanners table with RLS policies
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: scanners
-- Description: Stores RFID scanner/reader devices information
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.scanners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    location TEXT NOT NULL,
    description TEXT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    reader_type TEXT NOT NULL DEFAULT 'both' CHECK (reader_type IN ('entry', 'exit', 'both')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add table comment
COMMENT ON TABLE public.scanners IS 'RFID scanner/reader devices for access control';
COMMENT ON COLUMN public.scanners.id IS 'Unique identifier for the scanner';
COMMENT ON COLUMN public.scanners.name IS 'Display name of the scanner';
COMMENT ON COLUMN public.scanners.location IS 'Physical location of the scanner';
COMMENT ON COLUMN public.scanners.description IS 'Optional description of the scanner';
COMMENT ON COLUMN public.scanners.is_active IS 'Whether the scanner is currently active';
COMMENT ON COLUMN public.scanners.reader_type IS 'Type of reader: entry, exit, or both';
COMMENT ON COLUMN public.scanners.created_at IS 'Timestamp when the scanner was created';
COMMENT ON COLUMN public.scanners.updated_at IS 'Timestamp when the scanner was last updated';

-- ----------------------------------------------------------------------------
-- Row Level Security (RLS) for scanners table
-- ----------------------------------------------------------------------------

-- Enable RLS
ALTER TABLE public.scanners ENABLE ROW LEVEL SECURITY;

-- Policy: Allow authenticated users to read all scanners
DROP POLICY IF EXISTS "scanners_select_authenticated" ON public.scanners;
CREATE POLICY "scanners_select_authenticated"
    ON public.scanners
    FOR SELECT
    TO authenticated
    USING (true);

-- Policy: Allow service_role to insert scanners
DROP POLICY IF EXISTS "scanners_insert_service_role" ON public.scanners;
CREATE POLICY "scanners_insert_service_role"
    ON public.scanners
    FOR INSERT
    TO service_role
    WITH CHECK (true);

-- Policy: Allow service_role to update scanners
DROP POLICY IF EXISTS "scanners_update_service_role" ON public.scanners;
CREATE POLICY "scanners_update_service_role"
    ON public.scanners
    FOR UPDATE
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Policy: Allow service_role to delete scanners
DROP POLICY IF EXISTS "scanners_delete_service_role" ON public.scanners;
CREATE POLICY "scanners_delete_service_role"
    ON public.scanners
    FOR DELETE
    TO service_role
    USING (true);
