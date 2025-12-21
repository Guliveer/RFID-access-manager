-- ============================================================================
-- Migration: Create access_logs table
-- Description: Creates the access_logs table with RLS policies
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: access_logs
-- Description: Stores all access attempts (successful and denied)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.access_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_id UUID NULL REFERENCES public.tokens(id) ON DELETE SET NULL,
    scanner_id UUID NOT NULL REFERENCES public.scanners(id) ON DELETE CASCADE,
    access_granted BOOLEAN NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    rfid_uid TEXT NOT NULL,
    denial_reason TEXT NULL
);

-- Add table comment
COMMENT ON TABLE public.access_logs IS 'Log of all access attempts through RFID scanners';
COMMENT ON COLUMN public.access_logs.id IS 'Unique identifier for the log entry';
COMMENT ON COLUMN public.access_logs.token_id IS 'Reference to the token used (NULL if token not found)';
COMMENT ON COLUMN public.access_logs.scanner_id IS 'Reference to the scanner where access was attempted';
COMMENT ON COLUMN public.access_logs.access_granted IS 'Whether access was granted or denied';
COMMENT ON COLUMN public.access_logs.timestamp IS 'Timestamp of the access attempt';
COMMENT ON COLUMN public.access_logs.rfid_uid IS 'RFID UID that was scanned (stored even if token not found)';
COMMENT ON COLUMN public.access_logs.denial_reason IS 'Reason for denial if access was not granted';

-- ----------------------------------------------------------------------------
-- Row Level Security (RLS) for access_logs table
-- ----------------------------------------------------------------------------

-- Enable RLS
ALTER TABLE public.access_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Allow authenticated root/admin users to read access_logs
-- Note: This policy allows all authenticated users to read, 
-- but application logic should restrict to root/admin only
DROP POLICY IF EXISTS "access_logs_select_authenticated" ON public.access_logs;
CREATE POLICY "access_logs_select_authenticated"
    ON public.access_logs
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE users.id = auth.uid()
            AND users.role IN ('root', 'admin')
        )
    );

-- Policy: Allow service_role to insert access_logs
DROP POLICY IF EXISTS "access_logs_insert_service_role" ON public.access_logs;
CREATE POLICY "access_logs_insert_service_role"
    ON public.access_logs
    FOR INSERT
    TO service_role
    WITH CHECK (true);

-- Policy: Allow service_role to update access_logs (for corrections if needed)
DROP POLICY IF EXISTS "access_logs_update_service_role" ON public.access_logs;
CREATE POLICY "access_logs_update_service_role"
    ON public.access_logs
    FOR UPDATE
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Policy: Allow service_role to delete access_logs (for cleanup/archival)
DROP POLICY IF EXISTS "access_logs_delete_service_role" ON public.access_logs;
CREATE POLICY "access_logs_delete_service_role"
    ON public.access_logs
    FOR DELETE
    TO service_role
    USING (true);
