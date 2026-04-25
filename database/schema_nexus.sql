-- Nexus: Sistema de Conciliação de Cartões de Crédito
-- Schema PostgreSQL com Row Level Security (RLS)
-- Data: 2026-04-24

-- ============================================================================
-- 1. ENUMS E TIPOS
-- ============================================================================

CREATE TYPE status_transacao AS ENUM ('pendente', 'conciliada', 'divergencia', 'cancelada');
CREATE TYPE status_titulo AS ENUM ('pendente', 'pago', 'vencido', 'cancelado');
CREATE TYPE status_vinculo AS ENUM ('aguardando_validacao', 'confirmado', 'rejeitado', 'manual');

-- ============================================================================
-- 2. TABELAS DE DOMÍNIO
-- ============================================================================

-- Tabela de Filiais (Dimensão)
CREATE TABLE IF NOT EXISTS filiais (
  filial_id SERIAL PRIMARY KEY,
  codigo_filial VARCHAR(20) NOT NULL UNIQUE,
  nome_filial VARCHAR(255) NOT NULL,
  uf CHAR(2) NOT NULL,
  ativo BOOLEAN DEFAULT true,
  data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Transações GETNET (Adquirente)
CREATE TABLE IF NOT EXISTS transacoes_getnet (
  transacao_id BIGSERIAL PRIMARY KEY,
  filial_id INTEGER NOT NULL REFERENCES filiais(filial_id),
  nsu VARCHAR(20) NOT NULL,  -- Número Sequencial Único
  numero_autorizacao VARCHAR(20) NOT NULL,
  data_transacao DATE NOT NULL,
  hora_transacao TIME NOT NULL,
  valor NUMERIC(15, 2) NOT NULL CHECK (valor > 0),
  portador_digitos VARCHAR(4) NOT NULL,  -- Últimos 4 dígitos
  bandeira VARCHAR(50) NOT NULL,  -- Visa, Mastercard, Elo, etc.
  estabelecimento_codigo VARCHAR(20) NOT NULL,
  descricao_transacao VARCHAR(255),
  quantidade_parcelas SMALLINT DEFAULT 1,
  parcela_atual SMALLINT DEFAULT 1,
  status status_transacao DEFAULT 'pendente',
  hash_transacao VARCHAR(64) UNIQUE,  -- Para detect duplicatas
  data_ingesta TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(filial_id, nsu, numero_autorizacao)
);

-- Títulos TOTVS (ERP)
CREATE TABLE IF NOT EXISTS titulos_totvs (
  titulo_id BIGSERIAL PRIMARY KEY,
  filial_id INTEGER NOT NULL REFERENCES filiais(filial_id),
  numero_titulo VARCHAR(30) NOT NULL,
  numero_nf VARCHAR(20),
  serie_nf VARCHAR(10),
  data_emissao DATE NOT NULL,
  data_vencimento DATE NOT NULL,
  valor_total NUMERIC(15, 2) NOT NULL CHECK (valor_total > 0),
  valor_liquido NUMERIC(15, 2) NOT NULL CHECK (valor_liquido > 0),
  cliente_codigo VARCHAR(20) NOT NULL,
  cliente_nome VARCHAR(255) NOT NULL,
  natureza_operacao VARCHAR(100),
  referencia_cliente VARCHAR(50),
  status status_titulo DEFAULT 'pendente',
  data_ingesta TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(filial_id, numero_titulo)
);

-- ============================================================================
-- 3. TABELA DE LIGAÇÃO - RECONCILIAÇÃO (N:N)
-- ============================================================================

-- Vincula Transações GETNET com Títulos TOTVS
-- Suporta: 1 transação → N títulos (parcelado)
--          N transações → 1 título (múltiplos cartões)
--          Divergências com scoring de confiança
CREATE TABLE IF NOT EXISTS conciliacao_vinculos (
  vinculo_id BIGSERIAL PRIMARY KEY,
  filial_id INTEGER NOT NULL REFERENCES filiais(filial_id),
  transacao_getnet_id BIGINT NOT NULL REFERENCES transacoes_getnet(transacao_id) ON DELETE CASCADE,
  titulo_totvs_id BIGINT NOT NULL REFERENCES titulos_totvs(titulo_id) ON DELETE CASCADE,

  -- Análise de Matching
  diferenca_valor NUMERIC(15, 2) NOT NULL DEFAULT 0,
  diferenca_dias SMALLINT NOT NULL DEFAULT 0,
  score_confianca NUMERIC(3, 2) NOT NULL DEFAULT 0.00 CHECK (score_confianca BETWEEN 0 AND 1),

  -- Motivo da Rejeição (se houver)
  motivo_rejeicao VARCHAR(255),

  -- Status e Auditoria
  status status_vinculo DEFAULT 'aguardando_validacao',
  usuario_validacao VARCHAR(100),
  data_validacao TIMESTAMP WITH TIME ZONE,
  data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Índices para performance
  UNIQUE(transacao_getnet_id, titulo_totvs_id),
  INDEX idx_conciliacao_filial (filial_id),
  INDEX idx_conciliacao_status (status),
  INDEX idx_conciliacao_score (score_confianca DESC)
);

-- ============================================================================
-- 4. ÍNDICES PARA PERFORMANCE
-- ============================================================================

CREATE INDEX idx_transacoes_getnet_filial_data
  ON transacoes_getnet(filial_id, data_transacao DESC);

CREATE INDEX idx_transacoes_getnet_nsu
  ON transacoes_getnet(filial_id, nsu);

CREATE INDEX idx_titulos_totvs_filial_data
  ON titulos_totvs(filial_id, data_vencimento DESC);

CREATE INDEX idx_titulos_totvs_cliente
  ON titulos_totvs(filial_id, cliente_codigo);

-- ============================================================================
-- 5. ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Habilitar RLS nas tabelas
ALTER TABLE filiais ENABLE ROW LEVEL SECURITY;
ALTER TABLE transacoes_getnet ENABLE ROW LEVEL SECURITY;
ALTER TABLE titulos_totvs ENABLE ROW LEVEL SECURITY;
ALTER TABLE conciliacao_vinculos ENABLE ROW LEVEL SECURITY;

-- Política: Usuários veem apenas dados de suas filiais
-- (Assumindo uma tabela user_filiais que mapeia usuários a filiais)

CREATE POLICY rls_filiais_own
  ON filiais FOR ALL
  USING (filial_id IN (
    SELECT filial_id FROM user_filiais WHERE user_id = auth.uid()
  ));

CREATE POLICY rls_transacoes_getnet_own
  ON transacoes_getnet FOR ALL
  USING (filial_id IN (
    SELECT filial_id FROM user_filiais WHERE user_id = auth.uid()
  ));

CREATE POLICY rls_titulos_totvs_own
  ON titulos_totvs FOR ALL
  USING (filial_id IN (
    SELECT filial_id FROM user_filiais WHERE user_id = auth.uid()
  ));

CREATE POLICY rls_conciliacao_vinculos_own
  ON conciliacao_vinculos FOR ALL
  USING (filial_id IN (
    SELECT filial_id FROM user_filiais WHERE user_id = auth.uid()
  ));

-- ============================================================================
-- 6. FUNÇÕES DE AUDITORIA E AUTOMAÇÃO
-- ============================================================================

-- Trigger: Atualizar timestamp automaticamente
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.data_atualizacao = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_filiais_timestamp
  BEFORE UPDATE ON filiais FOR EACH ROW
  EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trigger_transacoes_getnet_timestamp
  BEFORE UPDATE ON transacoes_getnet FOR EACH ROW
  EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trigger_titulos_totvs_timestamp
  BEFORE UPDATE ON titulos_totvs FOR EACH ROW
  EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trigger_conciliacao_vinculos_timestamp
  BEFORE UPDATE ON conciliacao_vinculos FOR EACH ROW
  EXECUTE FUNCTION update_timestamp();

-- Função: Calcular score de matching automático
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
  IF ABS(valor_transacao - valor_titulo) / valor_titulo <= 0.05 THEN
    score := score + peso_valor;
  ELSIF ABS(valor_transacao - valor_titulo) / valor_titulo <= 0.10 THEN
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
-- 7. TABELAS DE SUPORTE PARA RLS
-- ============================================================================

-- Mapeamento de Usuários a Filiais
CREATE TABLE IF NOT EXISTS user_filiais (
  user_filial_id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  filial_id INTEGER NOT NULL REFERENCES filiais(filial_id) ON DELETE CASCADE,
  perfil VARCHAR(50) NOT NULL DEFAULT 'leitor',  -- leitor, operador, admin
  data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, filial_id)
);

-- ============================================================================
-- 8. DADOS INICIAIS
-- ============================================================================

-- Inserir filiais de exemplo
INSERT INTO filiais (codigo_filial, nome_filial, uf, ativo) VALUES
  ('SP001', 'São Paulo - Matriz', 'SP', true),
  ('RJ001', 'Rio de Janeiro - Filial', 'RJ', true),
  ('MG001', 'Minas Gerais - Filial', 'MG', true)
ON CONFLICT (codigo_filial) DO NOTHING;

-- ============================================================================
-- COMENTÁRIOS PARA DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON TABLE transacoes_getnet IS
  'Transações capturadas da adquirente GETNET.
   Cada registro representa uma transação de cartão de crédito.
   Chave única: (filial_id, nsu, numero_autorizacao)';

COMMENT ON TABLE titulos_totvs IS
  'Títulos a receber do sistema ERP TOTVS.
   Cada registro representa uma nota fiscal ou venda.
   Chave única: (filial_id, numero_titulo)';

COMMENT ON TABLE conciliacao_vinculos IS
  'Tabela de ligação que resolve a relação entre transações GETNET e títulos TOTVS.
   Suporta 1:N (uma transação para múltiplos títulos) e N:1 (múltiplas transações para um título).
   Score de confiança ajuda a resolver ambiguidades automaticamente.';
