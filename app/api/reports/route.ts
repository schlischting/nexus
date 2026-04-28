import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

/**
 * GET /api/reports/dashboard
 * Retorna métricas consolidadas do dashboard
 */
export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const endpoint = searchParams.get('endpoint');
  const filialCnpj = searchParams.get('filial');

  try {
    // Autenticação
    const authHeader = request.headers.get('authorization');
    if (!authHeader) {
      return NextResponse.json(
        { error: 'Não autenticado' },
        { status: 401 }
      );
    }

    if (endpoint === 'dashboard') {
      // Dashboard metrics
      const { data: nsuList } = await supabase
        .from('transacoes_getnet')
        .select('*')
        .is('titulo_id', null)
        .eq('filial_cnpj', filialCnpj || '');

      const { data: nfList } = await supabase
        .from('titulos_totvs')
        .select('*')
        .is('transacao_id', null)
        .eq('filial_cnpj', filialCnpj || '');

      const { data: vinculos } = await supabase
        .from('vinculos')
        .select('*')
        .eq('status', 'confirmado')
        .eq('filial_cnpj', filialCnpj || '');

      return NextResponse.json({
        nsu_sem_titulo: nsuList?.length || 0,
        titulo_sem_nsu: nfList?.length || 0,
        vinculos_confirmados: vinculos?.length || 0,
        total_valor_gap: (nsuList || []).reduce((acc, row) => acc + (row.valor || 0), 0),
        timestamp: new Date().toISOString(),
      });
    }

    if (endpoint === 'export-csv') {
      // Export CSV
      const { data: vinculos } = await supabase
        .from('vinculos')
        .select('*')
        .eq('filial_cnpj', filialCnpj || '');

      const csv = [
        ['NSU', 'NF', 'Modalidade', 'Parcelas', 'Score', 'Status', 'Data'],
        ...(vinculos || []).map((v) => [
          v.nsu,
          v.nf_numero,
          v.modalidade,
          v.parcelas,
          (v.score_confianca * 100).toFixed(0) + '%',
          v.status,
          new Date(v.created_at).toLocaleDateString('pt-BR'),
        ]),
      ]
        .map((row) => row.join(','))
        .join('\n');

      return new NextResponse(csv, {
        headers: {
          'Content-Type': 'text/csv',
          'Content-Disposition': 'attachment; filename="vinculos.csv"',
        },
      });
    }

    if (endpoint === 'logs') {
      // Logs filtrados
      const days = searchParams.get('days') || '7';
      const logType = searchParams.get('type');

      const startDate = new Date();
      startDate.setDate(startDate.getDate() - parseInt(days));

      let query = supabase
        .from('logs')
        .select('*')
        .gte('timestamp', startDate.toISOString())
        .order('timestamp', { ascending: false });

      if (logType) {
        query = query.eq('log_type', logType);
      }

      const { data: logs } = await query.limit(1000);

      return NextResponse.json({
        logs,
        period_days: days,
        filter_type: logType || 'all',
        total_records: logs?.length || 0,
      });
    }

    return NextResponse.json(
      { error: 'Endpoint não encontrado' },
      { status: 404 }
    );
  } catch (error) {
    console.error('Erro em /api/reports:', error);
    return NextResponse.json(
      { error: 'Erro ao processar relatório' },
      { status: 500 }
    );
  }
}
