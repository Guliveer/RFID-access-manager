-- ============================================================================
-- Migration: Create indexes
-- Description: Creates all performance indexes for the database tables
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Indexes for tokens table
-- ----------------------------------------------------------------------------

-- Index on rfid_uid for fast token lookup by RFID UID
CREATE INDEX IF NOT EXISTS idx_tokens_rfid_uid 
    ON public.tokens(rfid_uid);

-- Index on user_id for fast lookup of tokens by user
CREATE INDEX IF NOT EXISTS idx_tokens_user_id 
    ON public.tokens(user_id);

-- ----------------------------------------------------------------------------
-- Indexes for scanner_access table
-- ----------------------------------------------------------------------------

-- Index on user_id for fast lookup of access permissions by user
CREATE INDEX IF NOT EXISTS idx_scanner_access_user_id 
    ON public.scanner_access(user_id);

-- Index on scanner_id for fast lookup of access permissions by scanner
CREATE INDEX IF NOT EXISTS idx_scanner_access_scanner_id 
    ON public.scanner_access(scanner_id);

-- ----------------------------------------------------------------------------
-- Indexes for access_logs table
-- ----------------------------------------------------------------------------

-- Index on timestamp (descending) for fast retrieval of recent logs
CREATE INDEX IF NOT EXISTS idx_access_logs_timestamp 
    ON public.access_logs(timestamp DESC);

-- Index on scanner_id for filtering logs by scanner
CREATE INDEX IF NOT EXISTS idx_access_logs_scanner_id 
    ON public.access_logs(scanner_id);

-- Index on token_id for filtering logs by token
CREATE INDEX IF NOT EXISTS idx_access_logs_token_id 
    ON public.access_logs(token_id);

-- Index on rfid_uid for filtering logs by RFID UID (including unknown tokens)
CREATE INDEX IF NOT EXISTS idx_access_logs_rfid_uid 
    ON public.access_logs(rfid_uid);

-- ----------------------------------------------------------------------------
-- Comments on indexes
-- ----------------------------------------------------------------------------
COMMENT ON INDEX public.idx_tokens_rfid_uid IS 'Fast lookup of tokens by RFID UID';
COMMENT ON INDEX public.idx_tokens_user_id IS 'Fast lookup of tokens by user';
COMMENT ON INDEX public.idx_scanner_access_user_id IS 'Fast lookup of access permissions by user';
COMMENT ON INDEX public.idx_scanner_access_scanner_id IS 'Fast lookup of access permissions by scanner';
COMMENT ON INDEX public.idx_access_logs_timestamp IS 'Fast retrieval of recent access logs';
COMMENT ON INDEX public.idx_access_logs_scanner_id IS 'Fast filtering of access logs by scanner';
COMMENT ON INDEX public.idx_access_logs_token_id IS 'Fast filtering of access logs by token';
COMMENT ON INDEX public.idx_access_logs_rfid_uid IS 'Fast filtering of access logs by RFID UID';
