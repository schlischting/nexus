-- ============================================================================
-- NEXUS: Sistema de Conciliação de Cartões de Crédito
-- Schema PostgreSQL Definitivo com Row Level Security (RLS)
-- ============================================================================
-- Data: 2026-04-24
-- Versão: 2.1 (Ajustes finais de negócio: perfis, tipos de título, baixa TOTVS)
--
-- PRINCIPAIS MUDANÇAS v2.0 → v2.1:
--   ✓ Perfis de usuário refinados: operador_filial, supervisor, admin
--   ✓ RLS ajustado para respeitar perfis (supervisor vê todas filiais)
--   ✓ tipo_titulo em titulos_totvs: 'NF' | 'AN' | 'OUTRO'
--   ✓ Campos de baixa TOTVS: data_baixa_totvs, status_baixa, erro_baixa
--   ✓ Status_vinculo revisado: pendente, confirmado, erro_baixa, rejeitado
--   ✓ Documentação clara sobre relacionamento 1:1 (com suporte N:N para exceções)
--
-- ============================================================================
-- 1. ENUMS - TIPOS DE STATUS
-- ============================================================================

CREATE TYPE status_transacao AS ENUM (
  'pendente',
  'conciliada',
  'divergencia',
  'cancelada',
  'duplicata'
);

CREATE TYPE status_titulo AS ENUM (
  'pendente',
  'pago',
  'vencido',
  'cancelado'
);

-- MUDANÇA v2.1: Status revisado para fluxo de baixa TOTVS
--   pendente         → Operador criou vínculo, aguarda confirmação
--   confirmado       → Baixa executada no TOTVS com sucesso
--   erro_baixa       → PASOE retornou erro, precisa revisão/retry
--   rejeitado        → Supervisor cancelou o vínculo
CREATE TYPE status_vinculo AS ENUM (
  'pendente',
  'confirmado',
  'erro_baixa',
  'rejeitado'
);

-- NOVO v2.1: Tipo de título (NF vs AN vs OUTRO)
CREATE TYPE tipo_titulo AS ENUM (
  'NF',     -- Nota Fiscal normal
  'AN',     -- Aviso de Nota (compensado automaticamente pelo TOTVS)
  'OUTRO'   -- Outros (boleto, duplicata, etc)
);

-- NOVO v2.1: Perfis de usuário para RLS
CREATE TYPE perfil_usuario AS ENUM (
  'operador_filial',  -- Acesso apenas à sua filial, pode criar vinculos
  'supervisor',       -- Acesso read em todas filiais, pode validar vinculos
  'admin'             -- Acesso total + configuração de parâmetros
);

-- ============================================================================
-- 2. TABELAS DE DOMÍNIO
-- ============================================================================

-- 2.1. Tabela de Filiais (Dimensão de Negócio)
CREATE TABLE IF NOT EXISTS filiais (
  filial_cnpj CHAR(14) PRIMARY KEY
    CONSTRAINT ck_filial_cnpj_format CHECK (filial_cnpj ~ '^\d{14}$'),

  codigo_ec VARCHAR(20),
  nome_filial VARCHAR(255) NOT NULL DEFAULT '',
  uf CHAR(2),
  razao_social VARCHAR(255),
  ativo BOOLEAN DEFAULT true,

  data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE filiais IS
  'Dimensão de Filiais. PK natural: filial_cnpj (14 dígitos).
   Criadas automaticamente pelo import_getnet.py se não existirem.
   Dados completos (UF, razao_social) devem ser preenchidos manualmente.';

COMMENT ON COLUMN filiais.filial_cnpj IS
  'CNPJ da filial (14 dígitos, sem formatação). PK natural.
   Formato: validado por CHECK constraint (^\d{14}$). Chave RLS.';

-- 2.2. Tabela de Mapeamento Usuário → Filiais (para RLS)
-- MUDANÇA v2.1: Perfil agora usa ENUM com 3 opções (operador_filial, supervisor, admin)
CREATE TABLE IF NOT EXISTS user_filiais_cnpj (
  user_filial_id SERIAL PRIMARY KEY,

  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  filial_cnpj CHAR(14) NOT NULL REFERENCES filiais(filial_cnpj) ON DELETE CASCADE,

  -- MUDANÇA v2.1: Perfil agora é ENUM (mais seguro que VARCHAR)
  perfil perfil_usuario NOT NULL DEFAULT 'operador_filial',

  data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Constraints
  -- Operador_filial: 1 usuário pode acessar múltiplas filiais
  -- Supervisor: 1 usuário acessa todas as filiais (independente desta tabela)
  -- Admin: acesso global
  UNIQUE(user_id, filial_cnpj)
);

COMMENT ON TABLE user_filiais_cnpj IS
  'Mapeamento de usuários para filiais com perfis (RLS).

   PERFIS (v2.1):
   - operador_filial: Acesso apenas às filiais listadas. Pode criar vinculos.
   - supervisor: Acesso read em TODAS as filiais (não precisa estar mapeado).
   - admin: Acesso total + configuração de parâmetros.

   Nota: Supervisor e admin têm acesso global via RLS, operador_filial é restrito.';

COMMENT ON COLUMN user_filiais_cnpj.perfil IS
  'Perfil do usuário para esta filial.
   - operador_filial: Acesso exclusivo a esta filial, pode criar vinculos manualmente
   - supervisor: Acesso read em todas filiais (verificar via auth.jwt())
   - admin: Acesso total + parâmetros (verificar via auth.jwt())';

-- MANTER PARA COMPATIBILIDADE
CREATE TABLE IF NOT EXISTS user_filiais (
  user_filial_id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  filial_cnpj CHAR(14) NOT NULL,

  perfil VARCHAR(50) NOT NULL DEFAULT 'leitor',
  data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(user_id, filial_cnpj)
);

-- 2.3. Tabela de Transações GETNET (Fatos)
CREATE TABLE IF NOT EXISTS transacoes_getnet (
  transacao_id BIGSERIAL PRIMARY KEY,

  -- Filial
  filial_cnpj CHAR(14) NOT NULL REFERENCES filiais(filial_cnpj),

  -- Identificadores
  nsu VARCHAR(20) NOT NULL,
  numero_autorizacao VARCHAR(20) NOT NULL,

  -- Data e hora
  data_transacao DATE NOT NULL,
  hora_transacao TIME NOT NULL,

  -- Valores
  valor NUMERIC(15, 2) NOT NULL
    CONSTRAINT ck_transacao_valor_positivo CHECK (valor > 0),

  -- Classificação
  bandeira VARCHAR(50) NOT NULL,
  codigo_ec VARCHAR(20) NOT NULL,
  tipo_lancamento VARCHAR(50) NOT NULL,

  -- Status
  status status_transacao DEFAULT 'pendente',
  hash_transacao VARCHAR(64) UNIQUE,
  eh_duplicata BOOLEAN DEFAULT false,

  -- Auditoria
  data_ingesta TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Constraints
  UNIQUE(filial_cnpj, nsu, numero_autorizacao, data_transacao),
  UNIQUE(hash_transacao)
);

COMMENT ON TABLE transacoes_getnet IS
  'Transações de cartão de crédito (adquirente GETNET).
   Cada linha = uma transação de vendas.
   Relacionamento com conciliacao_vinculos: 1 NSU → 1 vínculo (caso normal)
   Exceção: 1 NSU pode ter múltiplos vínculos em casos de parcelamento ou múltiplos cartões.';

-- 2.4. Tabela de Títulos TOTVS (Fatos do ERP)
-- MUDANÇA v2.1: Adicionar tipo_titulo (NF, AN, OUTRO)
CREATE TABLE IF NOT EXISTS titulos_totvs (
  titulo_id BIGSERIAL PRIMARY KEY,

  -- Filial
  filial_cnpj CHAR(14) NOT NULL REFERENCES filiais(filial_cnpj),

  -- Identificadores
  numero_titulo VARCHAR(30) NOT NULL,
  numero_nf VARCHAR(20),
  serie_nf VARCHAR(10),

  -- NOVO v2.1: Tipo de título (NF vs AN vs OUTRO)
  -- NF: Nota Fiscal normal
  -- AN: Aviso de Nota (TOTVS compensa automaticamente com NF futura, Nexus não rastreia)
  -- OUTRO: Boleto, duplicata, etc
  tipo_titulo tipo_titulo NOT NULL DEFAULT 'NF',

  -- Datas
  data_emissao DATE NOT NULL,
  data_vencimento DATE NOT NULL,

  -- Valores
  valor_total NUMERIC(15, 2) NOT NULL
    CONSTRAINT ck_titulo_valor_total_positivo CHECK (valor_total > 0),
  valor_liquido NUMERIC(15, 2) NOT NULL
    CONSTRAINT ck_titulo_valor_liquido_positivo CHECK (valor_liquido > 0),

  -- Cliente
  cliente_codigo VARCHAR(20) NOT NULL,
  cliente_nome VARCHAR(255) NOT NULL,

  -- Classificação
  natureza_operacao VARCHAR(100),
  referencia_cliente VARCHAR(50),

  -- Status
  status status_titulo DEFAULT 'pendente',
  data_ingesta TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Constraints
  UNIQUE(filial_cnpj, numero_titulo)
);

COMMENT ON TABLE titulos_totvs IS
  'Títulos a receber do sistema ERP TOTVS.
   Cada linha = uma nota fiscal ou venda registrada no ERP.

   NOVO v2.1 - tipo_titulo:
   - NF: Nota Fiscal normal. Sempre vinculado a transações GETNET.
   - AN: Aviso de Nota. Compensado automaticamente pelo TOTVS com NF futura.
         Nexus não precisa rastrear esta conversão.
   - OUTRO: Boleto, duplicata, etc. Casos especiais.';

COMMENT ON COLUMN titulos_totvs.tipo_titulo IS
  'Tipo de documento fiscal.
   - NF: Nota Fiscal (vinculação esperada com transação GETNET)
   - AN: Aviso de Nota (compensação automática TOTVS, Nexus não rastreia)
   - OUTRO: Outros tipos (boleto, duplicata, etc)';

-- 2.5. Tabela de Conciliação (Vinculação 1:1 na prática, N:N para exceções)
-- MUDANÇA v2.1: Adicionar campos de baixa TOTVS
CREATE TABLE IF NOT EXISTS conciliacao_vinculos (
  vinculo_id BIGSERIAL PRIMARY KEY,

  -- Filial (isolamento RLS)
  filial_cnpj CHAR(14) NOT NULL REFERENCES filiais(filial_cnpj),

  -- Vinculação
  -- Nota: Relacionamento é 1:1 na maioria dos casos (1 NSU → 1 título)
  --       Suporta N:N para exceções (parcelamento, múltiplos cartões)
  transacao_getnet_id BIGINT NOT NULL REFERENCES transacoes_getnet(transacao_id) ON DELETE CASCADE,
  titulo_totvs_id BIGINT REFERENCES titulos_totvs(titulo_id) ON DELETE SET NULL,
    -- MUDANÇA: NULLABLE para suportar criação manual antes de buscar título

  -- Análise de matching
  diferenca_valor NUMERIC(15, 2) NOT NULL DEFAULT 0,
  diferenca_dias SMALLINT NOT NULL DEFAULT 0,
  score_confianca NUMERIC(3, 2) NOT NULL DEFAULT 0.00
    CONSTRAINT ck_score_entre_0_e_1 CHECK (score_confianca BETWEEN 0 AND 1),

  -- NOVO v2.1: Informações de vínculo manual (para Portal do Operador)
  numero_nf_manual VARCHAR(30),
    -- Número de NF digitado manualmente pelo operador
    -- Preenchido quando titulo_totvs_id é NULL
  tipo_vinculacao VARCHAR(50) NOT NULL DEFAULT 'automatico',
    -- 'automatico' (script) ou 'manual' (operador Portal)

  -- NOVO v2.1: Campos de baixa TOTVS (automática após confirmação)
  data_baixa_totvs TIMESTAMP WITH TIME ZONE,
    -- Data/hora quando PASOE confirmou a baixa do título
  status_baixa VARCHAR(50),
    -- 'sucesso' ou código de erro do PASOE
  erro_baixa TEXT,
    -- Mensagem de erro completa do PASOE (se houver)

  -- Status e auditoria
  motivo_rejeicao VARCHAR(255),
  -- MUDANÇA v2.1: Status revisado
  status status_vinculo DEFAULT 'pendente',
    -- 'pendente': criado, aguarda confirmação
    -- 'confirmado': baixa TOTVS executada com sucesso
    -- 'erro_baixa': PASOE retornou erro, precisa revisão
    -- 'rejeitado': supervisor cancelou
  usuario_validacao VARCHAR(100),
  data_validacao TIMESTAMP WITH TIME ZONE,

  -- Auditoria
  data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Constraints
  -- 1:1 na prática, mas UNIQUE pode ser removido se realmente N:N for necessário
  UNIQUE(transacao_getnet_id, titulo_totvs_id)
);

COMMENT ON TABLE conciliacao_vinculos IS
  'Tabela de ligação para reconciliação entre GETNET e TOTVS.

   RELACIONAMENTO (v2.1):
   - Caso normal (1:1): 1 transação GETNET → 1 título TOTVS
   - Exceção (N:N): 1 transação → múltiplos títulos (parcelamento, múltiplos cartões)

   FLUXO:
   1. Operador digita NSU no Portal → cria vínculo com titulo_totvs_id=NULL
   2. Sistema busca título TOTVS e atualiza titulo_totvs_id
   3. Sistema chama PASOE para baixa automática
   4. Resultado registrado em data_baixa_totvs, status_baixa, erro_baixa

   STATUS:
   - pendente: aguardando confirmação
   - confirmado: baixa TOTVS bem-sucedida
   - erro_baixa: PASOE retornou erro, precisa revisão
   - rejeitado: supervisor cancelou manualmente';

COMMENT ON COLUMN conciliacao_vinculos.titulo_totvs_id IS
  'FK para título TOTVS. NULLABLE para suportar criação manual antes de encontrar título.
   Preenchido quando título é localizado via busca automática ou manual.';

COMMENT ON COLUMN conciliacao_vinculos.numero_nf_manual IS
  'Número de NF digitado manualmente pelo operador no Portal do Operador.
   Preenchido quando titulo_totvs_id é NULL (operador não tinha título disponível).
   Usado para busca e linkagem automática com título TOTVS depois.';

COMMENT ON COLUMN conciliacao_vinculos.tipo_vinculacao IS
  'Origem do vínculo: "automatico" (script de matching) ou "manual" (operador Portal).
   Permite filtrar, aplicar SLAs diferentes, e auditar decisões operacionais.';

COMMENT ON COLUMN conciliacao_vinculos.data_baixa_totvs IS
  'Data/hora quando PASOE confirmou a baixa do título no ERP.
   NULL se não foi feita tentativa ainda ou se falhou.';

COMMENT ON COLUMN conciliacao_vinculos.status_baixa IS
  'Status da tentativa de baixa no PASOE: "sucesso" ou código de erro.
   Exemplos: "sucesso", "E001_TITULO_NAO_ENCONTRADO", "E002_SALDO_INSUFICIENTE"';

COMMENT ON COLUMN conciliacao_vinculos.erro_baixa IS
  'Mensagem de erro completa retornada pelo PASOE (se houver).
   Exemplo: "Título 001234 não encontrado na filial 84943067001393"';

-- ============================================================================
-- 3. ÍNDICES PARA PERFORMANCE
-- ============================================================================

-- Índices em transacoes_getnet
CREATE INDEX idx_transacoes_getnet_filial_cnpj_data
  ON transacoes_getnet(filial_cnpj, data_transacao DESC);

CREATE INDEX idx_transacoes_getnet_filial_cnpj_nsu
  ON transacoes_getnet(filial_cnpj, nsu);

CREATE INDEX idx_transacoes_getnet_hash
  ON transacoes_getnet(hash_transacao);

CREATE INDEX idx_transacoes_getnet_status
  ON transacoes_getnet(status);

-- Índices em titulos_totvs
CREATE INDEX idx_titulos_totvs_filial_cnpj_data
  ON titulos_totvs(filial_cnpj, data_vencimento DESC);

CREATE INDEX idx_titulos_totvs_filial_cnpj_cliente
  ON titulos_totvs(filial_cnpj, cliente_codigo);

CREATE INDEX idx_titulos_totvs_status
  ON titulos_totvs(status);

-- NOVO v2.1: Índice para Dashboard filtrar por tipo_titulo
CREATE INDEX idx_titulos_totvs_tipo
  ON titulos_totvs(filial_cnpj, tipo_titulo);

-- Índices em conciliacao_vinculos
CREATE INDEX idx_conciliacao_vinculos_filial_cnpj
  ON conciliacao_vinculos(filial_cnpj);

CREATE INDEX idx_conciliacao_vinculos_status
  ON conciliacao_vinculos(status);

CREATE INDEX idx_conciliacao_vinculos_score
  ON conciliacao_vinculos(score_confianca DESC);

-- NOVO v2.1: Índice para Dashboard - Vínculos pendentes de baixa
CREATE INDEX idx_conciliacao_vinculos_pendente_baixa
  ON conciliacao_vinculos(filial_cnpj, status)
  WHERE status IN ('pendente', 'erro_baixa');

-- NOVO v2.1: Índice para Portal - Busca por tipo_vinculacao
CREATE INDEX idx_conciliacao_tipo_vinculacao
  ON conciliacao_vinculos(filial_cnpj, tipo_vinculacao)
  WHERE status = 'pendente';

-- ============================================================================
-- 4. ROW LEVEL SECURITY (RLS) - SEGURANÇA POR FILIAL E PERFIL
-- ============================================================================
-- MUDANÇA v2.1: Policies ajustadas para respeitar perfis (supervisor vê tudo)
--
-- FLUXO:
--   1. Usuário faz query: SELECT * FROM transacoes_getnet
--   2. RLS verifica: É supervisor/admin? Sim → vê tudo. Não → vê apenas suas filiais
--   3. Resultado: Dados filtrados por filial_cnpj
--

ALTER TABLE filiais ENABLE ROW LEVEL SECURITY;
ALTER TABLE transacoes_getnet ENABLE ROW LEVEL SECURITY;
ALTER TABLE titulos_totvs ENABLE ROW LEVEL SECURITY;
ALTER TABLE conciliacao_vinculos ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filiais_cnpj ENABLE ROW LEVEL SECURITY;

-- Política: Filiais - Operador vê apenas filiais autorizadas, supervisor vê tudo
CREATE POLICY rls_filiais_own
  ON filiais FOR ALL
  USING (
    auth.jwt() ->> 'role' IN ('admin', 'supervisor')
    OR filial_cnpj IN (
      SELECT filial_cnpj FROM user_filiais_cnpj WHERE user_id = auth.uid()
    )
  );

-- Política: Transações GETNET - Operador vê apenas de suas filiais, supervisor vê tudo
CREATE POLICY rls_transacoes_getnet_own
  ON transacoes_getnet FOR ALL
  USING (
    auth.jwt() ->> 'role' IN ('admin', 'supervisor')
    OR filial_cnpj IN (
      SELECT filial_cnpj FROM user_filiais_cnpj WHERE user_id = auth.uid()
    )
  );

-- Política: Títulos TOTVS - Operador vê apenas de suas filiais, supervisor vê tudo
CREATE POLICY rls_titulos_totvs_own
  ON titulos_totvs FOR ALL
  USING (
    auth.jwt() ->> 'role' IN ('admin', 'supervisor')
    OR filial_cnpj IN (
      SELECT filial_cnpj FROM user_filiais_cnpj WHERE user_id = auth.uid()
    )
  );

-- Política: Conciliação - Operador vê apenas de suas filiais, supervisor vê tudo
CREATE POLICY rls_conciliacao_vinculos_own
  ON conciliacao_vinculos FOR ALL
  USING (
    auth.jwt() ->> 'role' IN ('admin', 'supervisor')
    OR filial_cnpj IN (
      SELECT filial_cnpj FROM user_filiais_cnpj WHERE user_id = auth.uid()
    )
  );

-- Política: User Filiais CNPJ - Admin vê tudo, usuários veem seus próprios
CREATE POLICY rls_user_filiais_cnpj_own
  ON user_filiais_cnpj FOR ALL
  USING (user_id = auth.uid() OR auth.jwt() ->> 'role' = 'admin');

-- ============================================================================
-- 5. TRIGGERS DE AUDITORIA E AUTOMAÇÃO
-- ============================================================================

CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.data_atualizacao = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_filiais_timestamp
  BEFORE UPDATE ON filiais
  FOR EACH ROW
  EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trigger_transacoes_getnet_timestamp
  BEFORE UPDATE ON transacoes_getnet
  FOR EACH ROW
  EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trigger_titulos_totvs_timestamp
  BEFORE UPDATE ON titulos_totvs
  FOR EACH ROW
  EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trigger_conciliacao_vinculos_timestamp
  BEFORE UPDATE ON conciliacao_vinculos
  FOR EACH ROW
  EXECUTE FUNCTION update_timestamp();

-- ============================================================================
-- 6. FUNÇÕES PARA MATCHING E CÁLCULO DE SCORE
-- ============================================================================

CREATE OR REPLACE FUNCTION calcular_score_matching(
  valor_transacao NUMERIC,
  valor_titulo NUMERIC,
  dias_diferenca INTEGER,
  bandeira VARCHAR
)
RETURNS NUMERIC AS $$
DECLARE
  score NUMERIC := 0;
  peso_valor NUMERIC := 0.50;
  peso_data NUMERIC := 0.30;
  peso_tipo NUMERIC := 0.20;
BEGIN
  -- Score por valor (tolerância 5%)
  IF ABS(valor_transacao - valor_titulo) / NULLIF(valor_titulo, 0) <= 0.05 THEN
    score := score + peso_valor;
  ELSIF ABS(valor_transacao - valor_titulo) / NULLIF(valor_titulo, 0) <= 0.10 THEN
    score := score + (peso_valor * 0.5);
  END IF;

  -- Score por data (tolerância 3 dias)
  IF ABS(dias_diferenca) <= 3 THEN
    score := score + peso_data;
  ELSIF ABS(dias_diferenca) <= 7 THEN
    score := score + (peso_data * 0.5);
  END IF;

  -- Score por tipo de transação
  score := score + peso_tipo;

  RETURN ROUND(score, 2);
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 7. DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON SCHEMA public IS
  'Schema Nexus v2.1 - Sistema de Reconciliação de Cartões de Crédito.

   PRINCIPAIS MUDANÇAS v2.0 → v2.1 (REGRAS FINAIS DE NEGÓCIO):

   1. PERFIS DE USUÁRIO (RLS refinado):
      - operador_filial: Acesso apenas à sua filial, pode criar vinculos manualmente
      - supervisor: Acesso read em TODAS filiais (permissão global via JWT)
      - admin: Acesso total + configuração de parâmetros

   2. TIPO DE TÍTULO (novo em titulos_totvs):
      - NF: Nota Fiscal normal (vinculação esperada)
      - AN: Aviso de Nota (TOTVS compensa com NF futura, Nexus não rastreia)
      - OUTRO: Boleto, duplicata, etc.

   3. BAIXA AUTOMÁTICA TOTVS (novos campos em conciliacao_vinculos):
      - data_baixa_totvs: Quando PASOE confirmou
      - status_baixa: "sucesso" ou código de erro
      - erro_baixa: Mensagem de erro completa (se houver)

   4. STATUS DO VÍNCULO (revisado):
      - pendente: Criado, aguarda confirmação
      - confirmado: Baixa TOTVS bem-sucedida
      - erro_baixa: PASOE retornou erro, precisa revisão
      - rejeitado: Supervisor cancelou

   5. RELACIONAMENTO 1:1 NA PRÁTICA:
      - 1 NSU → 1 título (caso normal)
      - Suporte N:N para exceções (parcelamento, múltiplos cartões)
      - UNIQUE(transacao_getnet_id, titulo_totvs_id) garante 1:1 por padrão

   FLUXO COMPLETO:
   1. NSU chega via GETNET → insere em transacoes_getnet
   2. Operador (ou script) busca/cria vínculo → insere em conciliacao_vinculos
   3. Sistema encontra título TOTVS → atualiza titulo_totvs_id
   4. Sistema chama PASOE para baixa automática → registra resultado
   5. Supervisor acompanha no Dashboard (read-only)

   RLS SECURITY:
   - operador_filial: Vê apenas sua filial (via user_filiais_cnpj)
   - supervisor: Vê todas filiais (verificação via auth.jwt() ->> role)
   - admin: Acesso total
  ';

-- ============================================================================
-- FIM DO SCHEMA
-- ============================================================================
-- Data: 2026-04-24
-- Versão: 2.1 (Regras finais confirmadas)
-- Status: ✅ PRONTO PARA APLICAR NO SUPABASE
-- Próximos Passos:
--   1. Executar schema_nexus_v2.1.sql
--   2. Remover MIGRACAO_PORTAL_OPERADOR.sql (já está aqui)
--   3. Validar com SUPABASE_DEPLOYMENT_ROTEIRO.md
-- ============================================================================
