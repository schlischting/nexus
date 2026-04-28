/*
 * Migração: Portal do Operador - Schema Adjustments
 * Data: 2026-04-24
 *
 * Contexto: Adiciona suporte para fluxo de conciliação manual via Portal do Operador
 * Onde operadores digitam NSU + número de NF manualmente
 *
 * Ajustes:
 *   1. titulo_totvs_id: DROP NOT NULL (permite vínculo sem título inicialmente)
 *   2. numero_nf_manual: Adiciona coluna (armazena NF digitada pelo operador)
 *   3. tipo_vinculacao: Diferencia vínculo automático vs manual
 *
 * Compatibilidade: ✅ Sem quebra de dados existentes (apenas adiciona flexibilidade)
 * Rollback: Possível via comandos ALTER TABLE reversos
 */

-- =============================================================================
-- ALTERAÇÃO 1: titulo_totvs_id NULLABLE
-- =============================================================================
-- Permite criar vínculo ANTES de ter o título TOTVS mapeado
-- Fluxo: Operador digita NSU + NF → vínculo criado com titulo_totvs_id=NULL
--        Depois sistema busca e associa título quando disponível

ALTER TABLE conciliacao_vinculos
  ALTER COLUMN titulo_totvs_id DROP NOT NULL;

COMMENT ON COLUMN conciliacao_vinculos.titulo_totvs_id IS
  'Referência ao título TOTVS. Pode ser NULL enquanto operador digita NF manualmente.
   Preenchido quando título é encontrado e validado.
   Permite vínculo 1ª etapa (NSU + NF manual) → 2ª etapa (busca automática de título)';


-- =============================================================================
-- ALTERAÇÃO 2: numero_nf_manual (Nova Coluna)
-- =============================================================================
-- Armazena o número de NF digitado manualmente pelo operador no Portal
-- Usado para:
--   a) Rastrear o que foi digitado (auditoria)
--   b) Buscar título TOTVS correspondente depois
--   c) Identificar digitações incorretas (para revisão)

ALTER TABLE conciliacao_vinculos ADD COLUMN
  numero_nf_manual VARCHAR(30);

COMMENT ON COLUMN conciliacao_vinculos.numero_nf_manual IS
  'Número de NF digitado manualmente pelo operador no Portal do Operador.
   Preenchido quando titulo_totvs_id é NULL (operador não tinha título disponível).
   Formato esperado: "NF-AAAA-XXXXXX" (ex: NF-2026-001234)
   Usado para busca e linkagem automática com título TOTVS depois.';


-- =============================================================================
-- ALTERAÇÃO 3: tipo_vinculacao (Nova Coluna)
-- =============================================================================
-- Diferencia origin do vínculo: criado automaticamente (script) vs manualmente (operador)
-- Essencial para:
--   a) Dashboard: filtrar por tipo
--   b) SLA: vinculos manuais podem ter SLA diferente
--   c) Auditoria: rastrear decisões do operador vs automação

ALTER TABLE conciliacao_vinculos ADD COLUMN
  tipo_vinculacao VARCHAR(50) NOT NULL DEFAULT 'automatico';

COMMENT ON COLUMN conciliacao_vinculos.tipo_vinculacao IS
  'Tipo de vinculação: "automatico" (script de matching) ou "manual" (operador Portal).
   Permite:
     - Filtrar vínculos por origem
     - SLAs diferentes para cada tipo
     - Auditoria e análise de decisões operacionais
   Default: "automatico" (compatível com dados existentes)';

-- Índice para dashboard (filtrar por tipo)
CREATE INDEX idx_conciliacao_tipo_vinculacao
  ON conciliacao_vinculos(filial_cnpj, tipo_vinculacao)
  WHERE status = 'aguardando_validacao';

COMMENT ON INDEX idx_conciliacao_tipo_vinculacao IS
  'Acelera queries do Dashboard que filtram por tipo_vinculacao.
   Exemplo: "Mostrar vinculos manuais pendentes de validação"';


-- =============================================================================
-- VERIFICAÇÃO PÓS-MIGRAÇÃO
-- =============================================================================

-- Validar que todas as 3 alterações foram aplicadas:
--
-- SELECT column_name, is_nullable, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'conciliacao_vinculos'
-- ORDER BY ordinal_position;
--
-- Resultado esperado:
--   titulo_totvs_id      | YES | bigint
--   numero_nf_manual     | YES | character varying
--   tipo_vinculacao      | NO  | character varying
--
-- Validar índice:
-- SELECT indexname FROM pg_indexes WHERE indexname = 'idx_conciliacao_tipo_vinculacao';
-- Resultado esperado: 1 linha


-- =============================================================================
-- EXEMPLOS DE USO
-- =============================================================================

/*
EXEMPLO 1: Operador digita NSU e NF (sem título TOTVS ainda)
------------------------------------------------------------

INSERT INTO conciliacao_vinculos (
  filial_cnpj,
  transacao_getnet_id,
  titulo_totvs_id,            -- NULL: não tem título ainda
  numero_nf_manual,           -- "NF-2026-001234": o que operador digitou
  tipo_vinculacao,            -- "manual": operador criou
  status,
  data_criacao
) VALUES (
  '84943067001393',
  12345,
  NULL,
  'NF-2026-001234',
  'manual',
  'aguardando_validacao',
  NOW()
);

RESULTADO: Vínculo criado, esperando validação e busca de título


EXEMPLO 2: Depois que título TOTVS é encontrado
------------------------------------------------

UPDATE conciliacao_vinculos
SET
  titulo_totvs_id = 1002,     -- Agora link para título real
  status = 'confirmado'
WHERE numero_nf_manual = 'NF-2026-001234'
  AND filial_cnpj = '84943067001393'
  AND tipo_vinculacao = 'manual';

RESULTADO: Vínculo completo, título confirmado


EXEMPLO 3: Dashboard - Alertas de Gaps
---------------------------------------

-- Alert A: Vínculos manuais sem título ainda
SELECT COUNT(*) as "vinculos_pendentes_validacao"
FROM conciliacao_vinculos
WHERE filial_cnpj = '84943067001393'
  AND tipo_vinculacao = 'manual'
  AND titulo_totvs_id IS NULL
  AND status = 'aguardando_validacao';

-- Alert B: Distribuição por tipo
SELECT
  tipo_vinculacao,
  COUNT(*) as total,
  SUM(CASE WHEN titulo_totvs_id IS NULL THEN 1 ELSE 0 END) as sem_titulo
FROM conciliacao_vinculos
WHERE filial_cnpj = '84943067001393'
GROUP BY tipo_vinculacao;
*/


-- =============================================================================
-- ROLLBACK (se necessário)
-- =============================================================================

/*
-- Para reverter todas as mudanças:

-- 1. Remover índice
DROP INDEX IF EXISTS idx_conciliacao_tipo_vinculacao;

-- 2. Remover colunas novas
ALTER TABLE conciliacao_vinculos
  DROP COLUMN numero_nf_manual,
  DROP COLUMN tipo_vinculacao;

-- 3. Restaurar NOT NULL em titulo_totvs_id
ALTER TABLE conciliacao_vinculos
  ALTER COLUMN titulo_totvs_id SET NOT NULL;

-- Schema volta à versão anterior (v2.0)
*/
