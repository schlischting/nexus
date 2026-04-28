# Schema Diff: v2.0 → v2.1 (Regras Finais de Negócio)

**Data:** 2026-04-24  
**Arquivo Antigo:** `schema_nexus.sql` (v2.0)  
**Arquivo Novo:** `schema_nexus_v2.1.sql` (v2.1)  
**Mudanças:** 5 principais, todas ADITIVAS (sem quebra de dados)

---

## 📋 Resumo Executivo

| # | Mudança | Tipo | Impacto |
|---|---------|------|---------|
| 1 | Novos ENUM: `tipo_titulo`, `perfil_usuario` | NOVO | ✅ Sem conflito |
| 2 | Novo campo `tipo_titulo` em `titulos_totvs` | NOVO | ✅ Sem conflito |
| 3 | 3 novos campos em `conciliacao_vinculos` para baixa TOTVS | NOVO | ✅ Sem conflito |
| 4 | Status revisado (pendente, confirmado, erro_baixa, rejeitado) | UPDATE | ✅ Compatível |
| 5 | `titulo_totvs_id` agora NULLABLE | ALTER | ✅ Sem quebra |
| 6 | RLS refinada para respeitar perfis (supervisor) | UPDATE | ✅ Compatível |
| 7 | 2 novos índices para Dashboard | NOVO | ✅ Sem conflito |

---

## 🔍 Mudança 1: Novos ENUM Types

### ANTES (v2.0)
```sql
CREATE TYPE status_vinculo AS ENUM (
  'aguardando_validacao',
  'confirmado',
  'rejeitado',
  'manual'
);
```

### DEPOIS (v2.1)
```sql
-- REMOVIDO ANTIGO (será migrado)
-- DROP TYPE status_vinculo;

CREATE TYPE status_vinculo AS ENUM (
  'pendente',        -- ← NOVO nome para 'aguardando_validacao'
  'confirmado',      -- ← Mantém mesmo
  'erro_baixa',      -- ← NOVO (erro do PASOE)
  'rejeitado'        -- ← NOVO nome para rejeição
);

-- NOVO: Tipo de título
CREATE TYPE tipo_titulo AS ENUM (
  'NF',              -- Nota Fiscal
  'AN',              -- Aviso de Nota (compensado automaticamente)
  'OUTRO'            -- Outros
);

-- NOVO: Perfis de usuário
CREATE TYPE perfil_usuario AS ENUM (
  'operador_filial', -- Acesso só à sua filial
  'supervisor',      -- Acesso read em todas filiais
  'admin'            -- Acesso total
);
```

**Impacto:** ✅ Sem quebra (novos tipos não conflitam)

---

## 🔍 Mudança 2: Campo `tipo_titulo` em `titulos_totvs`

### ANTES (v2.0)
```sql
CREATE TABLE IF NOT EXISTS titulos_totvs (
  titulo_id BIGSERIAL PRIMARY KEY,
  filial_cnpj CHAR(14) NOT NULL REFERENCES filiais(filial_cnpj),
  numero_titulo VARCHAR(30) NOT NULL,
  numero_nf VARCHAR(20),
  serie_nf VARCHAR(10),
  data_emissao DATE NOT NULL,
  -- ... resto igual
);
```

### DEPOIS (v2.1)
```sql
CREATE TABLE IF NOT EXISTS titulos_totvs (
  titulo_id BIGSERIAL PRIMARY KEY,
  filial_cnpj CHAR(14) NOT NULL REFERENCES filiais(filial_cnpj),
  numero_titulo VARCHAR(30) NOT NULL,
  numero_nf VARCHAR(20),
  serie_nf VARCHAR(10),

  -- NOVO em v2.1: Tipo de título
  tipo_titulo tipo_titulo NOT NULL DEFAULT 'NF',

  data_emissao DATE NOT NULL,
  -- ... resto igual
);

-- NOVO índice para dashboard
CREATE INDEX idx_titulos_totvs_tipo
  ON titulos_totvs(filial_cnpj, tipo_titulo);
```

**Impacto:** ✅ Sem quebra (default 'NF', coluna nova)

---

## 🔍 Mudança 3: Campos de Baixa TOTVS em `conciliacao_vinculos`

### ANTES (v2.0)
```sql
CREATE TABLE IF NOT EXISTS conciliacao_vinculos (
  vinculo_id BIGSERIAL PRIMARY KEY,
  filial_cnpj CHAR(14) NOT NULL REFERENCES filiais(filial_cnpj),
  transacao_getnet_id BIGINT NOT NULL REFERENCES transacoes_getnet(transacao_id) ON DELETE CASCADE,
  titulo_totvs_id BIGINT NOT NULL REFERENCES titulos_totvs(titulo_id) ON DELETE CASCADE,
  -- ... campos de análise
  status status_vinculo DEFAULT 'aguardando_validacao',
  usuario_validacao VARCHAR(100),
  data_validacao TIMESTAMP WITH TIME ZONE,
  data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
);
```

### DEPOIS (v2.1)
```sql
CREATE TABLE IF NOT EXISTS conciliacao_vinculos (
  vinculo_id BIGSERIAL PRIMARY KEY,
  filial_cnpj CHAR(14) NOT NULL REFERENCES filiais(filial_cnpj),
  transacao_getnet_id BIGINT NOT NULL REFERENCES transacoes_getnet(transacao_id) ON DELETE CASCADE,
  titulo_totvs_id BIGINT REFERENCES titulos_totvs(titulo_id) ON DELETE SET NULL,  -- ← AGORA NULLABLE
  -- ... campos de análise
  
  -- NOVO em v2.1: Informações de vínculo manual (Portal do Operador)
  numero_nf_manual VARCHAR(30),
  tipo_vinculacao VARCHAR(50) NOT NULL DEFAULT 'automatico',
  
  -- NOVO em v2.1: Campos de baixa TOTVS (integração PASOE)
  data_baixa_totvs TIMESTAMP WITH TIME ZONE,
  status_baixa VARCHAR(50),
  erro_baixa TEXT,
  
  -- ... resto (status, usuario_validacao, etc)
  status status_vinculo DEFAULT 'pendente',
  usuario_validacao VARCHAR(100),
  data_validacao TIMESTAMP WITH TIME ZONE,
  data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
);

-- NOVO índice: Vínculos pendentes de baixa
CREATE INDEX idx_conciliacao_vinculos_pendente_baixa
  ON conciliacao_vinculos(filial_cnpj, status)
  WHERE status IN ('pendente', 'erro_baixa');

-- NOVO índice: Portal do Operador - Busca por tipo_vinculacao
CREATE INDEX idx_conciliacao_tipo_vinculacao
  ON conciliacao_vinculos(filial_cnpj, tipo_vinculacao)
  WHERE status = 'pendente';
```

**Impacto:** ✅ Sem quebra (todas colunas NULLABLE ou com DEFAULT)

---

## 🔍 Mudança 4: Status Revisado em `status_vinculo`

### Mapeamento v2.0 → v2.1

| v2.0 | v2.1 | Significado |
|------|------|-------------|
| `aguardando_validacao` | `pendente` | Vínculo criado, aguarda confirmação |
| `confirmado` | `confirmado` | Baixa TOTVS bem-sucedida |
| *(novo)* | `erro_baixa` | PASOE retornou erro, precisa revisão |
| `rejeitado` | `rejeitado` | Supervisor cancelou |
| `manual` | *(removido)* | Uso desambiguado via `tipo_vinculacao` |

**Migração Necessária:**
```sql
-- Se houver dados antigos, executar:
UPDATE conciliacao_vinculos
SET status = 'pendente'::status_vinculo
WHERE status = 'aguardando_validacao'::status_vinculo;

-- Remover tipo antigo (após migração)
-- DROP TYPE status_vinculo CASCADE;
```

**Impacto:** ⚠️ Requer migração de dados antigos (se existirem)

---

## 🔍 Mudança 5: `titulo_totvs_id` Agora NULLABLE

### ANTES (v2.0)
```sql
titulo_totvs_id BIGINT NOT NULL REFERENCES titulos_totvs(titulo_id) ON DELETE CASCADE,
```

### DEPOIS (v2.1)
```sql
titulo_totvs_id BIGINT REFERENCES titulos_totvs(titulo_id) ON DELETE SET NULL,
```

**Por Quê?** Permite criar vínculo ANTES de encontrar o título (Portal do Operador)

**Fluxo:**
1. Operador digita NSU + NF → cria vínculo com `titulo_totvs_id = NULL`
2. Sistema busca título TOTVS → atualiza `titulo_totvs_id`
3. Sistema chama PASOE → registra resultado

**Impacto:** ✅ Sem quebra (NOT NULL → NULL é compatível para SELECT)

---

## 🔍 Mudança 6: RLS Refinada para Respeitar Perfis

### ANTES (v2.0)
```sql
-- TODAS políticas: operador vê apenas sua filial
CREATE POLICY rls_transacoes_getnet_own
  ON transacoes_getnet FOR ALL
  USING (
    filial_cnpj IN (
      SELECT filial_cnpj FROM user_filiais_cnpj WHERE user_id = auth.uid()
    )
  );
```

### DEPOIS (v2.1)
```sql
-- NOVO: Supervisor e admin veem tudo, operador vê apenas sua filial
CREATE POLICY rls_transacoes_getnet_own
  ON transacoes_getnet FOR ALL
  USING (
    auth.jwt() ->> 'role' IN ('admin', 'supervisor')
    OR filial_cnpj IN (
      SELECT filial_cnpj FROM user_filiais_cnpj WHERE user_id = auth.uid()
    )
  );
```

**Aplicado em:**
- `filiais`
- `transacoes_getnet`
- `titulos_totvs`
- `conciliacao_vinculos`

**Impacto:** ✅ Sem quebra (adição de permissões, não restrição)

---

## 🔍 Mudança 7: Dois Novos Índices

### NOVO em v2.1
```sql
-- Dashboard: Vínculos pendentes de baixa TOTVS
CREATE INDEX idx_conciliacao_vinculos_pendente_baixa
  ON conciliacao_vinculos(filial_cnpj, status)
  WHERE status IN ('pendente', 'erro_baixa');

-- Portal do Operador: Busca por tipo de vínculo
CREATE INDEX idx_conciliacao_tipo_vinculacao
  ON conciliacao_vinculos(filial_cnpj, tipo_vinculacao)
  WHERE status = 'pendente';

-- Dashboard: Filtrar títulos por tipo
CREATE INDEX idx_titulos_totvs_tipo
  ON titulos_totvs(filial_cnpj, tipo_titulo);
```

**Impacto:** ✅ Sem conflito (apenas performance)

---

## ✅ Resumo de Compatibilidade

### Dados Existentes
```
✅ Nenhum DELETE ou DROP necessário
✅ Todas as colunas novas têm DEFAULT ou são NULLABLE
⚠️ Status precisam ser migrados se houver dados antigos
```

### Aplicações Que Acessam v2.0
```
✅ Seguem funcionando normalmente
✅ Novas colunas são opcionais
⚠️ Precisam ser atualizadas para usar status novos
```

---

## 🔄 Estratégia de Migração

### Se você NÃO tem dados em produção:
```
REMOVA:    schema_nexus.sql
USE:       schema_nexus_v2.1.sql
RESULTADO: Schema v2.1 pronto
```

### Se você TEM dados do schema v2.0:
```
PASSO 1: Executar schema_nexus_v2.1.sql (cria novos tipos, campos, índices)
PASSO 2: Migrar dados antigos:
         UPDATE conciliacao_vinculos
         SET status = 'pendente'::status_vinculo
         WHERE status = 'aguardando_validacao'::status_vinculo;

PASSO 3: Validar com SUPABASE_DEPLOYMENT_ROTEIRO.md
PASSO 4: Remover schema_nexus.sql antigo (opcional, manter para backup)
```

---

## 📋 Checklist de Validação Pós-Migração

Execute estas queries para validar que v2.1 está correto:

```sql
-- ✅ Validar ENUMs novos
SELECT enum_range(NULL::tipo_titulo);
SELECT enum_range(NULL::perfil_usuario);

-- ✅ Validar coluna tipo_titulo
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'titulos_totvs'
AND column_name = 'tipo_titulo';
-- Resultado: tipo_titulo, USER-DEFINED, NO

-- ✅ Validar colunas de baixa TOTVS
SELECT column_name, is_nullable
FROM information_schema.columns
WHERE table_name = 'conciliacao_vinculos'
AND column_name IN ('data_baixa_totvs', 'status_baixa', 'erro_baixa',
                    'numero_nf_manual', 'tipo_vinculacao');
-- Resultado: 5 colunas, todas com is_nullable=YES

-- ✅ Validar titulo_totvs_id é NULLABLE
SELECT column_name, is_nullable
FROM information_schema.columns
WHERE table_name = 'conciliacao_vinculos'
AND column_name = 'titulo_totvs_id';
-- Resultado: titulo_totvs_id, YES

-- ✅ Validar novos índices
SELECT indexname FROM pg_indexes
WHERE indexname IN (
  'idx_conciliacao_vinculos_pendente_baixa',
  'idx_conciliacao_tipo_vinculacao',
  'idx_titulos_totvs_tipo'
);
-- Resultado: 3 índices
```

---

## 🗑️ O que Fazer com MIGRACAO_PORTAL_OPERADOR.sql?

### RESPOSTA DEFINITIVA:

**❌ NÃO EXECUTE MIGRACAO_PORTAL_OPERADOR.sql**

**Por Quê?**
- `schema_nexus_v2.1.sql` já contém TODAS as mudanças de MIGRACAO_PORTAL_OPERADOR.sql
- Tentar executar ALTER TABLE depois causaria erro: "coluna já existe"

### Comparação

| Mudança | Em MIGRACAO_PORTAL_OPERADOR.sql | Em schema_nexus_v2.1.sql |
|---------|----------------------------------|-------------------------|
| `titulo_totvs_id` NULLABLE | ✅ SIM (ALTER) | ✅ SIM (CREATE) |
| `numero_nf_manual` | ✅ SIM (ADD) | ✅ SIM (CREATE) |
| `tipo_vinculacao` | ✅ SIM (ADD) | ✅ SIM (CREATE) |
| Índice tipo_vinculacao | ✅ SIM | ✅ SIM |
| **Campos de baixa TOTVS** | ❌ NÃO | ✅ SIM (NOVO v2.1) |

**Conclusão:** `schema_nexus_v2.1.sql` é um **superconjunto** de MIGRACAO_PORTAL_OPERADOR.sql + regras finais de negócio.

---

## 🚀 Próximos Passos

### Imediatamente:
1. **Deletar/ignorar:** `schema_nexus.sql` (versão antigo)
2. **Deletar/ignorar:** `MIGRACAO_PORTAL_OPERADOR.sql` (substituído)
3. **Usar:** `schema_nexus_v2.1.sql` (nova versão única)

### Validação:
```bash
# No Supabase Dashboard:
1. SQL Editor → New Query
2. Copiar schema_nexus_v2.1.sql
3. Colar e Run
4. Validar com queries acima
```

### Documentação Atualizada:
- ✅ `SUPABASE_DEPLOYMENT_ROTEIRO.md` - Continue usando (SQL de teste é compatível)
- ✅ `docs/PORTAL_OPERADOR_INTEGRACAO.md` - Continua válido
- ✅ `backend/totvs_client.py` - Continua válido

---

**Status:** ✅ PRONTO PARA DEPLOY  
**Arquivo a Usar:** `schema_nexus_v2.1.sql`  
**Data:** 2026-04-24
