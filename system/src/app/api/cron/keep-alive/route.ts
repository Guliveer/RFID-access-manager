import { logger } from '@/lib/logger';
import { createAdminClient } from '@/utils/supabase/admin';
import { NextRequest, NextResponse } from 'next/server';

/**
 * Cron job endpoint to keep Supabase database alive
 * Prevents database from being paused due to inactivity
 *
 * Called by Vercel cron job with Authorization header
 */
export async function GET(request: NextRequest) {
    const authHeader = request.headers.get('authorization');
    const expectedToken = `Bearer ${process.env.CRON_SECRET}`;

    // Verify authorization
    if (!authHeader || authHeader !== expectedToken) {
        logger.warn('[CRON] Unauthorized keep-alive attempt');
        return NextResponse.json({error: 'Unauthorized'}, {status: 401});
    }

    try {
        const supabase = createAdminClient();
        const timestamp = new Date().toISOString();

        const {error} = await supabase.from('keep_alive').update({last_ping: timestamp}).eq('id', 1);

        if (error) {
            throw error;
        }

        logger.log('[CRON] Keep-alive ping successful:', timestamp);

        return NextResponse.json(
            {
                success: true,
                timestamp
            },
            {status: 200}
        );
    } catch (error) {
        logger.error('[CRON] Keep-alive ping failed:', error);

        return NextResponse.json(
            {
                error: 'Database ping failed',
                details: error instanceof Error ? error.message : 'Unknown error'
            },
            {status: 500}
        );
    }
}
