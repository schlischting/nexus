import { NextRequest, NextResponse } from 'next/server';
import { getServiceRoleClient } from '@/lib/supabase/server';

export async function GET(request: NextRequest) {
  try {
    const q = request.nextUrl.searchParams.get('q');
    const filial = request.nextUrl.searchParams.get('filial') || '';

    if (!q || q.trim().length === 0) {
      return NextResponse.json({ transacoes: [] });
    }

    const supabase = getServiceRoleClient();

    if (!supabase) {
      return NextResponse.json(
        { error: 'Service unavailable' },
        { status: 503 }
      );
    }

    const { data, error } = await (supabase as any)
      .from('transacoes_getnet')
      .select('transacao_id, nsu, valor_venda, data_venda, hora_venda, bandeira, modalidade, status')
      .ilike('nsu', `%${q}%`)
      .limit(10);

    if (error) {
      return NextResponse.json(
        { error: error.message },
        { status: 400 }
      );
    }

    // Map database columns to expected format
    const mapped = (data || []).map((row: any) => {
      const dataVenda = new Date(row.data_venda);
      const hoje = new Date();
      const diasPendente = Math.floor((hoje.getTime() - dataVenda.getTime()) / (1000 * 60 * 60 * 24));

      return {
        id: row.transacao_id,
        nsu: row.nsu,
        valor: row.valor_venda,
        data_venda: row.data_venda,
        hora_venda: row.hora_venda,
        bandeira: row.bandeira,
        modalidade: row.modalidade,
        tipo: row.modalidade === 'debito' ? 'debito' : 'credito',
        status: row.status,
        diasPendente: diasPendente,
      };
    });

    return NextResponse.json({ transacoes: mapped });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Internal server error';
    return NextResponse.json(
      { error: message },
      { status: 500 }
    );
  }
}
