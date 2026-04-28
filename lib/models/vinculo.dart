// Model: Vínculo de Reconciliação
// Mapeado da tabela conciliacao_vinculos

class Vinculo {
  final String vinculoId;
  final String filialCnpj;
  final String transacaoGetnetId;
  final String? tituloTotvsId;
  final String statusVinculo; // 'pendente_confirmacao', 'confirmado', 'sugerido', 'erro', 'nsu_invalido', 'rejeitado', 'exportado', 'baixado'
  final double scoreConfianca; // 0.0 - 1.0
  final String modalidadePagamento; // 'credito', 'debito'
  final int quantidadeParcelas;
  final String? statusBaixa; // 'sucesso' ou código erro
  final DateTime? dataBaixaTentativa;
  final DateTime? dataConfirmacao;
  final String? usuarioConfirmacao;
  final DateTime? dataExportacao;
  final DateTime criadoEm;
  final DateTime? atualizadoEm;

  Vinculo({
    required this.vinculoId,
    required this.filialCnpj,
    required this.transacaoGetnetId,
    this.tituloTotvsId,
    required this.statusVinculo,
    required this.scoreConfianca,
    required this.modalidadePagamento,
    required this.quantidadeParcelas,
    this.statusBaixa,
    this.dataBaixaTentativa,
    this.dataConfirmacao,
    this.usuarioConfirmacao,
    this.dataExportacao,
    required this.criadoEm,
    this.atualizadoEm,
  });

  factory Vinculo.fromJson(Map<String, dynamic> json) {
    return Vinculo(
      vinculoId: json['vinculo_id'] ?? '',
      filialCnpj: json['filial_cnpj'] ?? '',
      transacaoGetnetId: json['transacao_getnet_id'] ?? '',
      tituloTotvsId: json['titulo_totvs_id'],
      statusVinculo: json['status'] ?? 'pendente_confirmacao',
      scoreConfianca: (json['score_confianca'] as num?)?.toDouble() ?? 0.0,
      modalidadePagamento: json['modalidade_pagamento'] ?? 'credito',
      quantidadeParcelas: (json['quantidade_parcelas'] as num?)?.toInt() ?? 1,
      statusBaixa: json['status_baixa'],
      dataBaixaTentativa: json['data_baixa_tentativa'] != null
          ? DateTime.parse(json['data_baixa_tentativa'])
          : null,
      dataConfirmacao: json['data_confirmacao'] != null
          ? DateTime.parse(json['data_confirmacao'])
          : null,
      usuarioConfirmacao: json['usuario_confirmacao'],
      dataExportacao: json['data_exportacao'] != null
          ? DateTime.parse(json['data_exportacao'])
          : null,
      criadoEm: DateTime.parse(json['criado_em'] ?? DateTime.now().toIso8601String()),
      atualizadoEm: json['atualizado_em'] != null
          ? DateTime.parse(json['atualizado_em'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vinculo_id': vinculoId,
      'filial_cnpj': filialCnpj,
      'transacao_getnet_id': transacaoGetnetId,
      'titulo_totvs_id': tituloTotvsId,
      'status': statusVinculo,
      'score_confianca': scoreConfianca,
      'modalidade_pagamento': modalidadePagamento,
      'quantidade_parcelas': quantidadeParcelas,
      'status_baixa': statusBaixa,
      'data_baixa_tentativa': dataBaixaTentativa?.toIso8601String(),
      'data_confirmacao': dataConfirmacao?.toIso8601String(),
      'usuario_confirmacao': usuarioConfirmacao,
      'data_exportacao': dataExportacao?.toIso8601String(),
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm?.toIso8601String(),
    };
  }

  bool get isAutomatic => scoreConfianca >= 0.95;
  bool get isSuggestion => scoreConfianca >= 0.75 && scoreConfianca < 0.95;
  bool get isRejected => scoreConfianca < 0.75;

  String get statusEmoji {
    switch (statusVinculo) {
      case 'confirmado':
        return '✅';
      case 'sugerido':
        return '🟡';
      case 'erro':
        return '⚠️';
      case 'nsu_invalido':
        return '🔴';
      default:
        return '⚫';
    }
  }

  @override
  String toString() => 'Vinculo(nsu: $transacaoGetnetId, score: ${(scoreConfianca * 100).toStringAsFixed(1)}%, status: $statusVinculo)';
}
