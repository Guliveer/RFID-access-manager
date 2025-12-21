-- ============================================================================
-- Migration: Create check_rfid_access function
-- Description: Creates the RPC function for checking RFID access
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Function: check_rfid_access(p_scanner_id UUID, p_token_uid TEXT)
-- Description: Checks if a token has access to a scanner and logs the attempt
-- Returns: JSON with access result and details
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.check_rfid_access(
    p_scanner_id UUID,
    p_token_uid TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_token RECORD;
    v_user RECORD;
    v_scanner RECORD;
    v_access RECORD;
    v_result JSONB;
    v_access_granted BOOLEAN := false;
    v_denial_reason TEXT := NULL;
    v_error_code TEXT := NULL;
BEGIN
    -- --------------------------------------------------------------------
    -- Step 1: Find the scanner
    -- --------------------------------------------------------------------
    SELECT * INTO v_scanner
    FROM public.scanners
    WHERE id = p_scanner_id;

    IF NOT FOUND THEN
        v_result := jsonb_build_object(
            'success', false,
            'error', 'Scanner not found',
            'error_code', 'SCANNER_NOT_FOUND',
            'access', jsonb_build_object(
                'granted', false,
                'until', NULL,
                'denyReason', 'Scanner not found'
            ),
            'data', jsonb_build_object(
                'rfid_uid', p_token_uid,
                'user_id', NULL,
                'scanner_id', p_scanner_id
            ),
            'timestamp', NOW()
        );
        
        -- Log the failed attempt
        INSERT INTO public.access_logs (scanner_id, access_granted, rfid_uid, denial_reason)
        VALUES (p_scanner_id, false, p_token_uid, 'Scanner not found');
        
        RETURN v_result;
    END IF;

    -- Check if scanner is active
    IF NOT v_scanner.is_active THEN
        v_denial_reason := 'Scanner is disabled';
        v_error_code := 'SCANNER_DISABLED';
        
        v_result := jsonb_build_object(
            'success', false,
            'error', v_denial_reason,
            'error_code', v_error_code,
            'access', jsonb_build_object(
                'granted', false,
                'until', NULL,
                'denyReason', v_denial_reason
            ),
            'data', jsonb_build_object(
                'rfid_uid', p_token_uid,
                'user_id', NULL,
                'scanner_id', p_scanner_id
            ),
            'timestamp', NOW()
        );
        
        -- Log the failed attempt
        INSERT INTO public.access_logs (scanner_id, access_granted, rfid_uid, denial_reason)
        VALUES (p_scanner_id, false, p_token_uid, v_denial_reason);
        
        RETURN v_result;
    END IF;

    -- --------------------------------------------------------------------
    -- Step 2: Find the token
    -- --------------------------------------------------------------------
    SELECT * INTO v_token
    FROM public.tokens
    WHERE rfid_uid = p_token_uid;

    IF NOT FOUND THEN
        v_denial_reason := 'Token not found';
        v_error_code := 'TOKEN_NOT_FOUND';
        
        v_result := jsonb_build_object(
            'success', false,
            'error', v_denial_reason,
            'error_code', v_error_code,
            'access', jsonb_build_object(
                'granted', false,
                'until', NULL,
                'denyReason', v_denial_reason
            ),
            'data', jsonb_build_object(
                'rfid_uid', p_token_uid,
                'user_id', NULL,
                'scanner_id', p_scanner_id
            ),
            'timestamp', NOW()
        );
        
        -- Log the failed attempt
        INSERT INTO public.access_logs (scanner_id, access_granted, rfid_uid, denial_reason)
        VALUES (p_scanner_id, false, p_token_uid, v_denial_reason);
        
        RETURN v_result;
    END IF;

    -- Check if token is active
    IF NOT v_token.is_active THEN
        v_denial_reason := 'Token is disabled';
        v_error_code := 'TOKEN_DISABLED';
        
        v_result := jsonb_build_object(
            'success', false,
            'error', v_denial_reason,
            'error_code', v_error_code,
            'access', jsonb_build_object(
                'granted', false,
                'until', NULL,
                'denyReason', v_denial_reason
            ),
            'data', jsonb_build_object(
                'rfid_uid', p_token_uid,
                'user_id', v_token.user_id,
                'scanner_id', p_scanner_id
            ),
            'timestamp', NOW()
        );
        
        -- Log the failed attempt
        INSERT INTO public.access_logs (token_id, scanner_id, access_granted, rfid_uid, denial_reason)
        VALUES (v_token.id, p_scanner_id, false, p_token_uid, v_denial_reason);
        
        RETURN v_result;
    END IF;

    -- --------------------------------------------------------------------
    -- Step 3: Find the user
    -- --------------------------------------------------------------------
    SELECT * INTO v_user
    FROM public.users
    WHERE id = v_token.user_id;

    IF NOT FOUND THEN
        v_denial_reason := 'User not found';
        v_error_code := 'USER_NOT_FOUND';
        
        v_result := jsonb_build_object(
            'success', false,
            'error', v_denial_reason,
            'error_code', v_error_code,
            'access', jsonb_build_object(
                'granted', false,
                'until', NULL,
                'denyReason', v_denial_reason
            ),
            'data', jsonb_build_object(
                'rfid_uid', p_token_uid,
                'user_id', v_token.user_id,
                'scanner_id', p_scanner_id
            ),
            'timestamp', NOW()
        );
        
        -- Log the failed attempt
        INSERT INTO public.access_logs (token_id, scanner_id, access_granted, rfid_uid, denial_reason)
        VALUES (v_token.id, p_scanner_id, false, p_token_uid, v_denial_reason);
        
        RETURN v_result;
    END IF;

    -- Check if user is active
    IF NOT v_user.is_active THEN
        v_denial_reason := 'User is disabled';
        v_error_code := 'USER_DISABLED';
        
        v_result := jsonb_build_object(
            'success', false,
            'error', v_denial_reason,
            'error_code', v_error_code,
            'access', jsonb_build_object(
                'granted', false,
                'until', NULL,
                'denyReason', v_denial_reason
            ),
            'data', jsonb_build_object(
                'rfid_uid', p_token_uid,
                'user_id', v_user.id,
                'scanner_id', p_scanner_id
            ),
            'timestamp', NOW()
        );
        
        -- Log the failed attempt
        INSERT INTO public.access_logs (token_id, scanner_id, access_granted, rfid_uid, denial_reason)
        VALUES (v_token.id, p_scanner_id, false, p_token_uid, v_denial_reason);
        
        RETURN v_result;
    END IF;

    -- --------------------------------------------------------------------
    -- Step 4: Check access permission
    -- --------------------------------------------------------------------
    SELECT * INTO v_access
    FROM public.scanner_access
    WHERE user_id = v_user.id
      AND scanner_id = p_scanner_id;

    IF NOT FOUND THEN
        v_denial_reason := 'No access permission';
        v_error_code := 'NO_ACCESS';
        
        v_result := jsonb_build_object(
            'success', false,
            'error', v_denial_reason,
            'error_code', v_error_code,
            'access', jsonb_build_object(
                'granted', false,
                'until', NULL,
                'denyReason', v_denial_reason
            ),
            'data', jsonb_build_object(
                'rfid_uid', p_token_uid,
                'user_id', v_user.id,
                'scanner_id', p_scanner_id
            ),
            'timestamp', NOW()
        );
        
        -- Log the failed attempt
        INSERT INTO public.access_logs (token_id, scanner_id, access_granted, rfid_uid, denial_reason)
        VALUES (v_token.id, p_scanner_id, false, p_token_uid, v_denial_reason);
        
        RETURN v_result;
    END IF;

    -- Check if access is active
    IF NOT v_access.is_active THEN
        v_denial_reason := 'Access permission is disabled';
        v_error_code := 'ACCESS_DISABLED';
        
        v_result := jsonb_build_object(
            'success', false,
            'error', v_denial_reason,
            'error_code', v_error_code,
            'access', jsonb_build_object(
                'granted', false,
                'until', v_access.expires_at,
                'denyReason', v_denial_reason
            ),
            'data', jsonb_build_object(
                'rfid_uid', p_token_uid,
                'user_id', v_user.id,
                'scanner_id', p_scanner_id
            ),
            'timestamp', NOW()
        );
        
        -- Log the failed attempt
        INSERT INTO public.access_logs (token_id, scanner_id, access_granted, rfid_uid, denial_reason)
        VALUES (v_token.id, p_scanner_id, false, p_token_uid, v_denial_reason);
        
        RETURN v_result;
    END IF;

    -- Check if access has expired
    IF v_access.expires_at IS NOT NULL AND v_access.expires_at < NOW() THEN
        v_denial_reason := 'Access permission has expired';
        v_error_code := 'ACCESS_EXPIRED';
        
        v_result := jsonb_build_object(
            'success', false,
            'error', v_denial_reason,
            'error_code', v_error_code,
            'access', jsonb_build_object(
                'granted', false,
                'until', v_access.expires_at,
                'denyReason', v_denial_reason
            ),
            'data', jsonb_build_object(
                'rfid_uid', p_token_uid,
                'user_id', v_user.id,
                'scanner_id', p_scanner_id
            ),
            'timestamp', NOW()
        );
        
        -- Log the failed attempt
        INSERT INTO public.access_logs (token_id, scanner_id, access_granted, rfid_uid, denial_reason)
        VALUES (v_token.id, p_scanner_id, false, p_token_uid, v_denial_reason);
        
        RETURN v_result;
    END IF;

    -- --------------------------------------------------------------------
    -- Step 5: Access granted!
    -- --------------------------------------------------------------------
    v_access_granted := true;
    
    -- Update token last_used_at
    UPDATE public.tokens
    SET last_used_at = NOW()
    WHERE id = v_token.id;
    
    -- Log the successful access
    INSERT INTO public.access_logs (token_id, scanner_id, access_granted, rfid_uid, denial_reason)
    VALUES (v_token.id, p_scanner_id, true, p_token_uid, NULL);
    
    v_result := jsonb_build_object(
        'success', true,
        'error', NULL,
        'error_code', NULL,
        'access', jsonb_build_object(
            'granted', true,
            'until', v_access.expires_at,
            'denyReason', NULL
        ),
        'data', jsonb_build_object(
            'rfid_uid', p_token_uid,
            'user_id', v_user.id,
            'scanner_id', p_scanner_id
        ),
        'timestamp', NOW()
    );
    
    RETURN v_result;
END;
$$;

-- Add function comment
COMMENT ON FUNCTION public.check_rfid_access(UUID, TEXT) IS 'Checks if an RFID token has access to a scanner, logs the attempt, and returns detailed result';

-- Grant execute permission to service_role and anon (for API access)
GRANT EXECUTE ON FUNCTION public.check_rfid_access(UUID, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.check_rfid_access(UUID, TEXT) TO anon;
