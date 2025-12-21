import { createClient } from '@supabase/supabase-js';

export const createAdminClient = () => {
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const supabaseSecretKey = process.env.SUPABASE_SECRET_API_KEY;

    if (!supabaseUrl || !supabaseSecretKey) {
        throw new Error('Missing Supabase admin credentials (SUPABASE_SECRET_API_KEY)');
    }

    return createClient(supabaseUrl, supabaseSecretKey, {
        auth: {
            autoRefreshToken: false,
            persistSession: false
        }
    });
};
