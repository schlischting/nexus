import { NextRequest, NextResponse } from 'next/server';
import { getServiceRoleClient } from '@/lib/supabase/server';

export async function GET(request: NextRequest) {
  try {
    const q = request.nextUrl.searchParams.get('q');
    const filial = request.nextUrl.searchParams.get('filial') || '';

    if (!q || q.trim().length === 0) {
      return NextResponse.json({ titulos: [] });
    }

    const supabase = getServiceRoleClient();

    if (!supabase) {
      return NextResponse.json(
        { error: 'Service unavailable' },
        { status: 503 }
      );
    }

    const { data, error } = await (supabase as any)
      .from('titulos_totvs')
      .select('id, numero_nf, numero_titulo, valor_bruto, valor_liquido, data_emissao, data_vencimento, cliente_codigo, cliente_nome, status')
      .or(`numero_nf.ilike.%${q}%,numero_titulo.ilike.%${q}%`)
      .limit(10);

    if (error) {
      return NextResponse.json(
        { error: error.message },
        { status: 400 }
      );
    }

    // Map database columns to expected format
    const mapped = (data || []).map((row: any) => {
      const dataVencimento = new Date(row.data_vencimento);
      const hoje = new Date();
      const diasVencimento = Math.floor((dataVencimento.getTime() - hoje.getTime()) / (1000 * 60 * 60 * 24));

      return {
        id: row.id,
        numero_nf: row.numero_nf,
        numero_titulo: row.numero_titulo,
        valor: row.valor_liquido || row.valor_bruto,
        valor_bruto: row.valor_bruto,
        valor_liquido: row.valor_liquido,
        data_emissao: row.data_emissao,
        data_vencimento: row.data_vencimento,
        cliente_codigo: row.cliente_codigo,
        cliente_nome: row.cliente_nome,
        status: row.status,
        diasVencimento: diasVencimento,
      };
    });

    return NextResponse.json({ titulos: mapped });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Internal server error';
    return NextResponse.json(
      { error: message },
      { status: 500 }
    );
  }
}
