# Ajustes no Schema para Portal do Operador

**Data:** 2026-04-24  
**Contexto:** Implementar fluxo operacional de conciliação manual via FlutterFlow

---

## 🔴 Problema 1: titulo_totvs_id NÃO PODE SER NOT NULL

### Situação Atual
```sql
CREATE TABLE conciliacao_vinculos (
  ...
  titulo_totvs_id BIGINT NOT NULL REFERENCES titulos_totvs(...),
  ...
);
```

### Por Que É Problema?

**Fluxo do Operador:**
1. Operador abre portal
2. Digita NSU que viu no comprovante (ex: `145186923`)
3. Sistema busca em `transacoes_getnet` WHERE nsu = '145186923'
4. **Operador digita número de NF manualmente** (ex: `NF-2026-001234`)
5. Sistema cria registro em `conciliacao_vinculos`

**O Problema:** O registro de `titulos_totvs` pode não existir ainda!
- O título pode estar apenas no TOTVS (backend)
- Ou o operador pode ter digitado errado
- Ou os dados do TOTVS não foram importados

**Solução:** `titulo_totvs_id` deve ser **NULLABLE**

```sql
titulo_totvs_id BIGINT REFERENCES titulos_totvs(titulo_id) ON DELETE SET NULL,
-- Permite criar vínculo SEM ter o título associado ainda
```

---

## 🟡 Problema 2: Rastrear NF Digitada Manualmente

### Situação Atual
O operador digita "NF-2026-001234" mas não há lugar para guardar isso na tabela `conciliacao_vinculos`.

### Solução
Adicionar coluna `numero_nf_manual` para rastrear o que foi digitado:

```sql
ALTER TABLE conciliacao_vinculos ADD COLUMN
  numero_nf_manual VARCHAR(30);
  -- Número de NF digitado pelo operador
  -- Preenchido quando titulo_totvs_id é NULL
  -- Usado para buscar/linkar depois
```

---

## 🟡 Problema 3: Diferenciar Vínculos Manuais vs Automáticos

### Situação Atual
Campo `status` tem valores `'aguardando_validacao', 'confirmado', 'rejeitado', 'manual'`

### Problema
`status = 'manual'` não é claro se significa:
- Vínculo criado manualmente? ✓
- Vínculo aguardando revisão? ?
- Vínculo já validado? ?

### Solução
Adicionar coluna `tipo_vinculacao` para clareza:

```sql
ALTER TABLE conciliacao_vinculos ADD COLUMN
  tipo_vinculacao VARCHAR(50) NOT NULL DEFAULT 'automatico';
  -- Valores: 'automatico' (pelo script), 'manual' (operador)
  -- Permite filtrar por tipo no dashboard
```

---

## ✅ Problema 4: Index para Busca Rápida de NSU

### Situação Atual
Há index em `transacoes_getnet(filial_cnpj, nsu)` ✓

### Ok!
Permite busca rápida quando operador digita NSU:
```sql
SELECT * FROM transacoes_getnet 
WHERE filial_cnpj = $1 AND nsu = $2;
```

---

## ✅ Problema 5: Busca de Títulos Pendentes

### Situação Atual
Dashboard precisa mostrar "NSUs sem vínculo"

Já é possível:
```sql
SELECT * FROM transacoes_getnet 
WHERE filial_cnpj = $1 AND status = 'pendente'
ORDER BY data_transacao DESC;
```

---

## 📋 Resumo de Alterações Necessárias

### Alteração 1: titulo_totvs_id NULLABLE
```sql
ALTER TABLE conciliacao_vinculos
  ALTER COLUMN titulo_totvs_id DROP NOT NULL;
```

### Alteração 2: Adicionar numero_nf_manual
```sql
ALTER TABLE conciliacao_vinculos ADD COLUMN
  numero_nf_manual VARCHAR(30);

COMMENT ON COLUMN conciliacao_vinculos.numero_nf_manual IS
  'Número de NF digitado manualmente pelo operador.
   Preenchido quando titulo_totvs_id é NULL.
   Usado para buscar/linkar o título depois.';
```

### Alteração 3: Adicionar tipo_vinculacao
```sql
ALTER TABLE conciliacao_vinculos ADD COLUMN
  tipo_vinculacao VARCHAR(50) NOT NULL DEFAULT 'automatico';

COMMENT ON COLUMN conciliacao_vinculos.tipo_vinculacao IS
  'Tipo de vinculação: "automatico" (script) ou "manual" (operador).
   Permite filtrar e auditar origem do vínculo.';

-- Índice para dashboard
CREATE INDEX idx_conciliacao_tipo_vinculacao
  ON conciliacao_vinculos(filial_cnpj, tipo_vinculacao);
```

---

## 🔍 Validação: Fluxo Operador com Schema Ajustado

### Passo 1: Operador Abre Portal
```
POST /api/operador/buscar-nsu
Input: { filial_cnpj: "84943067001393", nsu: "145186923" }

Query (Supabase RLS):
SELECT transacao_id, nsu, valor, bandeira, data_transacao 
FROM transacoes_getnet
WHERE filial_cnpj = $1 AND nsu = $2 AND status = 'pendente'
LIMIT 1;

Output: 
{
  transacao_id: 12345,
  nsu: "145186923",
  valor: 7600.00,
  bandeira: "Visa",
  data_transacao: "2025-07-30"
}
```

### Passo 2: Operador Digita NF e Clica "Vincular"
```
POST /api/operador/criar-vinculo
Input: {
  transacao_getnet_id: 12345,
  numero_nf_manual: "NF-2026-001234",
  filial_cnpj: "84943067001393"
}

SQL (via RLS):
INSERT INTO conciliacao_vinculos (
  filial_cnpj,
  transacao_getnet_id,
  titulo_totvs_id,  -- NULL aqui!
  numero_nf_manual,
  tipo_vinculacao,
  status
) VALUES (
  '84943067001393',
  12345,
  NULL,  -- Vínculo criado sem ter o título ainda
  'NF-2026-001234',
  'manual',
  'aguardando_validacao'
);

Output: {
  vinculo_id: 99,
  status: "criado com sucesso"
}
```

### Passo 3: Atualizar transacao_getnet para 'reconciliada'
```
UPDATE transacoes_getnet
SET status = 'conciliada'
WHERE transacao_id = 12345;
```

### Passo 4: Dashboard Mostra Gaps

**Alert A: Sem Vínculo**
```sql
SELECT COUNT(*) as "sem_vinculo"
FROM transacoes_getnet
WHERE filial_cnpj = $1 AND status = 'pendente'
GROUP BY filial_cnpj;
```

**Alert B: Vínculo sem Título**
```sql
SELECT COUNT(*) as "vinculo_sem_titulo"
FROM conciliacao_vinculos
WHERE filial_cnpj = $1 AND titulo_totvs_id IS NULL
GROUP BY filial_cnpj;
```

---

## 📊 Schema Ajustado - Tabela conciliacao_vinculos

### Antes (v2.0)
```sql
CREATE TABLE conciliacao_vinculos (
  vinculo_id BIGSERIAL PRIMARY KEY,
  filial_cnpj CHAR(14) NOT NULL,
  transacao_getnet_id BIGINT NOT NULL,
  titulo_totvs_id BIGINT NOT NULL,  -- ← PROBLEMA
  diferenca_valor NUMERIC(15, 2) DEFAULT 0,
  diferenca_dias SMALLINT DEFAULT 0,
  score_confianca NUMERIC(3, 2) DEFAULT 0.00,
  motivo_rejeicao VARCHAR(255),
  status status_vinculo DEFAULT 'aguardando_validacao',
  usuario_validacao VARCHAR(100),
  data_validacao TIMESTAMP WITH TIME ZONE,
  data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Depois (v2.1)
```sql
CREATE TABLE conciliacao_vinculos (
  vinculo_id BIGSERIAL PRIMARY KEY,
  filial_cnpj CHAR(14) NOT NULL,
  transacao_getnet_id BIGINT NOT NULL,
  titulo_totvs_id BIGINT,  -- ← NULLABLE (permite vínculo sem título)
  
  -- NOVO
  numero_nf_manual VARCHAR(30),  -- NF digitada pelo operador
  tipo_vinculacao VARCHAR(50) NOT NULL DEFAULT 'automatico',  -- automatico|manual
  
  -- Análise
  diferenca_valor NUMERIC(15, 2) DEFAULT 0,
  diferenca_dias SMALLINT DEFAULT 0,
  score_confianca NUMERIC(3, 2) DEFAULT 0.00,
  
  -- Status
  motivo_rejeicao VARCHAR(255),
  status status_vinculo DEFAULT 'aguardando_validacao',
  usuario_validacao VARCHAR(100),
  data_validacao TIMESTAMP WITH TIME ZONE,
  
  -- Auditoria
  data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## ✅ Conclusão

**Schema v2.0:** Suporta 80% do fluxo  
**Ajustes Necessários:** 3 (todos em conciliacao_vinculos)  
**Impacto:** Baixo (apenas ALTER TABLE, sem quebra de compatibilidade)  
**Status:** PRONTO PARA IMPLEMENTAR

---

## 📌 Próximos Passos

1. ✅ Aplicar 3 alterações em Supabase
2. ✅ Criar endpoints Supabase (RLS-protected)
3. ✅ Criar totvs_client.py (mock)
4. ✅ Implementar FlutterFlow portal
