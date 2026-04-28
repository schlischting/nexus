# Supabase Deployment - Roteiro Passo a Passo

**Data:** 2026-04-24  
**Objetivo:** Subir banco Nexus do zero no Supabase  
**Duração Estimada:** 15 minutos

---

## 🎯 PARTE 1: Ordem dos Arquivos SQL

### ✅ Resposta Definitiva:

**EXECUTE OS DOIS, NESTA ORDEM:**

```
1️⃣  database/schema_nexus.sql        (v2.0 - Base)
                    ↓
2️⃣  database/MIGRACAO_PORTAL_OPERADOR.sql  (Portal - Ajustes)
```

### Por Quê?

| Arquivo | O que faz | Deve rodar? |
|---------|-----------|-----------|
| `schema_nexus.sql` | Cria 5 tabelas (filiais, transacoes_getnet, titulos_totvs, conciliacao_vinculos, user_filiais_cnpj) + RLS + triggers + funções | ✅ SIM - 1º |
| `MIGRACAO_PORTAL_OPERADOR.sql` | Adiciona 3 colunas novas (titulo_totvs_id NULLABLE, numero_nf_manual, tipo_vinculacao) + índice | ✅ SIM - 2º |

**Não rodaria APENAS um porque:**
- Se rodar APENAS `schema_nexus.sql` → Falta suporte para Portal do Operador
- Se rodar APENAS `MIGRACAO_PORTAL_OPERADOR.sql` → As tabelas não existem, query falha

---

## 🚀 PARTE 2: Checklist Pré-Execução (Supabase Dashboard)

### Antes de Executar Qualquer SQL

**[ ] 1. Criar Projeto Supabase**
- Ir em: https://app.supabase.com
- Clicar: "New Project"
- Nome: `nexus-prod` (ou similar)
- Password: Guardar com segurança
- Region: `South America (São Paulo)` ou sua preferência
- Esperar 5-10 min de inicialização

**[ ] 2. Habilitar RLS em Todas as Tabelas**
Nota: RLS será criado POR schema_nexus.sql, mas validar depois que está ativo

- Ir em: Authentication → Policies
- Verificar que RLS está "ON" (padrão no Supabase)

**[ ] 3. Preparar para SQL Execution**
- Ir em: SQL Editor
- Novo Query
- Pronto para copiar/colar

---

## 🔧 PARTE 3: Execução SQL (Passo a Passo)

### Step 1: Executar schema_nexus.sql

**Ação:**
1. Abrir: https://app.supabase.com → Seu Projeto → SQL Editor
2. Clicar: "New Query"
3. Copiar conteúdo do arquivo: `database/schema_nexus.sql`
4. Colar no SQL Editor
5. Clicar: "Run" (botão verde)

**Resultado esperado:**
```
✅ Success. 544 rows inserted/updated
```

**Tempo:** ~3-5 segundos

---

### Step 2: Executar MIGRACAO_PORTAL_OPERADOR.sql

**Ação:**
1. Clicar: "New Query" (nova query)
2. Copiar conteúdo do arquivo: `database/MIGRACAO_PORTAL_OPERADOR.sql`
3. Colar no SQL Editor
4. Clicar: "Run"

**Resultado esperado:**
```
✅ Success. 3 rows altered, 1 index created
```

**Tempo:** ~1-2 segundos

---

## ✅ PARTE 4: SQL de Teste de Sanidade

Execute IMEDIATAMENTE APÓS os 2 arquivos anteriores:

Copie e execute este SQL completo no Supabase SQL Editor:

```sql
/*
 * TEST SUITE: Nexus Schema Sanity Check
 * Data: 2026-04-24
 * Objetivo: Validar que schema foi criado corretamente
 */

BEGIN;  -- Iniciar transação (rollback ao final)

-- =========================================================================
-- TESTE 1: Validar que as 5 tabelas existem
-- =========================================================================

\echo '=== TESTE 1: Validar 5 Tabelas ==='

SELECT 
  COUNT(*) as tabelas_criadas,
  STRING_AGG(tablename, ', ' ORDER BY tablename) as nomes
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('filiais', 'user_filiais_cnpj', 'transacoes_getnet', 'titulos_totvs', 'conciliacao_vinculos');

-- Resultado esperado: 5 tabelas

-- Verificar detalhes de cada tabela
SELECT tablename, array_length(ARRAY(
  SELECT column_name FROM information_schema.columns 
  WHERE table_name = pg_tables.tablename
), 1) as coluna_count
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('filiais', 'user_filiais_cnpj', 'transacoes_getnet', 'titulos_totvs', 'conciliacao_vinculos')
ORDER BY tablename;

-- =========================================================================
-- TESTE 2: Validar que RLS está habilitado em 5 tabelas
-- =========================================================================

\echo ''
\echo '=== TESTE 2: Validar RLS Policies ==='

SELECT 
  COUNT(*) as policies_ativas
FROM pg_policies
WHERE tablename IN ('filiais', 'user_filiais_cnpj', 'transacoes_getnet', 'titulos_totvs', 'conciliacao_vinculos');

-- Resultado esperado: 5 ou mais (uma policy por tabela)

-- Listar políticas por tabela
SELECT 
  tablename,
  policyname,
  permissive,
  qual as tipo
FROM pg_policies
WHERE tablename IN ('filiais', 'user_filiais_cnpj', 'transacoes_getnet', 'titulos_totvs', 'conciliacao_vinculos')
ORDER BY tablename;

-- =========================================================================
-- TESTE 3: Validar que funções existem
-- =========================================================================

\echo ''
\echo '=== TESTE 3: Validar Funções ==='

SELECT 
  COUNT(*) as funcoes_criadas,
  STRING_AGG(proname, ', ' ORDER BY proname) as nomes
FROM pg_proc
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  AND proname IN ('update_timestamp', 'calcular_score_matching');

-- Resultado esperado: 2 funções

-- =========================================================================
-- TESTE 4: Validar que triggers foram criados
-- =========================================================================

\echo ''
\echo '=== TESTE 4: Validar Triggers ==='

SELECT 
  COUNT(*) as triggers_criados,
  STRING_AGG(trigger_name, ', ' ORDER BY trigger_name) as nomes
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND trigger_name LIKE 'trigger_%';

-- Resultado esperado: 4 triggers (um por tabela com timestamp)

-- =========================================================================
-- TESTE 5: Validar que índices foram criados
-- =========================================================================

\echo ''
\echo '=== TESTE 5: Validar Índices ==='

SELECT 
  COUNT(*) as indices_criados,
  STRING_AGG(indexname, ', ' ORDER BY indexname) as nomes
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname LIKE 'idx_%';

-- Resultado esperado: 10+ índices

-- =========================================================================
-- TESTE 6: Validar que colunas Portal do Operador foram adicionadas
-- =========================================================================

\echo ''
\echo '=== TESTE 6: Validar Colunas Portal do Operador ==='

SELECT
  column_name,
  is_nullable,
  column_default,
  data_type
FROM information_schema.columns
WHERE table_name = 'conciliacao_vinculos'
  AND column_name IN ('titulo_totvs_id', 'numero_nf_manual', 'tipo_vinculacao')
ORDER BY column_name;

-- Resultado esperado:
-- titulo_totvs_id    | YES | NULL   | bigint
-- numero_nf_manual   | YES | NULL   | character varying
-- tipo_vinculacao    | NO  | 'automatico' | character varying

-- =========================================================================
-- TESTE 7: Inserir Filial de Teste
-- =========================================================================

\echo ''
\echo '=== TESTE 7: Inserir Filial de Teste ==='

INSERT INTO filiais (
  filial_cnpj,
  codigo_ec,
  nome_filial,
  uf,
  razao_social,
  ativo
) VALUES (
  '12345678000195',
  'EC_TESTE_001',
  'Filial Teste Nexus',
  'SP',
  'NEXUS TESTING LTDA',
  true
)
ON CONFLICT (filial_cnpj) DO NOTHING;

-- Validar que foi inserida
SELECT 
  filial_cnpj,
  nome_filial,
  ativo,
  data_criacao
FROM filiais
WHERE filial_cnpj = '12345678000195';

-- Resultado esperado: 1 filial com ativo=true

-- =========================================================================
-- TESTE 8: Inserir Transação de Teste
-- =========================================================================

\echo ''
\echo '=== TESTE 8: Inserir Transação de Teste ==='

INSERT INTO transacoes_getnet (
  filial_cnpj,
  nsu,
  numero_autorizacao,
  data_transacao,
  hora_transacao,
  valor,
  bandeira,
  codigo_ec,
  tipo_lancamento,
  status,
  hash_transacao
) VALUES (
  '12345678000195',
  '000000001',
  '123456',
  '2026-04-24',
  '14:30:00'::time,
  1500.50,
  'Visa',
  'EC_TESTE_001',
  'Vendas',
  'pendente',
  'ABC123DEF456ABC123DEF456ABC123DEF456ABC123DEF456ABC123DEF456ABC1'
)
ON CONFLICT (hash_transacao) DO NOTHING;

-- Validar que foi inserida
SELECT 
  transacao_id,
  filial_cnpj,
  nsu,
  valor,
  status,
  data_transacao,
  hora_transacao
FROM transacoes_getnet
WHERE filial_cnpj = '12345678000195'
  AND nsu = '000000001';

-- Resultado esperado: 1 transação com status='pendente'

-- =========================================================================
-- TESTE 9: Validar Dedução (Hash deve rejeitar duplicata)
-- =========================================================================

\echo ''
\echo '=== TESTE 9: Testar Deduplicação (Hash UNIQUE) ==='

INSERT INTO transacoes_getnet (
  filial_cnpj,
  nsu,
  numero_autorizacao,
  data_transacao,
  hora_transacao,
  valor,
  bandeira,
  codigo_ec,
  tipo_lancamento,
  status,
  hash_transacao
) VALUES (
  '12345678000195',
  '000000002',
  '654321',
  '2026-04-24',
  '15:45:00'::time,
  2500.75,
  'Mastercard',
  'EC_TESTE_001',
  'Vendas',
  'pendente',
  'ABC123DEF456ABC123DEF456ABC123DEF456ABC123DEF456ABC123DEF456ABC1'  -- MESMO HASH
);

-- Resultado esperado: ❌ ERROR - duplicate key value violates unique constraint "hash_transacao"
-- Isso é ESPERADO e desejado!

-- =========================================================================
-- TESTE 10: Validar Triggers (data_atualizacao auto-atualiza)
-- =========================================================================

\echo ''
\echo '=== TESTE 10: Testar Triggers de Timestamp ==='

-- Inserir filial de teste para trigger
INSERT INTO filiais (
  filial_cnpj,
  codigo_ec,
  nome_filial,
  uf
) VALUES (
  '98765432000108',
  'EC_TRIGGER_TEST',
  'Teste Trigger',
  'RJ'
)
ON CONFLICT (filial_cnpj) DO NOTHING;

-- Aguardar 1 segundo
SELECT pg_sleep(1);

-- Atualizar filial
UPDATE filiais
SET nome_filial = 'Teste Trigger Atualizado'
WHERE filial_cnpj = '98765432000108';

-- Verificar que data_atualizacao foi modificada
SELECT 
  filial_cnpj,
  nome_filial,
  data_criacao,
  data_atualizacao,
  EXTRACT(EPOCH FROM (data_atualizacao - data_criacao)) as segundos_decorridos
FROM filiais
WHERE filial_cnpj = '98765432000108';

-- Resultado esperado: data_atualizacao > data_criacao

-- =========================================================================
-- TESTE 11: Validar RLS Block (simular usuário sem acesso)
-- =========================================================================

\echo ''
\echo '=== TESTE 11: Validar RLS Bloqueio ==='

-- Este teste requer um usuário Supabase real e token JWT
-- Por enquanto, apenas mostramos as políticas

SELECT 
  policyname,
  tablename,
  qual as condicao
FROM pg_policies
WHERE tablename = 'filiais'
  AND policyname LIKE 'rls_%';

-- Resultado esperado: Políticas que usam auth.uid() ou current_user_filial()

-- =========================================================================
-- RESUMO FINAL
-- =========================================================================

\echo ''
\echo '╔════════════════════════════════════════════════════════════════╗'
\echo '║           ✅ TESTE DE SANIDADE COMPLETO                       ║'
\echo '║                                                                ║'
\echo '║  Se você viu todos os resultados acima sem ERROS:             ║'
\echo '║  ✅ Banco está pronto para uso                                ║'
\echo '║                                                                ║'
\echo '║  Se viu ERROS:                                                ║'
\echo '║  ❌ Verificar logs acima e corrigir                           ║'
\echo '╚════════════════════════════════════════════════════════════════╝'

-- =========================================================================
-- ROLLBACK (ou COMMIT)
-- =========================================================================

-- Para TESTAR sem salvar (reverter mudanças do TESTE 7-9):
ROLLBACK;

-- Para SALVAR (comentar ROLLBACK acima e descomentar):
-- COMMIT;

-- Nota: Em produção, remover BEGIN/ROLLBACK e usar COMMIT
```

---

## 📋 Como Executar o Teste (Passo a Passo)

### Opção A: Teste SEM Salvar (Recomendado Primeiro)

1. Copiar SQL completo acima
2. Colar no Supabase SQL Editor
3. Clicar: "Run"
4. Verificar RESULTADOS (tabelas, RLS, etc)
5. **Último comando: `ROLLBACK`** → Remove dados de teste
6. Resultado: Banco criado mas sem dados de teste

### Opção B: Teste SALVANDO Dados

1. **Abrir o SQL acima em editor de texto**
2. **Encontrar linha:** `ROLLBACK;` (perto do final)
3. **Comentar:** `-- ROLLBACK;`
4. **Descomentar:** `COMMIT;`
5. Colar no Supabase SQL Editor
6. Clicar: "Run"
7. Resultado: Banco + dados de teste salvos

---

## 📊 Resultado Esperado de Cada Teste

### TESTE 1: Tabelas ✅

```
 tabelas_criadas | nomes
-----------------+-----------------------------------------------
               5 | conciliacao_vinculos, filiais, titulos_totvs, 
                 | transacoes_getnet, user_filiais_cnpj
```

### TESTE 2: RLS Policies ✅

```
 policies_ativas
-----------------
               5
```

### TESTE 3: Funções ✅

```
 funcoes_criadas | nomes
-----------------+--------------------------------
               2 | calcular_score_matching, update_timestamp
```

### TESTE 4: Triggers ✅

```
 triggers_criados | nomes
------------------+------------------------------------------------------------------
                4 | trigger_conciliacao_vinculos_timestamp, trigger_filiais_timestamp,
                  | trigger_titulos_totvs_timestamp, trigger_transacoes_getnet_timestamp
```

### TESTE 5: Índices ✅

```
 indices_criados | nomes
-----------------+------- (10+ indices com prefixo idx_)
              11 | idx_conciliacao_vinculos_filial_cnpj, idx_conciliacao_vinculos_score, ...
```

### TESTE 6: Colunas Portal ✅

```
      column_name      | is_nullable |   column_default   |       data_type
-----------------------+-------------+--------------------+---------------------
 numero_nf_manual      | YES         |                    | character varying
 tipo_vinculacao       | NO          | 'automatico'::text | character varying
 titulo_totvs_id       | YES         |                    | bigint
```

### TESTE 7: Inserção Filial ✅

```
 filial_cnpj  |         nome_filial         | ativo |        data_criacao
--------------+-----------------------------+-------+------------------------
 12345678... | Filial Teste Nexus          | t     | 2026-04-24 14:30:00
```

### TESTE 8: Inserção Transação ✅

```
 transacao_id | filial_cnpj  | nsu | valor  | status    | data_transacao | hora_transacao
--------------+--------------+-----+--------+-----------+----------------+----------------
          1   | 12345678... | 000000001 | 1500.50 | pendente | 2026-04-24  | 14:30:00
```

### TESTE 9: Deduplicação ❌ (Erro Esperado) ✅

```
ERROR: duplicate key value violates unique constraint "hash_transacao"
DETAIL: Key (hash_transacao)=(ABC123DEF...) already exists.
```

✅ **Isso é ESPERADO e correto!**

### TESTE 10: Triggers ✅

```
 filial_cnpj  |          nome_filial           |      data_criacao      |     data_atualizacao   | segundos_decorridos
--------------+--------------------------------+------------------------+------------------------+---------------------
 98765432... | Teste Trigger Atualizado       | 2026-04-24 14:30:01   | 2026-04-24 14:30:02   | 1.245
```

---

## 🎯 Checklist Final de Validação

Após executar todos os testes, validar:

- [ ] TESTE 1: 5 tabelas apareceram
- [ ] TESTE 2: 5+ RLS policies ativas
- [ ] TESTE 3: 2 funções existem
- [ ] TESTE 4: 4 triggers criados
- [ ] TESTE 5: 10+ índices criados
- [ ] TESTE 6: 3 colunas do Portal aparecem
- [ ] TESTE 7: Filial inserida com sucesso
- [ ] TESTE 8: Transação inserida com sucesso
- [ ] TESTE 9: Tentativa de duplicata foi **bloqueada** (erro esperado) ✅
- [ ] TESTE 10: Trigger atualizou `data_atualizacao` automaticamente

**Se TODOS os 10 testes passaram:**
```
✅ BANCO PRONTO PARA USO
```

---

## 🚨 Troubleshooting

### Erro: "relation "filiais" does not exist"
**Causa:** schema_nexus.sql não foi executado primeiro  
**Solução:** Execute schema_nexus.sql antes de MIGRACAO_PORTAL_OPERADOR.sql

### Erro: "column "numero_nf_manual" does not exist"
**Causa:** MIGRACAO_PORTAL_OPERADOR.sql não foi executado  
**Solução:** Execute este arquivo DEPOIS de schema_nexus.sql

### Erro: "syntax error at or near "BEGIN""
**Causa:** Alguns bancos (AWS) não aceitam BEGIN/COMMIT em SQL Editor  
**Solução:** Remover BEGIN e ROLLBACK, deixar apenas SELECT queries

### Teste 9 não deu erro (aceitou duplicata)
**Causa:** Hash anterior não foi salvo corretamente  
**Solução:** Verificar que hash_transacao é UNIQUE em schema

---

## ✅ Próximos Passos Após Banco Pronto

1. **Configurar Autenticação Supabase**
   - Auth → Users → Criar usuário de teste
   - Guardar email e senha

2. **Inserir user_filiais_cnpj**
   ```sql
   INSERT INTO user_filiais_cnpj (
     user_id,
     filial_cnpj,
     perfil
   ) VALUES (
     'UUID-do-usuario',  -- De Supabase Auth
     '12345678000195',
     'operador'
   );
   ```

3. **Testar RLS com Usuário Real**
   - Login com usuário
   - Fazer query via Supabase Client
   - Validar que vê apenas sua filial

---

**Status:** ✅ PRONTO PARA DEPLOY  
**Tempo Total:** ~15 minutos  
**Próximo:** Configurar Edge Functions para Portal do Operador
