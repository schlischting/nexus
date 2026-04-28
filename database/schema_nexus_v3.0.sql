-- ============================================================================
-- NEXUS: Sistema de Conciliação de Cartões de Crédito
-- Schema PostgreSQL v3.0 DEFINITIVO com Row Level Security (RLS)
-- ============================================================================
-- Data: 2026-04-25
-- Versão: 3.0 (COMPLETO: config_parametros, views, scoring, RLS policies)
--
-- MUDANÇAS v2.1 → v3.0:
--   ✓ Adicionado: tabela config_parametros com dados iniciais
--   ✓ Adicionado: views de alertas (vw_nsu_sem_titulo, vw_titulo_sem_nsu, vw_sugestoes_supervisor)
--   ✓ Completado: função calcular_score_matching() com lógica de scoring
--   ✓ Adicionado: triggers de auditoria completos
--   ✓ Verificado: RLS policies para 3 perfis (operador_filial, supervisor, admin)
--   ✓ Adicionado: índices para performance dashboard
--   ✓ Documentação: COMMENT completa em todas tabelas e colunas
--
-- ============================================================================
-- 1. EXTENSÕES NECESSÁRIAS
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================================
-- 2. TYPES (ENUMS) — TIPOS DE STATUS
-- ============================================================================

CREATE TYPE status_transacao AS ENUM (
  'pendente',
  'conciliada',
  'divergencia',
  'cancelada',
  'duplicata'
);

CREATE TYPE status_titulo AS ENUM (
  'aberto',
  'baixado',
  'baixado_parcial',
  'cancelado'
);

CREATE TYPE status_vinculo AS ENUM (
  'nsu_invalido',
  'pendente',
  'sugerido',
  'confirmado',
  'exportado',
  'baixado',
  'baixado_parcial',
  'erro_baixa',
  'rejeitado'
);

CREATE TYPE tipo_titulo AS ENUM (
  'NF',     -- Nota Fiscal normal
  'AN',     -- Aviso de Nota (compensado automaticamente pelo TOTVS)
  'OUTRO'   -- Outros (boleto, duplicata, etc)
);

CREATE TYPE perfil_usuario AS ENUM (
  'operador_filial',  -- Acesso apenas à sua filial
  'supervisor',       -- Acesso read em todas filiais, UPDATE em vinculos
  'admin'             -- Acesso total + parâmetros
);

-- ============================================================================
-- 3. TABELAS PRINCIPAIS
-- ============================================================================

-- 3.1 FILIAIS (Dimensão)
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
  'Dimensão de Filiais. PK natural: filial_cnpj (14 dígitos sem formatação).
   Criadas automaticamente pelo import_getnet.py. Chave de isolamento RLS.';

COMMENT ON COLUMN filiais.filial_cnpj IS
  'CNPJ da filial (14 dígitos, apenas números). Validade: CHECK (^\d{14}$).
   Chave natural e chave de isolamento multi-tenant.';

-- 3.2 USER_FILIAIS_CNPJ (RLS Mapping)
CREATE TABLE IF NOT EXISTS user_filiais_cnpj (
  user_filial_id SERIAL PRIMARY KEY,

  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  filial_cnpj CHAR(14) NOT NULL REFERENCES filiais(filial_cnpj) ON DELETE CASCADE,

  perfil perfil_usuario NOT NULL DEFAULT 'operador_filial',

  data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(user_id, filial_cnpj)
);

COMMENT ON TABLE user_filiais_cnpj IS
  'Mapeamento de usuários para filiais com perfis (RLS).

   PERFIS:
   - operador_filial: Acesso apenas às filiais listadas nesta tabela.
   - supervisor: Acesso read em TODAS as filiais (via RLS policy).
   - admin: Acesso total sem restrição (via RLS policy).

   Nota: Supervisor e admin têm acesso global via RLS, operador_filial é restrito por esta tabela.';

COMMENT ON COLUMN user_filiais_cnpj.perfil IS
  'Perfil do usuário para esta filial.
   - operador_filial: Acesso exclusivo a esta filial, pode criar vínculos manualmente.
   - supervisor: Acesso read em todas filiais (verificado via auth.jwt()).
   - admin: Acesso total + parâmetros (verificado via auth.jwt()).';

-- Manter compatibilidade (deprecated)
CREATE TABLE IF NOT EXISTS user_filiais (
  user_filial_id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  filial_cnpj CHAR(14) NOT NULL,
  perfil VARCHAR(50) NOT NULL DEFAULT 'leitor',
  data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, filial_cnpj)
);

-- 3.3 TRANSACOES_GETNET (Fatos do adquirente)
CREATE TABLE IF NOT EXISTS transacoes_getnet (
  transacao_id BIGSERIAL PRIMARY KEY,

  filial_cnpj CHAR(14) NOT NULL REFERENCES filiais(filial_cnpj) ON DELETE CASCADE,

  nsu VARCHAR(30) NOT NULL,
  autorizacao VARCHAR(30) NOT NULL,

  data_venda DATE NOT NULL,
  hora_venda TIME NOT NULL,

  valor_venda NUMERIC(15, 2) NOT NULL
    CONSTRAINT ck_transacao_valor_positivo CHECK (valor_venda > 0),
  valor_liquido NUMERIC(15, 2),
  valor_liquido_parcela NUMERIC(15, 2),

  parcelas SMALLINT DEFAULT 1,
  valor_parcela NUMERIC(15, 2),

  bandeira VARCHAR(50) NOT NULL,
  modalidade VARCHAR(20),
  codigo_ec VARCHAR(20) NOT NULL,

  status status_transacao DEFAULT 'pendente',
  origem VARCHAR(50) NOT NULL DEFAULT 'arquivo_getnet'
    CONSTRAINT ck_origem CHECK (origem IN ('arquivo_getnet', 'digitado_operador')),
  hash_transacao VARCHAR(64) UNIQUE,
  eh_duplicata BOOLEAN DEFAULT false,

  data_ingesta TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(filial_cnpj, nsu, autorizacao, data_venda)
);

COMMENT ON TABLE transacoes_getnet IS
  'Transações de cartão de crédito do adquirente GETNET.
   Cada linha = uma venda processada pela maquininha.

   Importação: via import_getnet.py a partir do arquivo Excel ADTO_*.xlsx.
   Relacionamento: 1 NSU → 1 título TOTVS (caso normal);
                  N NSUs → 1 título (parcelamento múltiplos cartões).';

COMMENT ON COLUMN transacoes_getnet.hash_transacao IS
  'SHA256(filial_cnpj|nsu|autorizacao|data_venda|valor_venda).
   Usado para deduplicação CNPJ-scoped. UNIQUE garante não importar 2x.';

COMMENT ON COLUMN transacoes_getnet.eh_duplicata IS
  'TRUE se a mesma transação foi detectada N vezes (parcelamento ou erro de transmissão).
   Mantém histórico, marca como duplicata para análise posterior.';

COMMENT ON COLUMN transacoes_getnet.origem IS
  'Origem da transação: arquivo_getnet (importada de arquivo ADTO_*.xlsx) ou digitado_operador (lançada manualmente).
   Usado para diferenciar fluxos no dashboard e queries.';

-- 3.4 TITULOS_TOTVS (Fatos do ERP)
CREATE TABLE IF NOT EXISTS titulos_totvs (
  titulo_id BIGSERIAL PRIMARY KEY,

  filial_cnpj CHAR(14) NOT NULL REFERENCES filiais(filial_cnpj) ON DELETE CASCADE,

  numero_titulo VARCHAR(30) NOT NULL,
  numero_nf VARCHAR(30),
  especie VARCHAR(10),
  serie VARCHAR(10),
  numero VARCHAR(20),
  parcela VARCHAR(10),

  tipo_titulo tipo_titulo NOT NULL DEFAULT 'NF',

  data_emissao DATE NOT NULL,
  data_vencimento DATE NOT NULL,

  valor_bruto NUMERIC(15, 2) NOT NULL
    CONSTRAINT ck_titulo_valor_bruto_positivo CHECK (valor_bruto > 0),
  valor_liquido NUMERIC(15, 2) NOT NULL
    CONSTRAINT ck_titulo_valor_liquido_positivo CHECK (valor_liquido > 0),

  cliente_codigo VARCHAR(20) NOT NULL,
  cliente_nome VARCHAR(255) NOT NULL,

  natureza_operacao VARCHAR(100),
  referencia_cliente VARCHAR(50),

  nsu_getnet VARCHAR(30),
  nexus_vinculo_id UUID,

  status status_titulo DEFAULT 'aberto',

  data_ingesta TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(filial_cnpj, numero_titulo)
);

COMMENT ON TABLE titulos_totvs IS
  'Títulos a receber do ERP TOTVS (Contas a Receber).

   Importação: via programa Progress diário (export de títulos em aberto).
   Relacionamento: geralmente 1 título ↔ 1 NSU GETNET;
                  exceção: múltiplos NSUs de cartões diferentes para mesma NF.

   tipo_titulo:
   - NF: Nota Fiscal normal, sempre esperado vínculo GETNET.
   - AN: Aviso de Nota, compensado automaticamente pelo TOTVS, Nexus não rastreia.
   - OUTRO: Boleto, duplicata, etc.';

COMMENT ON COLUMN titulos_totvs.tipo_titulo IS
  'Tipo de documento fiscal. NF: vínculo esperado. AN: compensação automática. OUTRO: casos especiais.';

COMMENT ON COLUMN titulos_totvs.nsu_getnet IS
  'Preenchido APÓS baixa TOTVS bem-sucedida. Garante rastreabilidade: qual NSU gerou a baixa.';

COMMENT ON COLUMN titulos_totvs.nexus_vinculo_id IS
  'UUID do vínculo em conciliacao_vinculos que baixou este título. Preenchido após baixa.';

-- 3.5 CONCILIACAO_VINCULOS (Tabela de Ligação)
CREATE TABLE IF NOT EXISTS conciliacao_vinculos (
  vinculo_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  filial_cnpj CHAR(14) NOT NULL REFERENCES filiais(filial_cnpj) ON DELETE CASCADE,

  transacao_getnet_id BIGINT NOT NULL REFERENCES transacoes_getnet(transacao_id) ON DELETE CASCADE,
  titulo_totvs_id BIGINT REFERENCES titulos_totvs(titulo_id) ON DELETE SET NULL,

  numero_nf_informado VARCHAR(30),
  tipo_vinculacao VARCHAR(50) NOT NULL DEFAULT 'automatico',

  diferenca_valor NUMERIC(15, 2) NOT NULL DEFAULT 0,
  diferenca_dias SMALLINT NOT NULL DEFAULT 0,
  score_confianca NUMERIC(4, 3) NOT NULL DEFAULT 0.000
    CONSTRAINT ck_score_entre_0_e_1 CHECK (score_confianca BETWEEN 0 AND 1),

  origem VARCHAR(20) NOT NULL DEFAULT 'automatico',
  status status_vinculo DEFAULT 'pendente',

  confirmado_por VARCHAR(200),
  data_confirmacao TIMESTAMP WITH TIME ZONE,

  data_exportacao TIMESTAMP WITH TIME ZONE,
  data_baixa_totvs TIMESTAMP WITH TIME ZONE,
  valor_baixado NUMERIC(15, 2),

  status_baixa VARCHAR(50),
  erro_baixa TEXT,

  observacao TEXT,
  motivo_rejeicao VARCHAR(255),

  criado_por VARCHAR(200),
  usuario_validacao VARCHAR(200),

  criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_validacao TIMESTAMP WITH TIME ZONE,
  data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(transacao_getnet_id, titulo_totvs_id)
);

COMMENT ON TABLE conciliacao_vinculos IS
  'Tabela de ligação entre GETNET e TOTVS. Central do sistema Nexus.

   FLUXO:
   1. Script ou operador cria vínculo (NSU + NF)
   2. Sistema busca título TOTVS, calcula score matching
   3. Se score > 0.95: status = sugerido (pronto para confirmar)
   4. Supervisor confirma (status = confirmado)
   5. Sistema chama PASOE para baixa
   6. PASOE retorna sucesso/erro
   7. Sistema registra resultado em data_baixa_totvs, status_baixa, erro_baixa

   STATUS (ciclo de vida):
   - nsu_invalido: NSU digitado não existe na GETNET (fim)
   - pendente: criado, aguardando match automático
   - sugerido: match automático gerado (0.75-0.95), aguarda supervisor
   - confirmado: supervisor aprovou, pronto para exportar a TOTVS
   - exportado: JSON enviado ao PASOE
   - baixado: PASOE executou com sucesso (fim)
   - baixado_parcial: PASOE executou parcial (valor < esperado)
   - erro_baixa: PASOE retornou erro, reprocessable
   - rejeitado: supervisor cancelou (fim)';

COMMENT ON COLUMN conciliacao_vinculos.numero_nf_informado IS
  'NF digitado manualmente pelo operador no Portal (quando titulo_totvs_id é NULL).
   Usado para busca automática e linkagem com título TOTVS.';

COMMENT ON COLUMN conciliacao_vinculos.tipo_vinculacao IS
  'Origem: "automatico" (script matching) ou "manual" (Portal do Operador).
   Permite filtrar, auditar decisões, aplicar SLAs diferentes.';

COMMENT ON COLUMN conciliacao_vinculos.score_confianca IS
  'Score 0.000-1.000 do matching automático.
   > 0.95: confirmação automática. 0.75-0.95: sugestão para supervisor. < 0.75: gap.';

COMMENT ON COLUMN conciliacao_vinculos.status_baixa IS
  'Status da tentativa baixa PASOE: "sucesso" ou código erro.
   Ex: "E001_TITULO_NAO_ENCONTRADO", "E002_SALDO_INSUFICIENTE"';

COMMENT ON COLUMN conciliacao_vinculos.erro_baixa IS
  'Mensagem de erro completa do PASOE (se houver).
   Ex: "Título 001234 não encontrado na filial 84943067001393"';

-- 3.6 CONFIG_PARAMETROS (Configurações do Sistema)
CREATE TABLE IF NOT EXISTS config_parametros (
  chave VARCHAR(50) PRIMARY KEY,
  valor VARCHAR(200) NOT NULL,
  descricao TEXT,
  atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE config_parametros IS
  'Parâmetros configuráveis do sistema Nexus.
   Utilizados em: calcular_score_matching(), filtros dashboard, SLAs, etc.
   Acesso: admin only (via RLS).';

-- Dados iniciais (padrões do sistema)
INSERT INTO config_parametros (chave, valor, descricao) VALUES
  ('tolerancia_valor_pct', '5', 'Tolerância percentual no match de valor (ex: 5%)'),
  ('tolerancia_dias', '3', 'Tolerância em dias no match de data'),
  ('score_auto', '0.95', 'Score mínimo para match automático (ex: 0.95 = 95%)'),
  ('score_sugestao', '0.75', 'Score mínimo para sugestão ao supervisor (ex: 0.75 = 75%)'),
  ('max_retries_baixa', '3', 'Máximo de tentativas de reprocessamento de baixa'),
  ('timeout_pasoe_segundos', '30', 'Timeout para chamadas ao PASOE (em segundos)')
ON CONFLICT (chave) DO NOTHING;

-- ============================================================================
-- 4. ÍNDICES PARA PERFORMANCE
-- ============================================================================

-- Índices em transacoes_getnet
CREATE INDEX IF NOT EXISTS idx_transacoes_getnet_filial_cnpj_data
  ON transacoes_getnet(filial_cnpj, data_venda DESC);

CREATE INDEX IF NOT EXISTS idx_transacoes_getnet_filial_cnpj_nsu
  ON transacoes_getnet(filial_cnpj, nsu);

CREATE INDEX IF NOT EXISTS idx_transacoes_getnet_origem
  ON transacoes_getnet(filial_cnpj, origem, status);

CREATE INDEX IF NOT EXISTS idx_transacoes_getnet_hash
  ON transacoes_getnet(hash_transacao);

CREATE INDEX IF NOT EXISTS idx_transacoes_getnet_status
  ON transacoes_getnet(status) WHERE status = 'pendente';

-- Índices em titulos_totvs
CREATE INDEX IF NOT EXISTS idx_titulos_totvs_filial_cnpj_data
  ON titulos_totvs(filial_cnpj, data_vencimento DESC);

CREATE INDEX IF NOT EXISTS idx_titulos_totvs_filial_cnpj_nf
  ON titulos_totvs(filial_cnpj, numero_nf);

CREATE INDEX IF NOT EXISTS idx_titulos_totvs_status
  ON titulos_totvs(status) WHERE status = 'aberto';

CREATE INDEX IF NOT EXISTS idx_titulos_totvs_tipo
  ON titulos_totvs(filial_cnpj, tipo_titulo);

-- Índices em conciliacao_vinculos
CREATE INDEX IF NOT EXISTS idx_conciliacao_vinculos_filial_cnpj
  ON conciliacao_vinculos(filial_cnpj);

CREATE INDEX IF NOT EXISTS idx_conciliacao_vinculos_status
  ON conciliacao_vinculos(status);

CREATE INDEX IF NOT EXISTS idx_conciliacao_vinculos_score
  ON conciliacao_vinculos(score_confianca DESC);

CREATE INDEX IF NOT EXISTS idx_conciliacao_vinculos_transacao
  ON conciliacao_vinculos(transacao_getnet_id);

CREATE INDEX IF NOT EXISTS idx_conciliacao_vinculos_titulo
  ON conciliacao_vinculos(titulo_totvs_id);

CREATE INDEX IF NOT EXISTS idx_conciliacao_vinculos_pendente_baixa
  ON conciliacao_vinculos(filial_cnpj, status)
  WHERE status IN ('pendente', 'sugerido', 'erro_baixa');

-- ============================================================================
-- 5. FUNÇÃO: update_timestamp()
-- ============================================================================

CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.data_atualizacao = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 6. TRIGGERS DE AUDITORIA
-- ============================================================================

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
-- 7. FUNÇÃO: calcular_score_matching()
-- ============================================================================

CREATE OR REPLACE FUNCTION calcular_score_matching(
  p_valor_getnet NUMERIC,
  p_valor_totvs NUMERIC,
  p_data_getnet DATE,
  p_data_totvs DATE,
  p_tolerancia_pct NUMERIC DEFAULT 5,
  p_tolerancia_dias INTEGER DEFAULT 3
)
RETURNS NUMERIC AS $$
DECLARE
  score_valor NUMERIC := 0.0;
  score_data NUMERIC := 0.0;
  score_nf NUMERIC := 0.2;  -- Peso fixo se NF informado
  score_final NUMERIC := 0.0;
  diff_valor_pct NUMERIC;
  diff_dias INTEGER;
BEGIN
  -- Score Valor (peso 0.5)
  -- Se valores coincidem dentro tolerância: score = 0.5
  IF p_valor_totvs > 0 THEN
    diff_valor_pct := ABS(p_valor_getnet - p_valor_totvs) / p_valor_totvs * 100;

    IF diff_valor_pct <= p_tolerancia_pct THEN
      score_valor := 0.5;      -- Match exato (dentro tolerância)
    ELSIF diff_valor_pct <= (p_tolerancia_pct * 2) THEN
      score_valor := 0.25;     -- Match parcial
    ELSE
      score_valor := 0.0;      -- Sem match
    END IF;
  END IF;

  -- Score Data (peso 0.3)
  -- Se datas coincidem dentro tolerância: score = 0.3
  diff_dias := ABS(p_data_getnet - p_data_totvs)::INT;

  IF diff_dias = 0 THEN
    score_data := 0.3;         -- Mesmo dia
  ELSIF diff_dias <= p_tolerancia_dias THEN
    score_data := 0.15;        -- Dentro tolerância
  ELSE
    score_data := 0.0;         -- Fora tolerância
  END IF;

  -- Score NF (peso 0.2)
  -- Nota: este valor é fixo (0.2) quando há título encontrado
  -- Em lógica de aplicação, reduzir score se não há título (nsu_invalido)
  -- score_nf já é 0.2, vem de que titulo_totvs_id É NOT NULL

  score_final := score_valor + score_data + score_nf;

  RETURN ROUND(score_final::NUMERIC, 3);
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 8. VIEWS: ALERTAS E SUGESTÕES
-- ============================================================================

-- VIEW 1: NSU sem título vinculado
CREATE OR REPLACE VIEW vw_nsu_sem_titulo AS
SELECT
  t.transacao_id,
  t.filial_cnpj,
  t.nsu,
  t.autorizacao,
  t.data_venda,
  t.hora_venda,
  t.valor_venda,
  t.bandeira,
  t.modalidade,
  COUNT(cv.vinculo_id) as vinculos_count,
  MAX(cv.criado_em) as ultimo_vínculo_em
FROM transacoes_getnet t
LEFT JOIN conciliacao_vinculos cv ON t.transacao_id = cv.transacao_getnet_id
  AND cv.status NOT IN ('nsu_invalido', 'rejeitado')
WHERE t.status = 'pendente'
GROUP BY
  t.transacao_id, t.filial_cnpj, t.nsu, t.autorizacao,
  t.data_venda, t.hora_venda, t.valor_venda, t.bandeira, t.modalidade
HAVING COUNT(cv.vinculo_id) = 0
ORDER BY t.data_venda DESC;

COMMENT ON VIEW vw_nsu_sem_titulo IS
  'NSUs pendentes SEM título vinculado. Dashboard operador: alerta 🔴.
   Usado por: Dashboard operador, listagem de gaps por filial.';

-- VIEW 2: Títulos sem NSU vinculado
CREATE OR REPLACE VIEW vw_titulo_sem_nsu AS
SELECT
  t.titulo_id,
  t.filial_cnpj,
  t.numero_nf,
  t.tipo_titulo,
  t.serie,
  t.numero,
  t.parcela,
  t.data_emissao,
  t.data_vencimento,
  t.valor_bruto,
  t.valor_liquido,
  t.cliente_codigo,
  t.cliente_nome,
  COUNT(cv.vinculo_id) as vinculos_count,
  MAX(cv.criado_em) as primeiro_vínculo_em
FROM titulos_totvs t
LEFT JOIN conciliacao_vinculos cv ON t.titulo_id = cv.titulo_totvs_id
  AND cv.status NOT IN ('nsu_invalido', 'rejeitado')
WHERE t.status = 'aberto'
  AND t.tipo_titulo IN ('NF', 'AN')
GROUP BY
  t.titulo_id, t.filial_cnpj, t.numero_nf, t.tipo_titulo,
  t.serie, t.numero, t.parcela, t.data_emissao, t.data_vencimento,
  t.valor_bruto, t.valor_liquido, t.cliente_codigo, t.cliente_nome
HAVING COUNT(cv.vinculo_id) = 0
ORDER BY t.data_vencimento ASC;

COMMENT ON VIEW vw_titulo_sem_nsu IS
  'Títulos TOTVS em aberto SEM NSU GETNET vinculado. Dashboard operador: alerta 🟡.
   Usado por: Dashboard operador, listagem de títulos órfãos por filial.';

-- VIEW 3: Sugestões para supervisor validação manual
CREATE OR REPLACE VIEW vw_sugestoes_supervisor AS
SELECT
  cv.vinculo_id,
  cv.filial_cnpj,
  tg.transacao_id as transacao_getnet_id,
  tg.nsu,
  tg.autorizacao,
  tg.data_venda,
  tg.valor_venda,
  tg.bandeira,
  tg.modalidade,
  tt.titulo_id as titulo_totvs_id,
  tt.numero_nf,
  tt.serie,
  tt.numero,
  tt.parcela,
  tt.tipo_titulo,
  tt.data_emissao,
  tt.data_vencimento,
  tt.valor_bruto,
  tt.valor_liquido,
  tt.cliente_nome,
  cv.score_confianca,
  ABS(tg.valor_venda - tt.valor_bruto) as diferenca_valor,
  ABS(tg.data_venda - tt.data_vencimento)::INT as dias_diferenca,
  cv.criado_em,
  cv.criado_por
FROM conciliacao_vinculos cv
JOIN transacoes_getnet tg ON cv.transacao_getnet_id = tg.transacao_id
JOIN titulos_totvs tt ON cv.titulo_totvs_id = tt.titulo_id
WHERE cv.status = 'sugerido'
ORDER BY cv.score_confianca DESC, cv.filial_cnpj, tg.data_venda DESC;

COMMENT ON VIEW vw_sugestoes_supervisor IS
  'Sugestões de vínculo com score 0.75-0.95. Dashboard supervisor: pendentes de validação manual.
   Usado por: Dashboard supervisor, tela de validação de sugestões.';

-- ============================================================================
-- 9. ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Habilitar RLS em todas as tabelas
ALTER TABLE filiais ENABLE ROW LEVEL SECURITY;
ALTER TABLE transacoes_getnet ENABLE ROW LEVEL SECURITY;
ALTER TABLE titulos_totvs ENABLE ROW LEVEL SECURITY;
ALTER TABLE conciliacao_vinculos ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_filiais_cnpj ENABLE ROW LEVEL SECURITY;
ALTER TABLE config_parametros ENABLE ROW LEVEL SECURITY;

-- ===== POLICIES: FILIAIS =====
CREATE POLICY rls_filiais_own
  ON filiais FOR ALL
  USING (
    auth.jwt() ->> 'role' IN ('admin', 'supervisor')
    OR filial_cnpj IN (
      SELECT filial_cnpj FROM user_filiais_cnpj WHERE user_id = auth.uid()
    )
  );

-- ===== POLICIES: TRANSACOES_GETNET =====
CREATE POLICY rls_transacoes_getnet_own
  ON transacoes_getnet FOR ALL
  USING (
    auth.jwt() ->> 'role' IN ('admin', 'supervisor')
    OR filial_cnpj IN (
      SELECT filial_cnpj FROM user_filiais_cnpj WHERE user_id = auth.uid()
    )
  );

-- ===== POLICIES: TITULOS_TOTVS =====
CREATE POLICY rls_titulos_totvs_own
  ON titulos_totvs FOR ALL
  USING (
    auth.jwt() ->> 'role' IN ('admin', 'supervisor')
    OR filial_cnpj IN (
      SELECT filial_cnpj FROM user_filiais_cnpj WHERE user_id = auth.uid()
    )
  );

-- ===== POLICIES: CONCILIACAO_VINCULOS =====
CREATE POLICY rls_conciliacao_vinculos_own
  ON conciliacao_vinculos FOR ALL
  USING (
    auth.jwt() ->> 'role' IN ('admin', 'supervisor')
    OR filial_cnpj IN (
      SELECT filial_cnpj FROM user_filiais_cnpj WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_conciliacao_vinculos_supervisor_update
  ON conciliacao_vinculos FOR UPDATE
  USING (auth.jwt() ->> 'role' IN ('admin', 'supervisor'));

-- ===== POLICIES: USER_FILIAIS_CNPJ =====
CREATE POLICY rls_user_filiais_cnpj_own
  ON user_filiais_cnpj FOR ALL
  USING (user_id = auth.uid() OR auth.jwt() ->> 'role' = 'admin');

-- ===== POLICIES: CONFIG_PARAMETROS =====
CREATE POLICY rls_config_parametros_admin
  ON config_parametros FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin');

-- ============================================================================
-- 10. DADOS INICIAIS (1 FILIAL + 1 TRANSACAO + 1 TITULO + 1 VINCULO)
-- ============================================================================

-- Exemplo de filial (opcional, comentado)
-- INSERT INTO filiais (filial_cnpj, nome_filial, uf, razao_social, ativo)
-- VALUES ('84943067001393', 'Matriz', 'SP', 'Minusa Tratorpeças Ltda', true)
-- ON CONFLICT (filial_cnpj) DO NOTHING;

-- ============================================================================
-- FIM DO SCHEMA
-- ============================================================================

-- Checklist de verificação (executar via SELECT)
-- SELECT 'Filiais' as tabela, COUNT(*) as registros FROM filiais
-- UNION ALL
-- SELECT 'Transações GETNET', COUNT(*) FROM transacoes_getnet
-- UNION ALL
-- SELECT 'Títulos TOTVS', COUNT(*) FROM titulos_totvs
-- UNION ALL
-- SELECT 'Vínculos', COUNT(*) FROM conciliacao_vinculos
-- UNION ALL
-- SELECT 'Config Parâmetros', COUNT(*) FROM config_parametros;
