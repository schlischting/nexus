-- Migration: Add origem field to transacoes_getnet
-- Date: 2026-04-28
-- Purpose: Support two NSU workflows (arquivo_getnet vs digitado_operador)

-- Step 1: Add column origem with default value
ALTER TABLE transacoes_getnet
ADD COLUMN origem VARCHAR(50) NOT NULL DEFAULT 'arquivo_getnet';

-- Step 2: Add constraint for valid values
ALTER TABLE transacoes_getnet
ADD CONSTRAINT ck_origem CHECK (origem IN ('arquivo_getnet', 'digitado_operador'));

-- Step 3: Create index for performance
CREATE INDEX IF NOT EXISTS idx_transacoes_getnet_origem
ON transacoes_getnet(filial_cnpj, origem, status);

-- Step 4: Add column comment
COMMENT ON COLUMN transacoes_getnet.origem IS
  'Origem da transação: arquivo_getnet (importada de arquivo ADTO_*.xlsx) ou digitado_operador (lançada manualmente).
   Usado para diferenciar fluxos no dashboard e queries.';

-- Verification query (run after migration)
-- SELECT COUNT(*) as total, origem, COUNT(DISTINCT origem) as origens_unicas FROM transacoes_getnet GROUP BY origem;
-- Expected: All rows should have origem = 'arquivo_getnet' (default)
