import { getServiceRoleClient } from '@/lib/supabase/server';
import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const supabase = getServiceRoleClient();

    if (!supabase) {
      return NextResponse.json(
        { error: 'Service unavailable' },
        { status: 503 }
      );
    }

    const body = await request.json();

    const { vinculos_ids, data_exportacao, usuario_id } = body;

    if (!vinculos_ids || !Array.isArray(vinculos_ids) || vinculos_ids.length === 0) {
      return NextResponse.json(
        { error: 'Invalid vinculos_ids' },
        { status: 400 }
      );
    }

    if (!usuario_id) {
      return NextResponse.json(
        { error: 'Missing usuario_id' },
        { status: 400 }
      );
    }

    // Call RPC function to export to TOTVS
    const { data, error } = await (supabase.rpc as any)('exportar_para_totvs', {
      p_vinculos_ids: vinculos_ids,
      p_data_exportacao: data_exportacao || new Date().toISOString(),
      p_usuario_id: usuario_id,
    });

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }

    return NextResponse.json({
      success: true,
      data,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Internal server error';
    return NextResponse.json(
      { error: message },
      { status: 500 }
    );
  }
}

export async function GET(request: NextRequest) {
  try {
    const supabase = getServiceRoleClient();

    if (!supabase) {
      return NextResponse.json(
        { error: 'Service unavailable' },
        { status: 503 }
      );
    }

    const filialCnpj = request.nextUrl.searchParams.get('filial_cnpj');

    if (!filialCnpj) {
      return NextResponse.json(
        { error: 'Missing filial_cnpj' },
        { status: 400 }
      );
    }

    // Get export history for filial
    const { data, error } = await supabase
      .from('conciliacao_vinculos')
      .select('*, transacoes_getnet(nsu), titulos_totvs(numero_nf)')
      .eq('filial_cnpj', filialCnpj)
      .eq('status_vinculo', 'exportado')
      .order('data_exportacao', { ascending: false })
      .limit(100);

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }

    return NextResponse.json(data);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Internal server error';
    return NextResponse.json(
      { error: message },
      { status: 500 }
    );
  }
}
