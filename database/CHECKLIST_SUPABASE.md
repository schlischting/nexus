# Checklist: Deploy Nexus Schema no Supabase

**Data:** 2026-04-25  
**Versão:** 3.0 FINAL  
**Status:** 🟢 PRONTO PARA DEPLOY  
**Tempo Total:** ~30 minutos

---

## Pré-Requisitos

- [x] Projeto Supabase criado (https://supabase.com)
- [x] URL do banco: `https://[seu-projeto].supabase.co`
- [x] Chave anon: `eyJ...` (em `.env`)
- [x] Arquivo `schema_nexus_v3.0.sql` disponível
- [x] Acesso ao Supabase Dashboard (SQL Editor)

---

## FASE 1: Configuração Pre-SQL (Dashboard Supabase)

### 1. Ativar Extensões

**Local:** Supabase Dashboard → Extensions

```
[ ] uuid-ossp
    Status: Enabled/Installing
    Descrição: UUID generation

[ ] pg_trgm
    Status: Enabled/Installing
    Descrição: Text search (preparação)
```

**⏱️ Tempo:** 2 minutos

**✓ Se OK:** Ambas aparecem em "Installed extensions"

---

### 2. Confirmar Supabase Auth Habilitado

**Local:** Supabase Dashboard → Authentication

```
[ ] Auth habilitado
    Próximos > Auth Providers > Email habilitado

[ ] API corretamente apontada
    URL: https://[seu-projeto].supabase.co/auth/v1
```

**⏱️ Tempo:** 1 minuto

**✓ Se OK:** Você consegue fazer signup/signin

---

### 3. Configurar CORS (Opcional, se FlutterFlow vai usar)

**Local:** Supabase Dashboard → Project Settings → API → CORS

```
[ ] Domínios Permitidos:
    - http://localhost:3000 (desenvolvimento)
    - https://seu-app.flutterflow.app (produção)
    - https://seu-app.com (seu domínio)
```

**⏱️ Tempo:** 2 minutos

**✓ Se OK:** FlutterFlow consegue fazer requests ao Supabase

---

## FASE 2: Deploy Schema (SQL Editor)

### 1. Abrir SQL Editor

**Local:** Supabase Dashboard → SQL Editor → "New Query"

```sql
-- Copiar TODO o conteúdo de schema_nexus_v3.0.sql aqui
```

**⏱️ Tempo:** 1 minuto

---

### 2. Executar Schema

```
[ ] Copiar e colar INTEIRO o arquivo schema_nexus_v3.0.sql

[ ] Revisar:
    - Nenhuma linha vermelha (erro)
    - Nenhuma sintaxe inválida

[ ] Clicar botão RUN ou Ctrl+Enter

[ ] Aguardar execução (2-5 minutos)
```

**⏱️ Tempo:** 5 minutos

**✓ Se OK:** 
```
-- Resultado esperado:
CREATE EXTENSION
CREATE TYPE
CREATE TABLE
CREATE INDEX
CREATE FUNCTION
CREATE TRIGGER
CREATE POLICY
INSERT 0 6
-- ... sem erros
```

---

### 3. Verificar Tabelas Criadas

```sql
SELECT
  schemaname,
  tablename
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
```

**Resultado Esperado:**
```
schemaname | tablename
============|=====================
public     | conciliacao_vinculos
public     | config_parametros
public     | filiais
public     | titulos_totvs
public     | transacoes_getnet
public     | user_filiais
public     | user_filiais_cnpj
(7 rows)
```

**⏱️ Tempo:** 1 minuto

**✓ Se OK:** 7 tabelas visíveis em Dashboard → Tables

---

## FASE 3: SQL Sanity Checks (Validação Local)

Execute cada query abaixo no SQL Editor Supabase:

### Check 1: Tabelas Criadas

```sql
-- Verificar se todas as 7 tabelas existem
SELECT COUNT(*) as total_tabelas
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE';

-- Resultado esperado: 7
```

✅ **OK:** resultado = 7

❌ **FALHA:** Executar novamente schema_nexus_v3.0.sql

---

### Check 2: Types (ENUMs) Criados

```sql
-- Verificar se todos os 5 enums existem
SELECT typname
FROM pg_type
WHERE typtype = 'e'
  AND typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
ORDER BY typname;

-- Resultado esperado: 5 enums
-- perfil_usuario, status_titulo, status_transacao, status_vinculo, tipo_titulo
```

✅ **OK:** 5 linhas retornadas

❌ **FALHA:** Verificar erros de criação

---

### Check 3: Índices Criados

```sql
-- Verificar se todos os 12 índices existem
SELECT COUNT(*) as total_indices
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname LIKE 'idx_%';

-- Resultado esperado: >= 12
```

✅ **OK:** >= 12

❌ **FALHA:** Alguns índices podem ter falhado (menos crítico)

---

### Check 4: Funções Criadas

```sql
-- Verificar funções de negócio
SELECT routinename
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_type = 'FUNCTION'
  AND routine_name IN ('update_timestamp', 'calcular_score_matching')
ORDER BY routinename;

-- Resultado esperado: 2 funções
```

✅ **OK:** 2 linhas (update_timestamp, calcular_score_matching)

❌ **FALHA:** Função não foi criada

---

### Check 5: Triggers Criados

```sql
-- Verificar se 4 triggers existem
SELECT COUNT(*) as total_triggers
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND trigger_name LIKE 'trigger_%';

-- Resultado esperado: 4
```

✅ **OK:** 4

❌ **FALHA:** Triggers não foram criadas

---

### Check 6: Views Criadas

```sql
-- Verificar se 3 views existem
SELECT viewname
FROM pg_views
WHERE schemaname = 'public'
  AND viewname LIKE 'vw_%'
ORDER BY viewname;

-- Resultado esperado: 3 views
-- vw_nsu_sem_titulo, vw_sugestoes_supervisor, vw_titulo_sem_nsu
```

✅ **OK:** 3 linhas

❌ **FALHA:** Views não foram criadas

---

### Check 7: RLS Habilitado

```sql
-- Verificar se RLS está habilitado em todas as tabelas
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('filiais', 'transacoes_getnet', 'titulos_totvs', 'conciliacao_vinculos', 'user_filiais_cnpj', 'config_parametros')
ORDER BY tablename;

-- Resultado esperado: tablename | rowsecurity
--                      ........... | t (true em todas)
```

✅ **OK:** Todos com `rowsecurity = true`

❌ **FALHA:** Executar:
```sql
ALTER TABLE [tabela] ENABLE ROW LEVEL SECURITY;
```

---

### Check 8: Policies RLS Criadas

```sql
-- Verificar se policies existem
SELECT policyname, tablename
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Resultado esperado: >= 6 policies
-- rls_filiais_own
-- rls_transacoes_getnet_own
-- rls_titulos_totvs_own
-- rls_conciliacao_vinculos_own
-- rls_conciliacao_vinculos_supervisor_update
-- rls_user_filiais_cnpj_own
-- rls_config_parametros_admin
```

✅ **OK:** >= 7 policies

❌ **FALHA:** Policies não foram criadas (verificar erros no deploy)

---

### Check 9: config_parametros Preenchido

```sql
-- Verificar se parâmetros iniciais foram inseridos
SELECT COUNT(*) as total_parametros
FROM config_parametros;

-- Resultado esperado: 6
```

✅ **OK:** 6 parâmetros

❌ **FALHA:** Executar:
```sql
INSERT INTO config_parametros (chave, valor, descricao) VALUES
  ('tolerancia_valor_pct', '5', 'Tolerância percentual no match de valor (ex: 5%)'),
  ('tolerancia_dias', '3', 'Tolerância em dias no match de data'),
  ('score_auto', '0.95', 'Score mínimo para match automático'),
  ('score_sugestao', '0.75', 'Score mínimo para sugestão ao supervisor'),
  ('max_retries_baixa', '3', 'Máximo de tentativas de reprocessamento'),
  ('timeout_pasoe_segundos', '30', 'Timeout para chamadas ao PASOE (segundos)');
```

---

### Check 10: Constraints Validadas

```sql
-- Verificar se constraints estão presentes
SELECT constraint_name, table_name, constraint_type
FROM information_schema.table_constraints
WHERE table_schema = 'public'
  AND table_name IN ('filiais', 'transacoes_getnet', 'titulos_totvs', 'conciliacao_vinculos')
  AND constraint_type IN ('UNIQUE', 'PRIMARY KEY', 'FOREIGN KEY', 'CHECK')
ORDER BY table_name, constraint_name;

-- Resultado esperado: >= 20 constraints
```

✅ **OK:** >= 20 constraints

❌ **FALHA:** Alguma constraint não foi criada

---

### Check 11: Scoring Function Logic

```sql
-- Testar calcular_score_matching() com valores de teste
SELECT
  calcular_score_matching(
    1500.00::NUMERIC,      -- valor_getnet
    1515.00::NUMERIC,      -- valor_totvs
    '2026-03-26'::DATE,    -- data_getnet
    '2026-03-28'::Date,    -- data_totvs
    5::NUMERIC,            -- tolerancia_pct
    3::INTEGER             -- tolerancia_dias
  ) as score;

-- Resultado esperado: 0.650 (0.5 valor + 0.15 data + 0.2 nf)
-- Diferença valor: (|1500-1515|/1515)*100 = 1% < 5% ✓ → 0.5
-- Diferença dias: |2| dias <= 3 dias ✓ → 0.15
-- Nf encontrado: ✓ → 0.2
-- Total: 0.650
```

✅ **OK:** score = 0.650

❌ **FALHA:** Função não calculando corretamente (verificar lógica)

---

## FASE 4: SQL de Dados de Teste

Inserir 1 filial + 1 transação + 1 título + 1 vínculo para testes:

```sql
-- ============================================================================
-- DADOS DE TESTE (Filial 001)
-- ============================================================================

-- 1. Inserir filial de teste
INSERT INTO filiais (filial_cnpj, nome_filial, uf, razao_social, codigo_ec, ativo)
VALUES (
  '84943067001393',
  'Filial 001 — Teste',
  'SP',
  'Minusa Tratorpeças Ltda',
  'EC-001',
  true
)
ON CONFLICT (filial_cnpj) DO NOTHING;

-- 2. Inserir 1 transação GETNET
INSERT INTO transacoes_getnet (
  filial_cnpj, nsu, autorizacao,
  data_venda, hora_venda,
  valor_venda, valor_liquido, valor_parcela,
  parcelas, bandeira, modalidade, codigo_ec,
  status, hash_transacao, eh_duplicata
)
VALUES (
  '84943067001393',
  '000001234',
  '123456',
  '2026-03-26'::DATE,
  '11:07:56'::TIME,
  1500.00,
  1485.00,
  1485.00,
  1,
  'Visa Crédito',
  'credito',
  'EC-001',
  'pendente',
  sha256('84943067001393|000001234|123456|1500.00|2026-03-26')::text,
  false
)
ON CONFLICT (filial_cnpj, nsu, autorizacao, data_venda) DO NOTHING;

-- 3. Inserir 1 título TOTVS
INSERT INTO titulos_totvs (
  filial_cnpj, numero_titulo, numero_nf, especie, serie, numero, parcela,
  tipo_titulo,
  data_emissao, data_vencimento,
  valor_bruto, valor_liquido,
  cliente_codigo, cliente_nome,
  status
)
VALUES (
  '84943067001393',
  'NF-001234-A1',
  'NF-001234',
  'NF',
  '001',
  '001234',
  'a1',
  'NF',
  '2026-03-20'::DATE,
  '2026-05-28'::DATE,
  1515.00,
  1515.00,
  'GETNET',
  'GETNET DO BRASIL',
  'aberto'
)
ON CONFLICT (filial_cnpj, numero_titulo) DO NOTHING;

-- 4. Inserir 1 vínculo de teste (automático, high score)
INSERT INTO conciliacao_vinculos (
  filial_cnpj,
  transacao_getnet_id,
  titulo_totvs_id,
  numero_nf_informado,
  tipo_vinculacao,
  diferenca_valor,
  diferenca_dias,
  score_confianca,
  origem,
  status,
  criado_por
)
SELECT
  '84943067001393',
  tg.transacao_id,
  tt.titulo_id,
  'NF-001234',
  'automatico',
  ABS(tg.valor_venda - tt.valor_bruto),
  ABS(EXTRACT(DAY FROM tg.data_venda - tt.data_vencimento))::INTEGER,
  0.850,  -- 85% (manual para teste)
  'automatico',
  'sugerido',  -- Pronto para supervisor validar
  'system@teste'
FROM transacoes_getnet tg
JOIN titulos_totvs tt ON tg.filial_cnpj = tt.filial_cnpj
WHERE tg.filial_cnpj = '84943067001393'
  AND tg.nsu = '000001234'
  AND tt.numero_nf = 'NF-001234'
ON CONFLICT (transacao_getnet_id, titulo_totvs_id) DO NOTHING;

-- Verificação rápida
SELECT 'Filiais' as recurso, COUNT(*) as total FROM filiais
UNION ALL
SELECT 'Transações GETNET', COUNT(*) FROM transacoes_getnet
UNION ALL
SELECT 'Títulos TOTVS', COUNT(*) FROM titulos_totvs
UNION ALL
SELECT 'Vínculos', COUNT(*) FROM conciliacao_vinculos;
```

**Resultado Esperado:**
```
recurso                | total
=======================|=======
Filiais                | 1
Transações GETNET      | 1
Títulos TOTVS          | 1
Vínculos               | 1
```

✅ **OK:** 4 registros inseridos

❌ **FALHA:** Verificar mensagens de erro (constraints, FK, etc)

---

## FASE 5: Testar RLS com 2 Usuários

### Pré-requisito: Criar 2 Usuários de Teste

**Local:** Supabase Dashboard → Authentication → Users

1. **Usuário 1: Operador da Filial 001**
   ```
   Email: operador@teste.com
   Senha: [gerar]
   Role: operador_filial
   ```

2. **Usuário 2: Supervisor**
   ```
   Email: supervisor@teste.com
   Senha: [gerar]
   Role: supervisor
   ```

✅ **Se OK:** 2 usuários criados com status "Confirmed"

---

### Teste 1: Operador vê Apenas Sua Filial

**Contexto:** Logged in como `operador@teste.com` com `user_filiais_cnpj.filial_cnpj = '84943067001393'`

```sql
-- Consulta como operador
SELECT filial_cnpj, COUNT(*) as transacoes
FROM transacoes_getnet
GROUP BY filial_cnpj;

-- Resultado esperado:
-- filial_cnpj      | transacoes
-- ================|===========
-- 84943067001393   | 1
-- (Outras filiais NÃO aparecem)
```

✅ **OK:** Operador vê APENAS a filial 84943067001393

❌ **FALHA:** Operador vê outras filiais (RLS não funcionando)

---

### Teste 2: Supervisor vê Todas as Filiais

**Contexto:** Logged in como `supervisor@teste.com` com `auth.jwt() ->> 'role' = 'supervisor'`

```sql
-- Consulta como supervisor
SELECT filial_cnpj, COUNT(*) as transacoes
FROM transacoes_getnet
GROUP BY filial_cnpj
ORDER BY filial_cnpj;

-- Resultado esperado:
-- filial_cnpj      | transacoes
-- ================|===========
-- 84943067001393   | 1
-- [Outras filiais aparecem se existirem]
```

✅ **OK:** Supervisor vê TODAS as filiais

❌ **FALHA:** Supervisor não consegue ler dados (RLS muito restritivo)

---

### Teste 3: Admin vê e Modifica config_parametros

**Contexto:** Logged in como admin (bearer token com role = 'admin')

```sql
-- Ler parâmetros
SELECT chave, valor
FROM config_parametros
WHERE chave = 'tolerancia_valor_pct';

-- Esperado: 5

-- Atualizar parâmetro
UPDATE config_parametros
SET valor = '10'
WHERE chave = 'tolerancia_valor_pct';

-- Ler novamente
SELECT valor FROM config_parametros WHERE chave = 'tolerancia_valor_pct';

-- Esperado: 10
```

✅ **OK:** Admin consegue ler e atualizar

❌ **FALHA:** Admin não consegue (problema com RLS ou token)

---

### Teste 4: Operador Não Consegue Modificar config_parametros

**Contexto:** Logged in como `operador@teste.com`

```sql
-- Tentar atualizar parâmetro (deve falhar com 403)
UPDATE config_parametros
SET valor = '20'
WHERE chave = 'tolerancia_valor_pct';

-- Resultado esperado: ERROR (403 Forbidden ou RLS violation)
```

✅ **OK:** Operador recebe erro 403

❌ **FALHA:** Operador consegue modificar (RLS não protegendo)

---

## FASE 6: Ordem Exata de Execução (Production)

Ao fazer deploy final em Produção, seguir esta ordem:

### Passo 1: Backup (Opcional, só se há dados)
```bash
# Se já há dados no Supabase, fazer backup
pg_dump -h [host] -U postgres -d [seu-db] > backup_antes_v3.0.sql
```

### Passo 2: Deploy Schema
```bash
# No SQL Editor Supabase, executar schema_nexus_v3.0.sql
# (ou via CLI: psql -h [host] -U postgres -d [seu-db] < schema_nexus_v3.0.sql)
```

### Passo 3: Verificação (Phase 3 acima)
```sql
-- Executar todos os 11 checks de validação
```

### Passo 4: Inserir Dados Iniciais
```sql
-- Inserir filial matriz + parâmetros iniciais
-- (se houver dados antigos, migrar)
```

### Passo 5: Testes RLS (Phase 5 acima)
```
-- Criar usuários de teste
-- Executar 4 testes RLS
```

### Passo 6: Go Live
```
-- Import GETNET v2.1 comanda: python backend/import_getnet.py --upload
-- Iniciar FlutterFlow
-- Monitorar Supabase logs
```

---

## Troubleshooting

### Erro: "Extension uuid-ossp does not exist"

```bash
# Solução:
1. Dashboard → Extensions → Procurar "uuid-ossp"
2. Clicar "Create"
3. Aguardar ~30s
4. Tentar executar schema novamente
```

---

### Erro: "permission denied for schema public"

```bash
# Solução:
1. Usar Supabase Dashboard SQL Editor (não CLI externo)
2. Verificar se está logado como postgres (admin)
3. Tentar:
   GRANT ALL ON SCHEMA public TO postgres;
   GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres;
```

---

### Erro: "RLS policy missing"

```bash
# Solução:
1. Reexecutar schema_nexus_v3.0.sql
2. Se erro persiste, deletar tabela e recriar:
   DROP TABLE [tabela] CASCADE;
   -- Executar a parte relevante do schema
```

---

### Erro: "Function calcular_score_matching not found"

```bash
# Solução:
1. Verificar se postgresql LANG foi criada:
   CREATE LANGUAGE IF NOT EXISTS plpgsql;
2. Reexecutar função:
   CREATE OR REPLACE FUNCTION calcular_score_matching(...) RETURNS NUMERIC AS $$...
```

---

### Erro: "RLS violation" em queries normais

```bash
# Solução:
1. Verificar se JWT token tem "role" claim:
   SELECT auth.jwt() ->> 'role';
2. Se NULL, adicionar via Supabase Auth:
   - Criar usuário com perfil correto em user_filiais_cnpj
   - Usar Custom Claims (se disponível)
3. Testar novamente
```

---

## Checklist Final

- [ ] Schema v3.0 executado sem erros
- [ ] Todas as 7 tabelas criadas
- [ ] Todos 5 ENUMs existem
- [ ] Todos 12+ índices criados
- [ ] 2 funções operacionais
- [ ] 4 triggers ativos
- [ ] 3 views retornam dados
- [ ] 7+ RLS policies ativas
- [ ] config_parametros com 6 parâmetros
- [ ] 1 filial de teste inserida
- [ ] 1 transação GETNET de teste
- [ ] 1 título TOTVS de teste
- [ ] 1 vínculo de teste
- [ ] Operador vê APENAS sua filial
- [ ] Supervisor vê TODAS filiais
- [ ] Admin consegue modificar config
- [ ] Operador NÃO consegue modificar config
- [ ] Função scoring calcula corretamente
- [ ] Views retornam dados esperados
- [ ] Pronto para FlutterFlow integrar

---

**✅ STATUS: PRONTO PARA DEPLOY**

Data: 2026-04-25  
Próxima ação: Iniciar import_getnet.py v2.1 ou FlutterFlow
Tempo total estimado: **30 minutos** (incluindo verificações)

---

## Resumo das 3 Tarefas

| Task | Arquivo(s) | Status |
|------|-----------|--------|
| 1. Skills | `nexus-postgresql`, `nexus-python-backend`, `nexus-flutterflow`, `nexus-ux` | ✅ 4 skills, 2.000+ linhas |
| 2. Schema | `schema_nexus_v3.0.sql` + `DIFF_v2.1_vs_v3.0.md` | ✅ Completo, idempotente |
| 3. Checklist | `CHECKLIST_SUPABASE.md` (este arquivo) | ✅ 6 fases, 11 checks, troubleshooting |

**🎉 NEXUS v3.0 PRONTO PARA PRODUÇÃO**
