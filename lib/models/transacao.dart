// Model: Transação GETNET
// Mapeado da tabela transacoes_getnet

class Transacao {
  final String transacaoId;
  final String filialCnpj;
  final String nsu;
  final DateTime dataSolicitacao;
  final DateTime dataVenda;
  final double valorBruto;
  final double valorTaxa;
  final double valorLiquido;
  final String bandeira; // 'Visa', 'Mastercard', 'Elo', etc
  final String tipo; // 'credito', 'debito'
  final int parcelas;
  final String cnpjCliente;
  final String nomeCliente;
  final String statusTransacao; // 'pendente', 'confirmado', 'rejeitado', 'erro'
  final DateTime criadoEm;
  final DateTime? atualizadoEm;

  Transacao({
    required this.transacaoId,
    required this.filialCnpj,
    required this.nsu,
    required this.dataSolicitacao,
    required this.dataVenda,
    required this.valorBruto,
    required this.valorTaxa,
    required this.valorLiquido,
    required this.bandeira,
    required this.tipo,
    required this.parcelas,
    required this.cnpjCliente,
    required this.nomeCliente,
    required this.statusTransacao,
    required this.criadoEm,
    this.atualizadoEm,
  });

  factory Transacao.fromJson(Map<String, dynamic> json) {
    return Transacao(
      transacaoId: json['transacao_id'] ?? '',
      filialCnpj: json['filial_cnpj'] ?? '',
      nsu: json['nsu'] ?? '',
      dataSolicitacao: DateTime.parse(json['data_solicitacao'] ?? DateTime.now().toIso8601String()),
      dataVenda: DateTime.parse(json['data_venda'] ?? DateTime.now().toIso8601String()),
      valorBruto: (json['valor_bruto'] as num?)?.toDouble() ?? 0.0,
      valorTaxa: (json['valor_taxa'] as num?)?.toDouble() ?? 0.0,
      valorLiquido: (json['valor_liquido'] as num?)?.toDouble() ?? 0.0,
      bandeira: json['bandeira'] ?? 'Desconhecida',
      tipo: json['tipo'] ?? 'credito',
      parcelas: (json['parcelas'] as num?)?.toInt() ?? 1,
      cnpjCliente: json['cnpj_cliente'] ?? '',
      nomeCliente: json['nome_cliente'] ?? '',
      statusTransacao: json['status'] ?? 'pendente',
      criadoEm: DateTime.parse(json['criado_em'] ?? DateTime.now().toIso8601String()),
      atualizadoEm: json['atualizado_em'] != null
          ? DateTime.parse(json['atualizado_em'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transacao_id': transacaoId,
      'filial_cnpj': filialCnpj,
      'nsu': nsu,
      'data_solicitacao': dataSolicitacao.toIso8601String(),
      'data_venda': dataVenda.toIso8601String(),
      'valor_bruto': valorBruto,
      'valor_taxa': valorTaxa,
      'valor_liquido': valorLiquido,
      'bandeira': bandeira,
      'tipo': tipo,
      'parcelas': parcelas,
      'cnpj_cliente': cnpjCliente,
      'nome_cliente': nomeCliente,
      'status': statusTransacao,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm?.toIso8601String(),
    };
  }

  @override
  String toString() => 'Transacao(nsu: $nsu, valor: R\$ ${valorBruto.toStringAsFixed(2)}, data: $dataVenda)';
}
