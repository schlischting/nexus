-- ============================================================================
-- NEXUS: Sistema de Conciliação de Cartões de Crédito
-- Schema PostgreSQL Definitivo com Row Level Security (RLS)
-- ============================================================================
-- Data: 2026-04-24
-- Versão: 2.0 (Consolidado com aprendizados do arquivo ADTO_23042026.xlsx)
--
-- PRINCIPAIS MUDANÇAS v1 → v2:
--   ✓ RLS baseado em filial_cnpj (CHAR 14) em vez de filial_id
--   ✓ filial_cnpj como PRIMARY KEY natural (mais seguro, menos redundância)
--   ✓ CHECK constraint para validar CNPJ (14 dígitos numéricos)
--   ✓ Hash transacao inclui CNPJ no escopo (CNPJ|NSU|Auth|Valor|Data)
--   ✓ hora_transacao como TIME (coluna separada, não extraída de timestamp)
--   ✓ Documentação de auto-criação de filiais
--   ✓ Tabela user_filiais_cnpj para RLS mapping
--
-- ARQUIVOS RELACIONADOS:
--   - backend/import_getnet.py (ingestão com auto-criação de filiais)
--   - docs/QUALIDADE_DADOS_GETNET.md (análise de qualidade)
--   - database/AJUSTES_SCHEMA_NECESSARIOS.md (justificativa de mudanças)
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

CREATE TYPE status_vinculo AS ENUM (
  'aguardando_validacao',
  'confirmado',
  'rejeitado',
  'manual'
);

-- ============================================================================
-- 2. TABELAS DE DOMÍNIO
-- ============================================================================

-- 2.1. Tabela de Filiais (Dimensão de Negócio)
--
-- MUDANÇA v2: filial_cnpj é agora PRIMARY KEY (em vez de filial_id SERIAL)
-- MOTIVO: CNPJ é o identificador natural, imutável e vem direto do arquivo
-- SEGURANÇA: RLS baseado em filial_cnpj é mais seguro que IDs gerados
--
-- AUTO-CRIAÇÃO:
--   O script import_getnet.py cria filiais automaticamente se não existirem.
--   Preenche com dados mínimos; dados completos devem ser adicionados manualmente.
--   Filiais criadas começam com status ativo=true.
--
CREATE TABLE IF NOT EXISTS filiais (
  filial_cnpj CHAR(14) PRIMARY KEY
    CONSTRAINT ck_filial_cnpj_format CHECK (filial_cnpj ~ '^\d{14}$'),

  codigo_ec VARCHAR(20),  -- Código de Estabelecimento (do Excel, pode ser NULL inicialmente)
  nome_filial VARCHAR(255) NOT NULL DEFAULT '',  -- Auto-preenchido como "Filial [CNPJ]"

  uf CHAR(2),  -- Estado (default: SP, deve ser atualizado manualmente)
  razao_social VARCHAR(255),  -- Razão social completa (preenchimento manual)

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
   Formato: validado por CHECK constraint (^\d{14}$)';

COMMENT ON COLUMN filiais.codigo_ec IS
  'Código de Estabelecimento Comercial (do arquivo GETNET Excel).
   Pode haver múltiplos por filial.';

COMMENT ON COLUMN filiais.nome_filial IS
  'Nome descritivo. Auto-preenchido como "Filial [CNPJ]", deve ser atualizado.';

-- 2.2. Tabela de Mapeamento Usuário → Filiais (para RLS)
--
-- NOVO em v2: user_filiais_cnpj (em vez de user_filiais com filial_id)
-- MOTIVO: RLS baseado em filial_cnpj é mais direto e seguro
--
-- NOTA: Manter ambas durante transição? Ou migrar completamente?
--       Recomendação: Manter user_filiais para compatibilidade, usar user_filiais_cnpj para RLS.
--
CREATE TABLE IF NOT EXISTS user_filiais_cnpj (
  user_filial_id SERIAL PRIMARY KEY,

  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  filial_cnpj CHAR(14) NOT NULL REFERENCES filiais(filial_cnpj) ON DELETE CASCADE,

  perfil VARCHAR(50) NOT NULL DEFAULT 'leitor',  -- leitor, operador, admin

  data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(user_id, filial_cnpj)
);

COMMENT ON TABLE user_filiais_cnpj IS
  'Mapeamento de usuários para filiais (RLS). Usado pelas políticas de Row Level Security.
   Baseado em filial_cnpj (mais seguro que filial_id).';

-- MANTER PARA COMPATIBILIDADE (v1 para v2 transição)
CREATE TABLE IF NOT EXISTS user_filiais (
  user_filial_id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  filial_cnpj CHAR(14) NOT NULL,  -- Referência por CNPJ (não FK para permitir transição)

  perfil VARCHAR(50) NOT NULL DEFAULT 'leitor',
  data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(user_id, filial_cnpj)
);

-- 2.3. Tabela de Transações GETNET (Fatos)
--
-- MUDANÇA v2:
--   - Removido filial_id (usar filial_cnpj como FK para filiais)
--   - filial_cnpj agora CHAR(14) com CHECK constraint
--   - hora_transacao como TIME (coluna separada, não extraída de timestamp)
--   - Documentado que hash é CNPJ-scoped
--
-- DADOS REAIS (arquivo ADTO_23042026.xlsx):
--   - 4.378 Vendas
--   - 1.190 transações únicas (após deduplicação)
--   - 3.188 duplicatas detectadas
--   - 41 filiais (CNPJs únicos)
--   - Valor: R$ 16.769.222,48 (transações únicas)
--
CREATE TABLE IF NOT EXISTS transacoes_getnet (
  transacao_id BIGSERIAL PRIMARY KEY,

  -- Filial (nova estrutura: FK para filiais via CNPJ)
  filial_cnpj CHAR(14) NOT NULL REFERENCES filiais(filial_cnpj),

  -- Identificadores de transação
  nsu VARCHAR(20) NOT NULL,  -- Número Sequencial Único
  numero_autorizacao VARCHAR(20) NOT NULL,  -- Código de autorização

  -- Data e hora (separadas, conforme arquivo Excel)
  data_transacao DATE NOT NULL,
  hora_transacao TIME NOT NULL,  -- MUDANÇA v2: coluna separada (não extraída de timestamp)

  -- Valores
  valor NUMERIC(15, 2) NOT NULL
    CONSTRAINT ck_transacao_valor_positivo CHECK (valor > 0),

  -- Classificação
  bandeira VARCHAR(50) NOT NULL,  -- Visa, Mastercard, Elo, Diners, AMEX, Discover
  codigo_ec VARCHAR(20) NOT NULL,  -- Código de Estabelecimento Comercial
  tipo_lancamento VARCHAR(50) NOT NULL,  -- 'Vendas', 'Negociações', 'Saldo', etc.

  -- Deduplicação e status
  status status_transacao DEFAULT 'pendente',
  hash_transacao VARCHAR(64) UNIQUE,
    -- MUDANÇA v2: Hash = SHA256(filial_cnpj|nsu|numero_autorizacao|valor|data_transacao)
    -- Escopo: por filial (CNPJ-scoped deduplication)
    -- Exemplo: NSU "000001493" pode aparecer em filiais diferentes → NÃO é duplicata

  eh_duplicata BOOLEAN DEFAULT false,  -- Flag: TRUE se rejeitada como duplicata

  -- Auditoria
  data_ingesta TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Constraints de unicidade (por filial)
  UNIQUE(filial_cnpj, nsu, numero_autorizacao, data_transacao),

  -- Rejeitar duplicatas: mesmo hash não pode aparecer 2x
  UNIQUE(hash_transacao)
);

COMMENT ON TABLE transacoes_getnet IS
  'Transações de cartão de crédito (adquirente GETNET).
   Cada linha = uma transação de vendas.
   Fatos de um modelo de reconciliação.

   Dados reais (ADTO_23042026.xlsx):
   - 4.378 vendas (antes dedup)
   - 1.190 únicas (após dedup)
   - 3.188 duplicatas (mesma transação em múltiplas linhas)
   - 41 filiais (CNPJs)
   - R$ 16.769.222,48 valor total (transações únicas)';

COMMENT ON COLUMN transacoes_getnet.filial_cnpj IS
  'CNPJ da filial (FK para filiais). CHAR(14), sem formatação.
   Chave de isolamento para RLS.';

COMMENT ON COLUMN transacoes_getnet.hash_transacao IS
  'SHA256(filial_cnpj||"|"||nsu||"|"||numero_autorizacao||"|"||valor||"|"||data_transacao).
   Detecta duplicatas genuínas (mesma transação em múltiplas linhas).
   Escopo: por filial (CNPJ-scoped). Transações de filiais diferentes com mesmo NSU
   são VÁLIDAS (não são duplicatas).
   Exemplo: Filial A (NSU 000001493) ≠ Filial B (NSU 000001493).';

COMMENT ON COLUMN transacoes_getnet.hora_transacao IS
  'Horário da transação (HH:MM:SS). Coluna separada (não extraída de timestamp).
   MUDANÇA v2: Extraído de coluna HORA DA VENDA do Excel (não de timestamp).
   Problema v1: Timestamp do Excel é sempre 00:00:00, hora real fica perdida.';

COMMENT ON COLUMN transacoes_getnet.eh_duplicata IS
  'Flag de duplicata. TRUE se transação foi rejeitada por hash duplicado.
   Útil para auditoria: marca quais registros foram rejeitados como duplicatas.';

-- 2.4. Tabela de Títulos TOTVS (Fatos do ERP)
--
-- Sem mudanças significativas em v2 (FK ajustado para usar filial_cnpj)
--
CREATE TABLE IF NOT EXISTS titulos_totvs (
  titulo_id BIGSERIAL PRIMARY KEY,

  -- Filial (nova estrutura: FK via filial_cnpj)
  filial_cnpj CHAR(14) NOT NULL REFERENCES filiais(filial_cnpj),

  -- Identificadores
  numero_titulo VARCHAR(30) NOT NULL,
  numero_nf VARCHAR(20),
  serie_nf VARCHAR(10),

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

  -- Status e auditoria
  status status_titulo DEFAULT 'pendente',
  data_ingesta TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Constraints
  UNIQUE(filial_cnpj, numero_titulo)
);

COMMENT ON TABLE titulos_totvs IS
  'Títulos a receber do sistema ERP TOTVS.
   Cada linha = uma nota fiscal ou venda registrada no ERP.
   Fatos de um modelo de reconciliação.';

-- 2.5. Tabela de Conciliação (Vinculação N:N)
--
-- MUDANÇA v2: FK ajustado para usar filial_cnpj
-- Vincula transações GETNET com títulos TOTVS
-- Suporta: 1 transação → N títulos (parcelado)
--          N transações → 1 título (múltiplos cartões)
--          Divergências com scoring de confiança
--
CREATE TABLE IF NOT EXISTS conciliacao_vinculos (
  vinculo_id BIGSERIAL PRIMARY KEY,

  -- Filial (isolamento RLS)
  filial_cnpj CHAR(14) NOT NULL REFERENCES filiais(filial_cnpj),

  -- Vinculação (foreign keys)
  transacao_getnet_id BIGINT NOT NULL REFERENCES transacoes_getnet(transacao_id) ON DELETE CASCADE,
  titulo_totvs_id BIGINT NOT NULL REFERENCES titulos_totvs(titulo_id) ON DELETE CASCADE,

  -- Análise de matching
  diferenca_valor NUMERIC(15, 2) NOT NULL DEFAULT 0,
  diferenca_dias SMALLINT NOT NULL DEFAULT 0,
  score_confianca NUMERIC(3, 2) NOT NULL DEFAULT 0.00
    CONSTRAINT ck_score_entre_0_e_1 CHECK (score_confianca BETWEEN 0 AND 1),

  -- Motivo da rejeição (se houver)
  motivo_rejeicao VARCHAR(255),

  -- Status e auditoria
  status status_vinculo DEFAULT 'aguardando_validacao',
  usuario_validacao VARCHAR(100),
  data_validacao TIMESTAMP WITH TIME ZONE,
  data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Constraints
  UNIQUE(transacao_getnet_id, titulo_totvs_id)
);

COMMENT ON TABLE conciliacao_vinculos IS
  'Tabela de ligação para reconciliação entre GETNET e TOTVS.
   Resolução de N:N entre transações_getnet e titulos_totvs.
   Suporta parcelamentos (1 transação → N títulos) e múltiplos cartões (N → 1).
   Score de confiança ajuda a resolver ambiguidades automaticamente.';

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

-- Índices em conciliacao_vinculos
CREATE INDEX idx_conciliacao_vinculos_filial_cnpj
  ON conciliacao_vinculos(filial_cnpj);

CREATE INDEX idx_conciliacao_vinculos_status
  ON conciliacao_vinculos(status);

CREATE INDEX idx_conciliacao_vinculos_score
  ON conciliacao_vinculos(score_confianca DESC);

-- ============================================================================
-- 4. ROW LEVEL SECURITY (RLS) - SEGURANÇA POR FILIAL
-- ============================================================================
-- MUDANÇA v2: Todas as políticas usam filial_cnpj (não filial_id)
-- MOTIVO: Mais direto, seguro e alinhado com dados do arquivo
--
-- COMO FUNCIONA:
--   1. Usuário faz query: SELECT * FROM transacoes_getnet
--   2. RLS adiciona automaticamente: AND filial_cnpj IN (
--        SELECT filial_cnpj FROM user_filiais_cnpj WHERE user_id = auth.uid()
--      )
--   3. Usuário vê APENAS dados de suas filiais autorizadas
--

-- Habilitar RLS nas tabelas
ALTER TABLE filiais ENABLE ROW LEVEL SECURITY;
ALTER TABLE transacoes_getnet ENABLE ROW LEVEL SECURITY;
ALTER TABLE titulos_totvs ENABLE ROW LEVEL SECURITY;
ALTER TABLE conciliacao_vinculos ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filiais_cnpj ENABLE ROW LEVEL SECURITY;

-- Política: Filiais - Usuário vê apenas filiais autorizadas
CREATE POLICY rls_filiais_own
  ON filiais FOR ALL
  USING (
    filial_cnpj IN (
      SELECT filial_cnpj FROM user_filiais_cnpj WHERE user_id = auth.uid()
    )
  );

-- Política: Transações GETNET - Usuário vê apenas de suas filiais
CREATE POLICY rls_transacoes_getnet_own
  ON transacoes_getnet FOR ALL
  USING (
    filial_cnpj IN (
      SELECT filial_cnpj FROM user_filiais_cnpj WHERE user_id = auth.uid()
    )
  );

-- Política: Títulos TOTVS - Usuário vê apenas de suas filiais
CREATE POLICY rls_titulos_totvs_own
  ON titulos_totvs FOR ALL
  USING (
    filial_cnpj IN (
      SELECT filial_cnpj FROM user_filiais_cnpj WHERE user_id = auth.uid()
    )
  );

-- Política: Conciliação - Usuário vê apenas de suas filiais
CREATE POLICY rls_conciliacao_vinculos_own
  ON conciliacao_vinculos FOR ALL
  USING (
    filial_cnpj IN (
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

-- Trigger: Atualizar timestamp automaticamente
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

-- Função: Calcular score de matching (automático para conciliação)
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
-- 7. DADOS INICIAIS (EXEMPLO)
-- ============================================================================

-- Inserir filiais de exemplo (comentado - usar import_getnet.py para dados reais)
/*
INSERT INTO filiais (filial_cnpj, codigo_ec, nome_filial, uf, razao_social, ativo)
VALUES
  ('84943067000150', 'EC001', 'Filial São Paulo - Matriz', 'SP', 'EMPRESA HOLDING S/A', true),
  ('84943067000230', 'EC002', 'Filial Rio de Janeiro', 'RJ', 'EMPRESA HOLDING S/A', true),
  ('84943067000311', 'EC003', 'Filial Minas Gerais', 'MG', 'EMPRESA HOLDING S/A', true)
ON CONFLICT (filial_cnpj) DO NOTHING;
*/

-- ============================================================================
-- 8. DOCUMENTAÇÃO E METADADOS
-- ============================================================================

COMMENT ON SCHEMA public IS
  'Schema Nexus v2.0 - Sistema de Reconciliação de Cartões de Crédito.

   PRINCIPAIS MUDANÇAS v1 → v2:
   1. RLS baseado em filial_cnpj (CHAR 14) em vez de filial_id (INTEGER)
   2. filial_cnpj é PRIMARY KEY natural (em vez de SERIAL filial_id)
   3. CHECK constraint para CNPJ (^\d{14}$)
   4. Hash transacao é CNPJ-scoped (inclui CNPJ no cálculo)
   5. hora_transacao como TIME separada (não extraída de timestamp)
   6. Auto-criação de filiais pelo import_getnet.py
   7. Suporte para 41 filiais (CNPJs) reais

   RELACIONAMENTOS:
   - filiais (dimensão): PK = filial_cnpj
   - transacoes_getnet (fatos): FK = filial_cnpj
   - titulos_totvs (fatos): FK = filial_cnpj
   - conciliacao_vinculos (ligação): FK = filial_cnpj
   - user_filiais_cnpj (RLS): FK = filial_cnpj

   RLS SECURITY:
   - Todas as políticas usam filial_cnpj
   - Usuários veem apenas dados de suas filiais autorizadas
   - Controle via tabela user_filiais_cnpj

   DEDUPLICAÇÃO:
   - Hash = SHA256(filial_cnpj|nsu|numero_autorizacao|valor|data_transacao)
   - Escopo: por filial (CNPJ-scoped)
   - Rejeita duplicatas genuínas (mesma transação em múltiplas linhas)
   - Exemplo real: 4.378 vendas → 1.190 únicas (3.188 duplicatas)

   REFERÊNCIAS:
   - backend/import_getnet.py (v2.1): ingestão com auto-criação
   - docs/QUALIDADE_DADOS_GETNET.md: análise de qualidade
   - database/AJUSTES_SCHEMA_NECESSARIOS.md: justificativa de mudanças
  ';

-- ============================================================================
-- FIM DO SCHEMA
-- ============================================================================
-- Data: 2026-04-24
-- Status: ✅ PRONTO PARA APLICAR NO SUPABASE (primeira vez)
-- Próximo: Validar checklist antes de executar
-- ============================================================================
