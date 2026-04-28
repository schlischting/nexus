# PROMPT MASTER — Claude Code Nexus v3.0

## Contexto

Você é o desenvolvedor principal do projeto **Nexus**, sistema de conciliação 
de cartões de crédito GETNET × TOTVS para a Minusa Tratorpeças Ltda (41 filiais).

Antes de qualquer ação, leia obrigatoriamente nesta ordem:

```
1. docs/FLUXO_NEGOCIO.md          ← regras de negócio definitivas
2. docs/REQUISITOS_SCHEMA.md      ← schema PostgreSQL completo
3. docs/INTEGRACAO_TOTVS.md       ← integração Progress Datasul
4. ANALISE_PROBLEMAS.md           ← problemas já identificados e corrigidos
5. database/schema_nexus.sql      ← schema atual (base para atualizar)
6. backend/import_getnet.py       ← script já funcionando (v2.1)
```

---

## Status Atual do Projeto

### ✅ Concluído e validado:
- `backend/import_getnet.py` v2.1 — funcionando
  - Lê aba "Detalhado" do Excel GETNET (skiprows=7)
  - Filtra apenas TIPO DE LANÇAMENTO = 'Vendas'
  - Hash: SHA256(cnpj|nsu|auth|data|valor)
  - Processa todos os CNPJs ou filtra por um
  - 1.190 transações únicas de 8.990 linhas
  - Dry-run testado e validado
- Fluxo de negócio 100% definido (ver FLUXO_NEGOCIO.md)
- Schema v2.0 gerado (precisa atualização para v3.0)

### ⏳ Pendente (executar nesta sessão):
1. Gerar schema_nexus.sql v3.0 definitivo
2. Criar skills especializadas
3. Preparar para subir no Supabase

---

## TAREFA 1 — Skills Especializadas

Crie 4 skills em `/mnt/skills/user/`:

### skill: `nexus-postgresql`
Local: `/mnt/skills/user/nexus-postgresql/SKILL.md`
Conteúdo:
- Padrões RLS multi-tenant por filial_cnpj
- Views de alertas (vw_nsu_sem_titulo, vw_titulo_sem_nsu)
- Função calcular_score_matching()
- Índices para performance
- Convenções Supabase específicas do Nexus

### skill: `nexus-python-backend`
Local: `/mnt/skills/user/nexus-python-backend/SKILL.md`
Conteúdo:
- Padrões do import_getnet.py (já funcionando)
- Como criar novos importers (totvs_import.py)
- Padrão do totvs_client.py (mock → produção)
- Exportação JSON Nexus → TOTVS
- Tratamento de erros e reprocessamento

### skill: `nexus-flutterflow`
Local: `/mnt/skills/user/nexus-flutterflow/SKILL.md`
Conteúdo:
- Estrutura das telas (operador/supervisor/admin)
- Integração Supabase RLS no front
- Componentes de alerta (🔴🟡✅)
- Real-time subscriptions para gaps
- Perfis e permissões no FlutterFlow

### skill: `nexus-ux`
Local: `/mnt/skills/user/nexus-ux/SKILL.md`
Conteúdo:
- Dashboard operador (gaps por filial)
- Dashboard supervisor (visão consolidada)
- Fluxo de lançamento NSU + NF
- Fluxo de validação supervisor
- Padrões visuais de status (cores, ícones)

---

## TAREFA 2 — Schema v3.0 Definitivo

Reescreva `database/schema_nexus.sql` do zero incorporando
TUDO que está em `docs/REQUISITOS_SCHEMA.md`.

Estrutura obrigatória do arquivo:
```sql
-- 1. Extensões necessárias
-- 2. Enums
-- 3. Tabela: filiais
-- 4. Tabela: user_filiais
-- 5. Tabela: transacoes_getnet
-- 6. Tabela: titulos_totvs
-- 7. Tabela: conciliacao_vinculos
-- 8. Tabela: config_parametros (com dados iniciais)
-- 9. Índices
-- 10. Função: update_timestamp()
-- 11. Triggers de auditoria
-- 12. Função: calcular_score_matching()
-- 13. Views: vw_nsu_sem_titulo, vw_titulo_sem_nsu, vw_sugestoes_supervisor
-- 14. RLS Policies
-- 15. Dados iniciais: config_parametros
```

Após gerar, mostre checklist do que mudou vs v2.0.

---

## TAREFA 3 — Checklist Supabase

Gere `database/CHECKLIST_SUPABASE.md` com:

1. O que configurar no Dashboard ANTES de executar SQL
2. SQL de sanidade para rodar APÓS o schema
   (valida tabelas, policies, functions, views)
3. SQL de dados de teste
   (1 filial + 1 transação + 1 título + 1 vínculo)
4. Como testar RLS com 2 usuários diferentes
5. Ordem exata de execução

---

## REGRAS PARA ESTA SESSÃO

- Leia os docs ANTES de qualquer código
- Schema deve ser idempotente (pode rodar 2x sem erro)
- Mantenha import_getnet.py intacto (já funcionando)
- Use filial_cnpj CHAR(14) em TUDO (nunca filial_id como FK)
- RLS baseado em filial_cnpj via user_filiais
- Supervisor tem acesso a todas filiais (sem filtro RLS)
- Admin bypass total de RLS
- Documente cada tabela com COMMENT

Execute as 3 tarefas em ordem.
Confirme ao final de cada uma antes de prosseguir.
