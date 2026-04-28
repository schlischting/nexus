import { getServiceRoleClient } from '@/lib/supabase/server';
import { NextResponse } from 'next/server';

export const revalidate = 0; // Sem cache

export async function GET() {
  const startTime = Date.now();
  const results = {
    status: 'ok' as 'ok' | 'degraded' | 'error',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    version: '1.0.0',
    database: 'unknown' as 'connected' | 'error' | 'unknown',
    responseTime: 0,
    checks: {} as Record<string, { status: boolean; duration: number; message?: string }>,
  };

  try {
    // Check database connectivity
    const dbStart = Date.now();
    try {
      const supabase = getServiceRoleClient();

      if (!supabase) {
        throw new Error('Service unavailable');
      }

      // Simple query to verify connection
      const { data, error } = await supabase
        .from('filiais')
        .select('id', { count: 'exact' })
        .limit(1);

      const dbDuration = Date.now() - dbStart;

      if (error) {
        results.database = 'error';
        results.checks.database = {
          status: false,
          duration: dbDuration,
          message: error.message,
        };
        results.status = 'degraded';
      } else {
        results.database = 'connected';
        results.checks.database = {
          status: true,
          duration: dbDuration,
        };
      }
    } catch (dbError) {
      results.database = 'error';
      results.checks.database = {
        status: false,
        duration: Date.now() - dbStart,
        message: dbError instanceof Error ? dbError.message : 'Unknown error',
      };
      results.status = 'degraded';
    }

    // Check environment variables
    const envStart = Date.now();
    const requiredEnvVars = [
      'NEXT_PUBLIC_SUPABASE_URL',
      'NEXT_PUBLIC_SUPABASE_ANON_KEY',
      'SUPABASE_SERVICE_ROLE_KEY',
    ];

    const missingEnvVars = requiredEnvVars.filter(
      (varName) => !process.env[varName]
    );

    if (missingEnvVars.length > 0) {
      results.checks.environment = {
        status: false,
        duration: Date.now() - envStart,
        message: `Missing: ${missingEnvVars.join(', ')}`,
      };
      results.status = 'error';
    } else {
      results.checks.environment = {
        status: true,
        duration: Date.now() - envStart,
      };
    }

    // Memory usage
    const memStart = Date.now();
    if (global.gc) {
      global.gc();
    }
    const mem = process.memoryUsage();
    results.checks.memory = {
      status: mem.heapUsed / mem.heapTotal < 0.9, // Alert if > 90%
      duration: Date.now() - memStart,
      message: `${Math.round((mem.heapUsed / mem.heapTotal) * 100)}% heap used`,
    };

    if (mem.heapUsed / mem.heapTotal >= 0.9) {
      results.status = 'degraded';
    }

    results.responseTime = Date.now() - startTime;

    // Return appropriate status code
    const statusCode =
      results.status === 'ok' ? 200 : results.status === 'degraded' ? 503 : 500;

    return NextResponse.json(results, { status: statusCode });
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';

    return NextResponse.json(
      {
        status: 'error',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV || 'development',
        version: '1.0.0',
        database: 'error',
        responseTime: Date.now() - startTime,
        error: errorMessage,
      },
      { status: 500 }
    );
  }
}
