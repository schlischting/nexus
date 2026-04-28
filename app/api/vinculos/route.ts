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

    const {
      filial_cnpj,
      transacao_getnet_id,
      titulo_totvs_id,
      modalidade_pagamento,
      quantidade_parcelas,
    } = body;

    if (
      !filial_cnpj ||
      !transacao_getnet_id ||
      !titulo_totvs_id ||
      !modalidade_pagamento ||
      !quantidade_parcelas
    ) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      );
    }

    // Call RPC function to create vinculo and calculate score
    const { data, error } = await (supabase.rpc as any)('calcular_score_matching', {
      p_filial_cnpj: filial_cnpj,
      p_transacao_getnet_id: transacao_getnet_id,
      p_titulo_totvs_id: titulo_totvs_id,
      p_modalidade_pagamento: modalidade_pagamento,
      p_quantidade_parcelas: quantidade_parcelas,
    });

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

export async function PUT(request: NextRequest) {
  try {
    const supabase = getServiceRoleClient();

    if (!supabase) {
      return NextResponse.json(
        { error: 'Service unavailable' },
        { status: 503 }
      );
    }

    const body = await request.json();

    const { vinculo_id, action, usuario_id } = body;

    if (!vinculo_id || !action) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      );
    }

    let updateData: any = { atualizado_em: new Date().toISOString() };

    if (action === 'confirm') {
      updateData.status_vinculo = 'confirmado';
      updateData.data_confirmacao = new Date().toISOString();
      updateData.usuario_confirmacao = usuario_id;
    } else if (action === 'reject') {
      updateData.status_vinculo = 'rejeitado';
    } else {
      return NextResponse.json(
        { error: 'Invalid action' },
        { status: 400 }
      );
    }

    const { error } = await (supabase as any)
      .from('conciliacao_vinculos')
      .update(updateData)
      .eq('vinculo_id', vinculo_id);

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Internal server error';
    return NextResponse.json(
      { error: message },
      { status: 500 }
    );
  }
}
