/**
 * Logger & Analytics Module
 * Envia eventos de usuário para a tabela 'logs' no Supabase
 */

import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false },
});

export interface LogEvent {
  action: string;
  details?: Record<string, any>;
  userId?: string;
  filialCnpj?: string;
  timestamp?: string;
  userAgent?: string;
}

export interface ErrorLog {
  error: string;
  context?: Record<string, any>;
  stack?: string;
  userId?: string;
}

export interface PerformanceLog {
  action: string;
  duration: number; // milliseconds
  userId?: string;
}

/**
 * Log uma ação de usuário
 */
export async function logAction(event: LogEvent) {
  try {
    const { error } = await supabase.from('logs').insert({
      action: event.action,
      details: event.details || {},
      user_id: event.userId,
      filial_cnpj: event.filialCnpj,
      timestamp: event.timestamp || new Date().toISOString(),
      user_agent: event.userAgent || typeof navigator !== 'undefined' ? navigator.userAgent : null,
      log_type: 'action',
    });

    if (error) {
      console.error('Erro ao registrar ação:', error);
    }
  } catch (err) {
    console.error('Falha ao enviar log de ação:', err);
  }
}

/**
 * Log um erro
 */
export async function logError(log: ErrorLog) {
  try {
    const { error } = await supabase.from('logs').insert({
      action: 'error',
      details: {
        error: log.error,
        context: log.context,
        stack: log.stack,
      },
      user_id: log.userId,
      timestamp: new Date().toISOString(),
      user_agent: typeof navigator !== 'undefined' ? navigator.userAgent : null,
      log_type: 'error',
    });

    if (error) {
      console.error('Erro ao registrar erro:', error);
    }
  } catch (err) {
    console.error('Falha ao enviar log de erro:', err);
  }
}

/**
 * Log performance de uma ação
 */
export async function logPerformance(log: PerformanceLog) {
  try {
    const { error } = await supabase.from('logs').insert({
      action: log.action,
      details: {
        duration_ms: log.duration,
      },
      user_id: log.userId,
      timestamp: new Date().toISOString(),
      user_agent: typeof navigator !== 'undefined' ? navigator.userAgent : null,
      log_type: 'performance',
    });

    if (error) {
      console.error('Erro ao registrar performance:', error);
    }
  } catch (err) {
    console.error('Falha ao enviar log de performance:', err);
  }
}

/**
 * Atalho para eventos comuns
 */
export const logEvents = {
  login: (userId: string) =>
    logAction({ action: 'login', userId }),
  logout: (userId: string) =>
    logAction({ action: 'logout', userId }),
  createVinculo: (userId: string, nsu: string, nf: string, filialCnpj: string) =>
    logAction({
      action: 'create_vinculo',
      details: { nsu, nf },
      userId,
      filialCnpj,
    }),
  confirmMatch: (userId: string, vinculoId: string, filialCnpj: string) =>
    logAction({
      action: 'confirm_match',
      details: { vinculo_id: vinculoId },
      userId,
      filialCnpj,
    }),
  exportTotvs: (userId: string, recordCount: number, filialCnpj: string) =>
    logAction({
      action: 'export_totvs',
      details: { record_count: recordCount },
      userId,
      filialCnpj,
    }),
  viewDashboard: (userId: string, role: string) =>
    logAction({
      action: 'view_dashboard',
      details: { role },
      userId,
    }),
};
