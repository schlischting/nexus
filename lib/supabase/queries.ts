'use client';

import { useEffect, useState } from 'react';
import { getClient } from './client';
import { getServiceRoleClient } from './server';
import type {
  NsuGap,
  SuggestaoSupervisor,
  TituloGap,
  Vinculo,
  DashboardMetrics,
  ExportTotvsPayload,
  ExportTotvsResult,
} from '@/lib/types';

// Browser-side queries with RLS
export const fetchNsuSemTitulo = async (filialCnpj: string): Promise<NsuGap[]> => {
  const supabase = getClient();
  const { data, error } = await supabase
    .from('vw_nsu_sem_titulo')
    .select('*')
    .eq('filial_cnpj', filialCnpj)
    .order('dias_sem_titulo', { ascending: false });

  if (error) throw new Error(`Failed to fetch NSU gaps: ${error.message}`);
  return (data || []) as NsuGap[];
};

export const fetchTituloSemNsu = async (filialCnpj: string): Promise<TituloGap[]> => {
  const supabase = getClient();
  const { data, error } = await supabase
    .from('vw_titulo_sem_nsu')
    .select('*')
    .eq('filial_cnpj', filialCnpj)
    .order('dias_sem_nsu', { ascending: false });

  if (error) throw new Error(`Failed to fetch Titulo gaps: ${error.message}`);
  return (data || []) as TituloGap[];
};

export const fetchSugestoesSupervisor = async (
  filialCnpj?: string
): Promise<SuggestaoSupervisor[]> => {
  const supabase = getClient();
  let query = supabase.from('vw_sugestoes_supervisor').select('*');

  if (filialCnpj) {
    query = query.eq('filial_cnpj', filialCnpj);
  }

  const { data, error } = await query.order('score_confianca', {
    ascending: false,
  });

  if (error) throw new Error(`Failed to fetch suggestions: ${error.message}`);
  return (data || []) as SuggestaoSupervisor[];
};

export const criarVinculo = async (
  filialCnpj: string,
  transacaoId: string,
  tituloId: string,
  modalidadePagamento: string,
  quantidadeParcelas: number
): Promise<Vinculo> => {
  const supabase = getClient();

  const { data, error } = await supabase.rpc('calcular_score_matching', {
    p_filial_cnpj: filialCnpj,
    p_transacao_getnet_id: transacaoId,
    p_titulo_totvs_id: tituloId,
    p_modalidade_pagamento: modalidadePagamento,
    p_quantidade_parcelas: quantidadeParcelas,
  });

  if (error) throw new Error(`Failed to create vinculo: ${error.message}`);
  return data as Vinculo;
};

export const confirmarMatch = async (
  vinculoId: string,
  usuarioId: string
): Promise<void> => {
  const supabase = getClient();

  const { error } = await supabase
    .from('conciliacao_vinculos')
    .update({
      status_vinculo: 'confirmado',
      data_confirmacao: new Date().toISOString(),
      usuario_confirmacao: usuarioId,
      atualizado_em: new Date().toISOString(),
    })
    .eq('vinculo_id', vinculoId);

  if (error) throw new Error(`Failed to confirm match: ${error.message}`);
};

export const rejeitarVinculo = async (vinculoId: string): Promise<void> => {
  const supabase = getClient();

  const { error } = await supabase
    .from('conciliacao_vinculos')
    .update({
      status_vinculo: 'rejeitado',
      atualizado_em: new Date().toISOString(),
    })
    .eq('vinculo_id', vinculoId);

  if (error) throw new Error(`Failed to reject vinculo: ${error.message}`);
};

export const getDashboardMetrics = async (
  filialCnpj: string
): Promise<DashboardMetrics> => {
  const supabase = getClient();

  const [nsuGaps, tituloGaps, sugestoes] = await Promise.all([
    fetchNsuSemTitulo(filialCnpj),
    fetchTituloSemNsu(filialCnpj),
    fetchSugestoesSupervisor(filialCnpj),
  ]);

  const { data: vinculos } = await supabase
    .from('conciliacao_vinculos')
    .select('status_vinculo, score_confianca, criado_em')
    .eq('filial_cnpj', filialCnpj)
    .gte('criado_em', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString());

  const today = new Date().toDateString();
  const todayVinculos = (vinculos || []).filter(
    (v) => new Date(v.criado_em).toDateString() === today
  );

  const confirmados = todayVinculos.filter(
    (v) => v.status_vinculo === 'confirmado'
  ).length;
  const rejeitados = todayVinculos.filter(
    (v) => v.status_vinculo === 'rejeitado'
  ).length;

  const scoreSum = sugestoes.reduce((sum, s) => sum + s.score_confianca, 0);
  const scoreMedio = sugestoes.length > 0 ? scoreSum / sugestoes.length : 0;

  return {
    nsu_sem_titulo: nsuGaps.length,
    titulo_sem_nsu: tituloGaps.length,
    sugestoes_automaticas: sugestoes.filter((s) => s.score_confianca >= 0.95)
      .length,
    sugestoes_pendentes: sugestoes.filter(
      (s) => s.score_confianca >= 0.75 && s.score_confianca < 0.95
    ).length,
    vinculos_confirmados_dia: confirmados,
    vinculos_rejeitados_dia: rejeitados,
    taxa_sucesso:
      confirmados + rejeitados > 0
        ? (confirmados / (confirmados + rejeitados)) * 100
        : 0,
    score_medio: scoreMedio,
  };
};

export const exportarParaTOTVS = async (
  payload: ExportTotvsPayload
): Promise<ExportTotvsResult> => {
  const supabase = getClient();

  const { data, error } = await supabase.rpc('exportar_para_totvs', {
    p_vinculos_ids: payload.vinculos_ids,
    p_data_exportacao: payload.data_exportacao,
    p_usuario_id: payload.usuario_id,
  });

  if (error) throw new Error(`Failed to export: ${error.message}`);
  return data as ExportTotvsResult;
};

// Real-time subscription hook
export const useRealTimeUpdates = (table: string, filialCnpj?: string) => {
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    const supabase = getClient();

    let query = supabase
      .channel(`${table}-${filialCnpj || 'all'}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: table,
          ...(filialCnpj && { filter: `filial_cnpj=eq.${filialCnpj}` }),
        },
        (payload) => {
          window.dispatchEvent(
            new CustomEvent('supabase-update', { detail: { table, payload } })
          );
        }
      );

    query.on('system', { event: 'join' }, () => {
      setIsConnected(true);
    });

    query.on('system', { event: 'leave' }, () => {
      setIsConnected(false);
    });

    query.subscribe();

    return () => {
      supabase.removeChannel(query);
    };
  }, [table, filialCnpj]);

  return isConnected;
};

export const subscribeToVinculos = (
  filialCnpj: string,
  callback: (payload: any) => void
) => {
  const supabase = getClient();
  return supabase
    .channel(`vinculos-${filialCnpj}`)
    .on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: 'conciliacao_vinculos',
        filter: `filial_cnpj=eq.${filialCnpj}`,
      },
      callback
    )
    .subscribe();
};

// Novas queries para o redesign do operador
export const getNsuPendentes = async (filialCnpj: string) => {
  const supabase = getClient();
  const { data, error } = await supabase
    .from('transacoes_getnet')
    .select('*')
    .eq('filial_cnpj', filialCnpj)
    .eq('status', 'pendente')
    .order('data_venda', { ascending: false })
    .limit(100);

  if (error) throw new Error(`Failed to fetch NSU pendentes: ${error.message}`);
  return data || [];
};

export const getNsusComSugestao = async (filialCnpj: string) => {
  const supabase = getClient();
  const { data, error } = await supabase
    .from('vinculos')
    .select(`
      *,
      transacoes_getnet:transacao_id(nsu, valor_venda, data_venda, bandeira),
      titulos_totvs:nf_id(numero_nf, valor_liquido, data_vencimento)
    `)
    .eq('filial_cnpj', filialCnpj)
    .eq('status', 'sugerido')
    .order('score_confianca', { ascending: true })
    .limit(100);

  if (error) throw new Error(`Failed to fetch NSU com sugestão: ${error.message}`);
  return data || [];
};

export const getTitulosSemNsu = async (filialCnpj: string) => {
  const supabase = getClient();
  const { data, error } = await supabase
    .from('titulos_totvs')
    .select('*')
    .eq('filial_cnpj', filialCnpj)
    .eq('status', 'pendente')
    .order('data_vencimento', { ascending: true })
    .limit(100);

  if (error) throw new Error(`Failed to fetch títulos sem NSU: ${error.message}`);
  return data || [];
};

export const getUltimasConciliacoes = async (filialCnpj: string) => {
  const supabase = getClient();
  const { data, error } = await supabase
    .from('vinculos')
    .select(`
      *,
      transacoes_getnet:transacao_id(nsu, valor_venda, bandeira),
      titulos_totvs:nf_id(numero_nf, valor_liquido),
      users:user_id(email)
    `)
    .eq('filial_cnpj', filialCnpj)
    .eq('status', 'confirmado')
    .order('created_at', { ascending: false })
    .limit(50);

  if (error) throw new Error(`Failed to fetch últimas conciliações: ${error.message}`);
  return data || [];
};

export const criarVinculoPendente = async (
  transacaoId: string,
  filialCnpj: string,
  observacoes?: string
) => {
  const supabase = getClient();
  const { data, error } = await supabase
    .from('vinculos')
    .insert([
      {
        transacao_id: transacaoId,
        filial_cnpj: filialCnpj,
        status: 'pendente',
        observacoes,
        score_confianca: 0,
      },
    ])
    .select();

  if (error) throw new Error(`Failed to create vínculo pendente: ${error.message}`);
  return data?.[0];
};

export const criarVinculoComNf = async (
  transacaoId: string,
  nfId: string,
  filialCnpj: string,
  score: number,
  observacoes?: string,
  modalidade?: string,
  parcelas?: number
) => {
  const supabase = getClient();
  const status = score > 0.95 ? 'confirmado' : score >= 0.75 ? 'sugerido' : 'rejeitado';

  const { data, error } = await supabase
    .from('vinculos')
    .insert([
      {
        transacao_id: transacaoId,
        nf_id: nfId,
        filial_cnpj: filialCnpj,
        status,
        score_confianca: score,
        observacoes,
        modalidade,
        parcelas: parcelas || 1,
      },
    ])
    .select();

  if (error) throw new Error(`Failed to create vínculo com NF: ${error.message}`);
  return data?.[0];
};
