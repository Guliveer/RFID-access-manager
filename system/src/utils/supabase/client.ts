import { createBrowserClient } from '@supabase/ssr';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
    throw new Error('Missing Supabase environment variables: NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY are required');
}

const validatedUrl: string = supabaseUrl;
const validatedKey: string = supabaseAnonKey;

let client: ReturnType<typeof createBrowserClient> | null = null;

export function createClient() {
    if (client) {
        return client;
    }

    client = createBrowserClient(validatedUrl, validatedKey);
    return client;
}
