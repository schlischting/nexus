import { NextRequest, NextResponse } from 'next/server';
import { getServiceRoleClient } from '@/lib/supabase/server';

interface ScoreRequest {
  nsu_id: string;
  nf_id: string;
}

export async function POST(request: NextRequest) {
  try {
    const body: ScoreRequest = await request.json();
    const { nsu_id, nf_id } = body;

    if (!nsu_id || !nf_id) {
      return NextResponse.json(
        { error: 'nsu_id and nf_id are required' },
        { status: 400 }
      );
    }

    const supabase = getServiceRoleClient();

    if (!supabase) {
      return NextResponse.json(
        { error: 'Service unavailable' },
        { status: 503 }
      );
    }

    // Fetch NSU data
    const { data: nsuData, error: nsuError } = await (supabase as any)
      .from('transacoes_getnet')
      .select('transacao_id, nsu, valor_venda, data_venda, bandeira')
      .eq('transacao_id', nsu_id)
      .single();

    if (nsuError || !nsuData) {
      return NextResponse.json(
        { error: 'NSU not found' },
        { status: 404 }
      );
    }

    // Fetch NF data
    const { data: nfData, error: nfError } = await (supabase as any)
      .from('titulos_totvs')
      .select('id, numero_nf, valor_bruto, valor_liquido, data_emissao, data_vencimento, bandeira')
      .eq('id', nf_id)
      .single();

    if (nfError || !nfData) {
      return NextResponse.json(
        { error: 'NF not found' },
        { status: 404 }
      );
    }

    // Calculate score based on:
    // 1. Valor difference (tolerance: 5%)
    // 2. Data difference (tolerance: 3 days)
    // 3. Bandeira match (if available)

    const nsuValue = nsuData.valor_venda || 0;
    const nfValue = nfData.valor_liquido || nfData.valor_bruto || 0;

    // Valor difference percentage
    const valorDiff = Math.abs(nsuValue - nfValue) / nfValue;
    const valorScore = Math.max(0, 1 - valorDiff) * 0.5; // 50% weight

    // Data difference in days
    const nsuDate = new Date(nsuData.data_venda);
    const nfDate = new Date(nfData.data_vencimento || nfData.data_emissao);
    const daysDiff = Math.abs(
      Math.floor((nsuDate.getTime() - nfDate.getTime()) / (1000 * 60 * 60 * 24))
    );
    const diasScore = Math.max(0, 1 - daysDiff / 30) * 0.3; // 30% weight

    // Bandeira match
    const bandeiraNsu = nsuData.bandeira?.toLowerCase() || '';
    const bandeiraNf = nfData.bandeira?.toLowerCase() || '';
    const bandeiraMatch = bandeiraNsu === bandeiraNf || !bandeiraNf; // If NF has no bandeira, it's a match
    const bandeiraScore = bandeiraMatch ? 0.2 : 0; // 20% weight

    const totalScore = valorScore + diasScore + bandeiraScore;

    return NextResponse.json({
      score: Math.min(1, totalScore),
      breakdown: {
        valor_diff: (valorDiff * 100).toFixed(2),
        dias_diff: daysDiff,
        bandeira_match: bandeiraMatch,
      },
      details: {
        valor_score: valorScore.toFixed(3),
        dias_score: diasScore.toFixed(3),
        bandeira_score: bandeiraScore.toFixed(3),
      },
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Internal server error';
    return NextResponse.json(
      { error: message },
      { status: 500 }
    );
  }
}
