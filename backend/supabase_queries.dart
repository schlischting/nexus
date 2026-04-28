// Queries Supabase — Pronto para FlutterFlow
// Data: 2026-04-27
// Uso: Copiar/colar nas Actions do FlutterFlow ou em provider Flutter

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseQueries {
  static final supabase = Supabase.instance.client;

  // =========================================================================
  // 1. fetchNsuSemTitulo — Recupera NSUs sem título vinculado
  // =========================================================================
  /// Busca NSUs em transacoes_getnet que NÃO têm vínculo em conciliacao_vinculos
  /// Filtra automaticamente pela filial_cnpj do usuário (RLS)
  ///
  /// Uso em FlutterFlow:
  /// - Action: REST Call
  /// - URL: {project_url}/rest/v1/rpc/fetchNsuSemTitulo
  /// - Method: POST
  /// - Body: {"filial_cnpj": "12.345.678/0001-90"}
  static Future<List<Map<String, dynamic>>> fetchNsuSemTitulo(
      String filialCnpj) async {
    try {
      final response = await supabase
          .from('vw_nsu_sem_titulo')
          .select()
          .eq('filial_cnpj', filialCnpj)
          .order('data_venda', ascending: false)
          .limit(100);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erro ao buscar NSU sem título: $e');
      return [];
    }
  }

  // =========================================================================
  // 2. fetchTituloSemNsu — Recupera títulos TOTVS sem NSU vinculado
  // =========================================================================
  /// Busca títulos em titulos_totvs com status='aberto' que NÃO têm vínculo
  /// Filtra por tipo_titulo IN ('NF', 'AN')
  /// Filtra automaticamente pela filial_cnpj do usuário (RLS)
  ///
  /// Uso em FlutterFlow:
  /// - Action: REST Call
  /// - URL: {project_url}/rest/v1/rpc/fetchTituloSemNsu
  /// - Body: {"filial_cnpj": "12.345.678/0001-90"}
  static Future<List<Map<String, dynamic>>> fetchTituloSemNsu(
      String filialCnpj) async {
    try {
      final response = await supabase
          .from('vw_titulo_sem_nsu')
          .select()
          .eq('filial_cnpj', filialCnpj)
          .eq('status', 'aberto')
          .order('data_vencimento', ascending: true)
          .limit(100);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erro ao buscar título sem NSU: $e');
      return [];
    }
  }

  // =========================================================================
  // 3. fetchSugestoesSupervisor — Sugestões pendentes (score 0.75-0.95)
  // =========================================================================
  /// Busca vínculos com status='sugerido' e score_confianca entre 0.75 e 0.95
  /// Ordenado por score descendente
  /// Visível apenas para supervisor (RLS automático)
  ///
  /// Uso em FlutterFlow:
  /// - Action: REST Call
  /// - URL: {project_url}/rest/v1/rpc/fetchSugestoesSupervisor
  /// - Method: POST
  /// - Body: {} (vazio, RLS filtra pela role do JWT)
  static Future<List<Map<String, dynamic>>>
      fetchSugestoesSupervisor() async {
    try {
      final response = await supabase
          .from('vw_sugestoes_supervisor')
          .select()
          .eq('status', 'sugerido')
          .gte('score_confianca', 0.75)
          .lte('score_confianca', 0.95)
          .order('score_confianca', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erro ao buscar sugestões supervisor: $e');
      return [];
    }
  }

  // =========================================================================
  // 4. criarVinculo — Cria novo vínculo NSU + NF (Passo 3 do Lançamento)
  // =========================================================================
  /// Insere novo registro em conciliacao_vinculos com dados do wizard
  /// Status inicial: 'pendente_confirmacao'
  /// Chama RPC calcular_score_matching() automaticamente
  ///
  /// Parâmetros:
  ///   - nsuId: ID da transacao_getnet (transacao_id)
  ///   - tituloId: ID do titulo_totvs (titulo_id)
  ///   - filialCnpj: Filial do vínculo
  ///   - modalidade: 'credito' | 'debito'
  ///   - parcelas: INT (1-12)
  ///
  /// Uso em FlutterFlow:
  /// - Action: REST Call ou Supabase Insert
  /// - Body: JSON com os 5 parâmetros acima
  static Future<Map<String, dynamic>?> criarVinculo({
    required String nsuId,
    required String tituloId,
    required String filialCnpj,
    required String modalidade,
    required int parcelas,
  }) async {
    try {
      // Step 1: Buscar dados do NSU e Título para calcular score
      final nsuData = await supabase
          .from('transacoes_getnet')
          .select()
          .eq('transacao_id', nsuId)
          .single();

      final tituloData = await supabase
          .from('titulos_totvs')
          .select()
          .eq('titulo_id', tituloId)
          .single();

      // Step 2: Chamar RPC para calcular score
      final scoreResult = await supabase.rpc(
        'calcular_score_matching',
        params: {
          'p_valor_getnet': nsuData['valor_venda'],
          'p_valor_totvs': tituloData['valor_bruto'],
          'p_data_getnet': nsuData['data_venda'],
          'p_data_totvs': tituloData['data_vencimento'],
        },
      );

      final scoreConfianca = (scoreResult as num).toDouble();

      // Step 3: Determinar status baseado no score
      String statusVinculo = 'pendente_confirmacao';
      if (scoreConfianca >= 0.95) {
        statusVinculo = 'confirmado';
      } else if (scoreConfianca >= 0.75) {
        statusVinculo = 'sugerido';
      }

      // Step 4: Inserir vínculo
      final response = await supabase
          .from('conciliacao_vinculos')
          .insert({
            'transacao_getnet_id': nsuId,
            'titulo_totvs_id': tituloId,
            'filial_cnpj': filialCnpj,
            'status': statusVinculo,
            'score_confianca': scoreConfianca,
            'modalidade_pagamento': modalidade,
            'quantidade_parcelas': parcelas,
            'status_baixa': null,
            'data_baixa_tentativa': null,
          })
          .select()
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      print('Erro ao criar vínculo: $e');
      return null;
    }
  }

  // =========================================================================
  // 5. confirmarMatch — Confirma um match sugerido (Supervisor)
  // =========================================================================
  /// Atualiza status de 'sugerido' para 'confirmado'
  /// Registra data_confirmacao e usuario_confirmacao
  ///
  /// Uso em FlutterFlow:
  /// - Action: Supabase Update
  /// - Table: conciliacao_vinculos
  /// - Where: vinculo_id = {vinculoId}
  /// - Set: status='confirmado', data_confirmacao=NOW()
  static Future<bool> confirmarMatch(String vinculoId) async {
    try {
      final userId = supabase.auth.currentUser?.id ?? 'unknown';

      await supabase
          .from('conciliacao_vinculos')
          .update({
            'status': 'confirmado',
            'data_confirmacao': DateTime.now().toIso8601String(),
            'usuario_confirmacao': userId,
          })
          .eq('vinculo_id', vinculoId);

      return true;
    } catch (e) {
      print('Erro ao confirmar match: $e');
      return false;
    }
  }

  // =========================================================================
  // 6. exportarParaTOTVS — Exporta matches confirmados (Batch)
  // =========================================================================
  /// Atualiza status para 'exportado' para todos os matches confirmados
  /// Registra timestamp de exportação
  /// Em produção, chama API TOTVS (não implementado aqui)
  ///
  /// Parâmetros:
  ///   - filialCnpj: Filtra por filial (operador vê só sua filial)
  ///   - dataInicio/dataFim: Período da exportação
  ///
  /// Uso em FlutterFlow:
  /// - Action: REST Call
  /// - URL: {project_url}/rest/v1/rpc/exportarParaTOTVS
  /// - Body: {"filial_cnpj": "...", "data_inicio": "2026-04-20", "data_fim": "2026-04-27"}
  static Future<Map<String, dynamic>?> exportarParaTOTVS({
    required String filialCnpj,
    required String dataInicio,
    required String dataFim,
  }) async {
    try {
      // Step 1: Buscar matches confirmados no período
      final matches = await supabase
          .from('conciliacao_vinculos')
          .select()
          .eq('filial_cnpj', filialCnpj)
          .eq('status', 'confirmado')
          .gte('data_confirmacao', dataInicio)
          .lte('data_confirmacao', dataFim);

      if (matches.isEmpty) {
        return {'success': false, 'message': 'Nenhum match para exportar'};
      }

      // Step 2: Atualizar status para 'exportado'
      final ids = (matches as List).map((m) => m['vinculo_id']).toList();

      await supabase
          .from('conciliacao_vinculos')
          .update({
            'status': 'exportado',
            'data_exportacao': DateTime.now().toIso8601String(),
          })
          .inFilter('vinculo_id', ids);

      // Step 3: Retornar resultado
      return {
        'success': true,
        'message': 'Exportação realizada',
        'quantidade': matches.length,
        'registros': matches,
      };
    } catch (e) {
      print('Erro ao exportar para TOTVS: $e');
      return {'success': false, 'message': 'Erro: $e'};
    }
  }

  // =========================================================================
  // BONUS: Stream Real-Time para Dashboard (Operador)
  // =========================================================================
  /// Retorna Stream de updates em tempo real na view vw_nsu_sem_titulo
  /// Use com StreamBuilder no FlutterFlow
  ///
  /// Uso em FlutterFlow:
  /// - Criar StreamBuilder
  /// - Stream: SupabaseQueries.streamNsuSemTitulo(filialCnpj)
  static Stream<List<Map<String, dynamic>>> streamNsuSemTitulo(
      String filialCnpj) {
    return supabase
        .from('vw_nsu_sem_titulo')
        .on(RealtimeListenEvent.all, (payload) {
          print('Real-time update: $payload');
        })
        .eq('filial_cnpj', filialCnpj)
        .asStream()
        .map((event) => event.isEmpty ? [] : event as List<Map<String, dynamic>>);
  }

  // =========================================================================
  // BONUS: Stream Real-Time para Dashboard (Supervisor)
  // =========================================================================
  static Stream<List<Map<String, dynamic>>> streamSugestoesSupervisor() {
    return supabase
        .from('vw_sugestoes_supervisor')
        .on(RealtimeListenEvent.all, (payload) {
          print('Real-time sugestões: $payload');
        })
        .eq('status', 'sugerido')
        .asStream()
        .map((event) => event.isEmpty ? [] : event as List<Map<String, dynamic>>);
  }
}
