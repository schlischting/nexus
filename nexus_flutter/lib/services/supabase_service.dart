// Serviço Supabase — Singleton para acesso ao banco
// Implementa todas as queries necessárias com RLS automático

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transacao.dart';
import '../models/titulo.dart';
import '../models/vinculo.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  late SupabaseClient client;

  Future<void> initialize(String url, String anonKey) async {
    client = SupabaseClient(url, anonKey);
  }

  // =========================================================================
  // AUTENTICAÇÃO
  // =========================================================================

  User? get currentUser => client.auth.currentUser;

  Future<bool> login(String email, String password) async {
    try {
      await client.auth.signInWithPassword(email: email, password: password);
      return true;
    } catch (e) {
      print('Erro ao fazer login: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await client.auth.signOut();
  }

  // =========================================================================
  // BUSCAR DADOS — OPERADOR
  // =========================================================================

  /// Retorna NSUs sem título vinculado da filial do operador
  /// RLS filtra automaticamente por filial_cnpj do usuário
  Future<List<Transacao>> fetchNsuSemTitulo(String filialCnpj) async {
    try {
      final response = await client
          .from('vw_nsu_sem_titulo')
          .select()
          .eq('filial_cnpj', filialCnpj)
          .order('data_venda', ascending: false)
          .limit(100);

      return (response as List).map((e) => Transacao.fromJson(e)).toList();
    } catch (e) {
      print('Erro ao buscar NSU sem título: $e');
      return [];
    }
  }

  /// Retorna Títulos sem NSU vinculado da filial
  /// Filtra por status='aberto' e tipo_titulo IN ('NF', 'AN')
  Future<List<Titulo>> fetchTituloSemNsu(String filialCnpj) async {
    try {
      final response = await client
          .from('vw_titulo_sem_nsu')
          .select()
          .eq('filial_cnpj', filialCnpj)
          .order('data_vencimento', ascending: true)
          .limit(100);

      return (response as List).map((e) => Titulo.fromJson(e)).toList();
    } catch (e) {
      print('Erro ao buscar título sem NSU: $e');
      return [];
    }
  }

  /// Busca NSU pelo número (com like)
  Future<List<Transacao>> buscarNsu(String nsu, String filialCnpj) async {
    try {
      final response = await client
          .from('transacoes_getnet')
          .select()
          .ilike('nsu', '%$nsu%')
          .eq('filial_cnpj', filialCnpj)
          .order('data_venda', ascending: false)
          .limit(10);

      return (response as List).map((e) => Transacao.fromJson(e)).toList();
    } catch (e) {
      print('Erro ao buscar NSU: $e');
      return [];
    }
  }

  /// Busca Títulos pelo número NF
  Future<List<Titulo>> buscarTitulosPorNf(String numeroNf, String filialCnpj) async {
    try {
      final response = await client
          .from('titulos_totvs')
          .select()
          .ilike('numero_nf', '%$numeroNf%')
          .eq('filial_cnpj', filialCnpj)
          .eq('status', 'aberto')
          .order('data_vencimento', ascending: true)
          .limit(20);

      return (response as List).map((e) => Titulo.fromJson(e)).toList();
    } catch (e) {
      print('Erro ao buscar títulos por NF: $e');
      return [];
    }
  }

  // =========================================================================
  // CRIAR VÍNCULO (Lançamento NSU)
  // =========================================================================

  /// Cria novo vínculo NSU + NF com score automático
  /// 1. Busca dados do NSU e Título
  /// 2. Calcula score via RPC
  /// 3. Insere vínculo em conciliacao_vinculos
  /// 4. Retorna vínculo criado
  Future<Vinculo?> criarVinculo({
    required String nsuId,
    required String tituloId,
    required String filialCnpj,
    required String modalidade,
    required int parcelas,
  }) async {
    try {
      // Step 1: Buscar NSU
      final nsuData = await client
          .from('transacoes_getnet')
          .select()
          .eq('transacao_id', nsuId)
          .single();

      // Step 2: Buscar Título
      final tituloData = await client
          .from('titulos_totvs')
          .select()
          .eq('titulo_id', tituloId)
          .single();

      // Step 3: Calcular score via RPC
      final scoreResult = await client.rpc(
        'calcular_score_matching',
        params: {
          'p_valor_getnet': nsuData['valor_venda'],
          'p_valor_totvs': tituloData['valor_bruto'],
          'p_data_getnet': nsuData['data_venda'],
          'p_data_totvs': tituloData['data_vencimento'],
        },
      );

      final scoreConfianca = (scoreResult as num).toDouble();

      // Step 4: Determinar status baseado no score
      String statusVinculo = 'pendente_confirmacao';
      if (scoreConfianca >= 0.95) {
        statusVinculo = 'confirmado';
      } else if (scoreConfianca >= 0.75) {
        statusVinculo = 'sugerido';
      }

      // Step 5: Inserir vínculo
      final response = await client
          .from('conciliacao_vinculos')
          .insert({
            'transacao_getnet_id': nsuId,
            'titulo_totvs_id': tituloId,
            'filial_cnpj': filialCnpj,
            'status': statusVinculo,
            'score_confianca': scoreConfianca,
            'modalidade_pagamento': modalidade,
            'quantidade_parcelas': parcelas,
          })
          .select()
          .single();

      return Vinculo.fromJson(response);
    } catch (e) {
      print('Erro ao criar vínculo: $e');
      return null;
    }
  }

  // =========================================================================
  // SUPERVISOR — VALIDAR MATCHES
  // =========================================================================

  /// Retorna sugestões pendentes (0.75-0.95 score)
  /// Visível apenas para supervisor
  Future<List<Vinculo>> fetchSugestoesSupervisor() async {
    try {
      final response = await client
          .from('vw_sugestoes_supervisor')
          .select()
          .eq('status', 'sugerido')
          .gte('score_confianca', 0.75)
          .lte('score_confianca', 0.95)
          .order('score_confianca', ascending: false)
          .limit(50);

      return (response as List).map((e) => Vinculo.fromJson(e)).toList();
    } catch (e) {
      print('Erro ao buscar sugestões supervisor: $e');
      return [];
    }
  }

  /// Confirma um match sugerido (supervisor)
  Future<bool> confirmarMatch(String vinculoId) async {
    try {
      final userId = currentUser?.id ?? 'unknown';

      await client.from('conciliacao_vinculos').update({
        'status': 'confirmado',
        'data_confirmacao': DateTime.now().toIso8601String(),
        'usuario_confirmacao': userId,
      }).eq('vinculo_id', vinculoId);

      return true;
    } catch (e) {
      print('Erro ao confirmar match: $e');
      return false;
    }
  }

  /// Rejeita um vínculo sugerido
  Future<bool> rejeitarVinculo(String vinculoId) async {
    try {
      await client.from('conciliacao_vinculos').update({
        'status': 'rejeitado',
      }).eq('vinculo_id', vinculoId);

      return true;
    } catch (e) {
      print('Erro ao rejeitar vínculo: $e');
      return false;
    }
  }

  // =========================================================================
  // REAL-TIME STREAMS
  // =========================================================================

  /// Stream em tempo real de NSUs sem título
  Stream<List<Transacao>> streamNsuSemTitulo(String filialCnpj) {
    return client
        .from('vw_nsu_sem_titulo')
        .stream(primaryKey: ['transacao_id'])
        .eq('filial_cnpj', filialCnpj)
        .map((events) => events.map((e) => Transacao.fromJson(e)).toList());
  }

  /// Stream em tempo real de títulos sem NSU
  Stream<List<Titulo>> streamTituloSemNsu(String filialCnpj) {
    return client
        .from('vw_titulo_sem_nsu')
        .stream(primaryKey: ['titulo_id'])
        .eq('filial_cnpj', filialCnpj)
        .map((events) => events.map((e) => Titulo.fromJson(e)).toList());
  }

  /// Stream em tempo real de sugestões
  Stream<List<Vinculo>> streamSugestoesSupervisor() {
    return client
        .from('vw_sugestoes_supervisor')
        .stream(primaryKey: ['vinculo_id'])
        .eq('status', 'sugerido')
        .map((events) => events.map((e) => Vinculo.fromJson(e)).toList());
  }

  // =========================================================================
  // MÉTRICAS E DASHBOARD
  // =========================================================================

  /// Retorna contagem de vínculos por status
  Future<Map<String, int>> fetchMetricsOperador(String filialCnpj) async {
    try {
      final nsuCount = await client
          .from('vw_nsu_sem_titulo')
          .select('COUNT', const FetchOptions(count: CountOption.exact))
          .eq('filial_cnpj', filialCnpj)
          .then((response) => (response as dynamic).count ?? 0);

      final tituloCount = await client
          .from('vw_titulo_sem_nsu')
          .select('COUNT', const FetchOptions(count: CountOption.exact))
          .eq('filial_cnpj', filialCnpj)
          .then((response) => (response as dynamic).count ?? 0);

      final confirmadosCount = await client
          .from('conciliacao_vinculos')
          .select('COUNT', const FetchOptions(count: CountOption.exact))
          .eq('filial_cnpj', filialCnpj)
          .eq('status', 'confirmado')
          .then((response) => (response as dynamic).count ?? 0);

      return {
        'nsu_sem_titulo': nsuCount,
        'titulo_sem_nsu': tituloCount,
        'confirmados': confirmadosCount,
      };
    } catch (e) {
      print('Erro ao buscar métricas: $e');
      return {};
    }
  }
}
