// Domain types matching database schema_nexus_v3.0

export type StatusTransacao = 'pendente' | 'processado' | 'conciliado' | 'erro' | 'duplicado';
export type StatusTitulo = 'aberto' | 'parcial' | 'quitado' | 'cancelado' | 'duplicado';
export type StatusVinculo = 'sugestao' | 'confirmado' | 'rejeitado' | 'auto_confirmado' | 'em_processamento' | 'erro_processamento' | 'duplicado' | 'cancelado' | 'exportado';
export type TipoTitulo = 'NF' | 'AN' | 'PR' | 'CB' | 'CX' | 'OP' | 'CH' | 'BL';
export type PerfilUsuario = 'operador_filial' | 'supervisor' | 'admin';
export type ModalidadePagamento = 'credito_a_vista' | 'credito_parcelado' | 'debito';

export interface Transacao {
  transacao_id: string;
  filial_cnpj: string;
  nsu: string;
  data_solicitacao: string; // ISO date
  data_venda: string; // ISO date
  valor_bruto: number;
  valor_taxa: number;
  valor_liquido: number;
  bandeira: string;
  tipo: ModalidadePagamento;
  parcelas: number;
  cnpj_cliente: string;
  nome_cliente: string;
  status_transacao: StatusTransacao;
  criado_em: string; // ISO timestamp
  atualizado_em: string; // ISO timestamp
}

export interface Titulo {
  titulo_id: string;
  filial_cnpj: string;
  numero_nf: string;
  especie: TipoTitulo;
  serie: string;
  numero: string;
  parcela: number;
  data_emissao: string; // ISO date
  data_vencimento: string; // ISO date
  valor_bruto: number;
  desconto: number;
  acrescimo: number;
  valor_liquido: number;
  cnpj_cliente: string;
  nome_cliente: string;
  status_titulo: StatusTitulo;
  nsu_vinculado: string | null;
  criado_em: string; // ISO timestamp
  atualizado_em: string; // ISO timestamp
}

export interface Vinculo {
  vinculo_id: string;
  filial_cnpj: string;
  transacao_getnet_id: string;
  titulo_totvs_id: string;
  status_vinculo: StatusVinculo;
  score_confianca: number; // 0.0 to 1.0
  modalidade_pagamento: ModalidadePagamento;
  quantidade_parcelas: number;
  status_baixa: boolean;
  data_baixa_tentativa: string | null; // ISO timestamp
  data_confirmacao: string | null; // ISO timestamp
  usuario_confirmacao: string | null;
  data_exportacao: string | null; // ISO timestamp
  criado_em: string; // ISO timestamp
  atualizado_em: string; // ISO timestamp
}

export interface Usuario {
  user_id: string;
  email: string;
  nome: string;
  perfil: PerfilUsuario;
  ativo: boolean;
  criado_em: string;
  atualizado_em: string;
}

export interface UsuarioFilialCnpj {
  id: string;
  user_id: string;
  filial_cnpj: string;
  criado_em: string;
}

export interface DashboardMetrics {
  nsu_sem_titulo: number;
  titulo_sem_nsu: number;
  sugestoes_automaticas: number;
  sugestoes_pendentes: number;
  vinculos_confirmados_dia: number;
  vinculos_rejeitados_dia: number;
  taxa_sucesso: number; // 0-100
  score_medio: number; // 0.0-1.0
}

export interface NsuGap {
  transacao_id: string;
  nsu: string;
  valor_liquido: number;
  data_venda: string;
  banda: string;
  dias_sem_titulo: number;
  ultimo_vínculo_em: string | null;
  status_transacao: StatusTransacao;
}

export interface TituloGap {
  titulo_id: string;
  numero_nf: string;
  valor_liquido: number;
  data_vencimento: string;
  dias_sem_nsu: number;
  status_titulo: StatusTitulo;
}

export interface SuggestaoSupervisor {
  vinculo_id: string;
  transacao_id: string;
  titulo_id: string;
  nsu: string;
  numero_nf: string;
  valor_getnet: number;
  valor_totvs: number;
  data_venda: string;
  data_vencimento: string;
  dias_diferenca: number;
  score_confianca: number;
  modalidade_pagamento: ModalidadePagamento;
  quantidade_parcelas: number;
  status_vinculo: StatusVinculo;
}

export interface AuthState {
  user: { id: string; email: string } | null;
  loading: boolean;
  error: string | null;
}

export interface ExportTotvsPayload {
  vinculos_ids: string[];
  data_exportacao: string;
  usuario_id: string;
}

export interface ExportTotvsResult {
  sucesso: boolean;
  quantidade_exportada: number;
  data_exportacao: string;
  erros: Array<{ vinculo_id: string; mensagem: string }>;
}
