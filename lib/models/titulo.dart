// Model: Título TOTVS
// Mapeado da tabela titulos_totvs

class Titulo {
  final String tituloId;
  final String filialCnpj;
  final String numeroNf;
  final String especie; // 'NF' ou 'AN'
  final String serie;
  final String numero;
  final String parcela;
  final DateTime dataEmissao;
  final DateTime dataVencimento;
  final double valorBruto;
  final double desconto;
  final double acrescimo;
  final double valorLiquido;
  final String cnpjCliente;
  final String nomeCliente;
  final String statusTitulo; // 'aberto', 'pago', 'cancelado'
  final String? nsuVinculado;
  final DateTime criadoEm;
  final DateTime? atualizadoEm;

  Titulo({
    required this.tituloId,
    required this.filialCnpj,
    required this.numeroNf,
    required this.especie,
    required this.serie,
    required this.numero,
    required this.parcela,
    required this.dataEmissao,
    required this.dataVencimento,
    required this.valorBruto,
    required this.desconto,
    required this.acrescimo,
    required this.valorLiquido,
    required this.cnpjCliente,
    required this.nomeCliente,
    required this.statusTitulo,
    this.nsuVinculado,
    required this.criadoEm,
    this.atualizadoEm,
  });

  factory Titulo.fromJson(Map<String, dynamic> json) {
    return Titulo(
      tituloId: json['titulo_id'] ?? '',
      filialCnpj: json['filial_cnpj'] ?? '',
      numeroNf: json['numero_nf'] ?? '',
      especie: json['tipo_titulo'] ?? 'NF',
      serie: json['serie'] ?? '',
      numero: json['numero'] ?? '',
      parcela: json['parcela'] ?? '1',
      dataEmissao: DateTime.parse(json['data_emissao'] ?? DateTime.now().toIso8601String()),
      dataVencimento: DateTime.parse(json['data_vencimento'] ?? DateTime.now().toIso8601String()),
      valorBruto: (json['valor_bruto'] as num?)?.toDouble() ?? 0.0,
      desconto: (json['desconto'] as num?)?.toDouble() ?? 0.0,
      acrescimo: (json['acrescimo'] as num?)?.toDouble() ?? 0.0,
      valorLiquido: (json['valor_liquido'] as num?)?.toDouble() ?? 0.0,
      cnpjCliente: json['cnpj_cliente'] ?? '',
      nomeCliente: json['nome_cliente'] ?? '',
      statusTitulo: json['status'] ?? 'aberto',
      nsuVinculado: json['nsu_vinculado'],
      criadoEm: DateTime.parse(json['criado_em'] ?? DateTime.now().toIso8601String()),
      atualizadoEm: json['atualizado_em'] != null
          ? DateTime.parse(json['atualizado_em'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo_id': tituloId,
      'filial_cnpj': filialCnpj,
      'numero_nf': numeroNf,
      'tipo_titulo': especie,
      'serie': serie,
      'numero': numero,
      'parcela': parcela,
      'data_emissao': dataEmissao.toIso8601String(),
      'data_vencimento': dataVencimento.toIso8601String(),
      'valor_bruto': valorBruto,
      'desconto': desconto,
      'acrescimo': acrescimo,
      'valor_liquido': valorLiquido,
      'cnpj_cliente': cnpjCliente,
      'nome_cliente': nomeCliente,
      'status': statusTitulo,
      'nsu_vinculado': nsuVinculado,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm?.toIso8601String(),
    };
  }

  @override
  String toString() => 'Titulo(nf: $numeroNf, valor: R\$ ${valorBruto.toStringAsFixed(2)}, vencimento: $dataVencimento)';
}
