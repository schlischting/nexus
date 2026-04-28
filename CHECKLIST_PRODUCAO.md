# NEXUS — Checklist de Produção

Checklist completo para garantir que tudo está pronto para fazer deploy em produção.

## Fase 1: Preparação do Código

### 1.1 Limpeza e Validação

- [ ] Sem console.log / console.error statements (exceto em error boundaries)
- [ ] Sem debugger statements
- [ ] Sem TODO / FIXME comments (ou documentados com prazo)
- [ ] Sem commented-out code
- [ ] Sem imports não utilizados
- [ ] Formatação Prettier aplicada

```bash
npm run format
npm run lint
```

### 1.2 TypeScript e Build

- [ ] Sem erros de TypeScript: `npm run type-check` passa ✓
- [ ] Build compilado com sucesso: `npm run build` passa ✓
- [ ] Sem warnings durante build
- [ ] `.next` gerado corretamente

```bash
npm run type-check
npm run build
```

### 1.3 Validação Completa

- [ ] Script validate.sh passa: `npm run validate` ✓

```bash
bash scripts/validate.sh
```

## Fase 2: Banco de Dados

### 2.1 Schema PostgreSQL

- [ ] Schema `schema_nexus_v3.0.sql` executado no Supabase ✓
- [ ] 6 tabelas criadas (filiais, user_filiais_cnpj, user_filiais, transacoes_getnet, titulos_totvs, conciliacao_vinculos)
- [ ] 3 views criadas (vw_nsu_sem_titulo, vw_titulo_sem_nsu, vw_sugestoes_supervisor)
- [ ] 2 RPC functions criadas (calcular_score_matching, exportar_para_totvs)

### 2.2 Índices e Performance

- [ ] Índices criados em colunas de filtro:
  - [ ] filial_cnpj
  - [ ] nsu
  - [ ] numero_nf
  - [ ] status_transacao
  - [ ] status_titulo
  - [ ] status_vinculo

### 2.3 Row-Level Security (RLS)

- [ ] RLS habilitado em todas as tabelas ✓
- [ ] Policies configuradas:
  - [ ] user_filiais_cnpj: users can see own filiais
  - [ ] user_filiais: users can see own perfil
  - [ ] transacoes_getnet: operador sees own filial only
  - [ ] titulos_totvs: operador sees own filial only
  - [ ] conciliacao_vinculos: operador sees own filial only
  - [ ] config_parametros: admin only

### 2.4 Dados de Teste (Opcional)

- [ ] Filiais de teste inseridas
- [ ] Transações GETNET de teste
- [ ] Títulos TOTVS de teste
- [ ] Usuários de teste criados

```bash
npm run seed
```

## Fase 3: Variáveis de Ambiente

### 3.1 Desenvolvimento

- [ ] `.env.local` criado (copy from `.env.local.example`)
- [ ] `NEXT_PUBLIC_SUPABASE_URL` preenchido
- [ ] `NEXT_PUBLIC_SUPABASE_ANON_KEY` preenchido (pública)
- [ ] `SUPABASE_SERVICE_ROLE_KEY` preenchido (nunca commitar!)
- [ ] `NEXT_PUBLIC_APP_URL=http://localhost:3400`
- [ ] `NEXT_PUBLIC_ENABLE_ANALYTICS=true`

### 3.2 Produção

- [ ] `.env.production` criado (diferente de `.env.local`)
- [ ] `NEXT_PUBLIC_SUPABASE_URL` = produção Supabase
- [ ] `NEXT_PUBLIC_SUPABASE_ANON_KEY` = anon key produção
- [ ] `SUPABASE_SERVICE_ROLE_KEY` = service role key produção
- [ ] `NEXT_PUBLIC_APP_URL=https://nexus.minusa.com.br`

### 3.3 Vercel Dashboard

- [ ] Variáveis de environment configuradas em Vercel:
  - [ ] NEXT_PUBLIC_SUPABASE_URL
  - [ ] NEXT_PUBLIC_SUPABASE_ANON_KEY
  - [ ] SUPABASE_SERVICE_ROLE_KEY (marcado como Secret)
  - [ ] NEXT_PUBLIC_APP_URL
  - [ ] NEXT_PUBLIC_ENABLE_ANALYTICS

⚠️ **Nunca fazer commit de .env files**

## Fase 4: Testes Locais

### 4.1 Desenvolvimento em Localhost

- [ ] `npm run dev` inicia sem erros
- [ ] App abre em http://localhost:3400 ✓
- [ ] Não há erros no console

### 4.2 Autenticação

- [ ] Login page carrega
- [ ] Login com email/password funciona
- [ ] Redirection após login funciona:
  - [ ] Operador → /operador/dashboard
  - [ ] Supervisor → /supervisor/dashboard
- [ ] Logout funciona

### 4.3 Dashboard Operador

- [ ] Dashboard carrega
- [ ] Métricas exibem dados corretos:
  - [ ] NSU sem Título count
  - [ ] Título sem NSU count
  - [ ] Sugestões Automáticas count
  - [ ] Taxa de Sucesso %
- [ ] Tabelas carregam dados
- [ ] Real-time updates funcionam (indicador verde)

### 4.4 Novo Lançamento

- [ ] Página abre com stepper 3-step
- [ ] **Step 1**: Buscar NSU funciona
- [ ] **Step 2**: Selecionar NF funciona
- [ ] **Step 3**: Score calcula corretamente
- [ ] Botões Confirmar/Rejeitar funcionam
- [ ] Volta para dashboard após confirmar

### 4.5 Dashboard Supervisor

- [ ] Dashboard supervisor carrega
- [ ] Abas funcionam (Automáticos, Sugestões, Manual)
- [ ] MatchSuggestion cards exibem corretamente
- [ ] Score progress bars mostram cores corretas
- [ ] Confirmar/Rejeitar funcionam
- [ ] Seleção e export funcionam

### 4.6 API Routes

- [ ] `GET /api/health` retorna 200 OK
- [ ] `GET /api/health` com status estruturado
- [ ] `POST /api/auth` retorna user + perfil + filiais
- [ ] `POST /api/vinculos` cria vinculo
- [ ] `PUT /api/vinculos` confirma/rejeita
- [ ] `POST /api/export` exporta para TOTVS

```bash
curl http://localhost:3400/api/health
```

### 4.7 Performance

- [ ] Build size < 50MB
- [ ] Initial page load < 3s
- [ ] API responses < 1s
- [ ] Real-time updates < 2s
- [ ] Nenhum memory leak (F12 → Memory)

## Fase 5: Git & Deploymentreadiness

### 5.1 Git Status

- [ ] `git status` limpo (nada não-tracked)
- [ ] Todos os arquivos commitados
- [ ] Nenhuma mudança local

```bash
git status
git add .
git commit -m "NEXUS production ready"
```

### 5.2 Código Publicável

- [ ] Sem credenciais em código
- [ ] Sem hardcoded URLs (usar env vars)
- [ ] Sem logs sensíveis
- [ ] Sem TODO para produção

### 5.3 GitHub

- [ ] Branch `main` está sincronizado
- [ ] Push para origin main concluído
- [ ] GitHub Actions workflow passou

```bash
git push origin main
# Aguardar GitHub Actions passar
```

## Fase 6: Deploy Vercel

### 6.1 Vercel Setup

- [ ] Vercel account criada e logada
- [ ] Repositório GitHub conectado
- [ ] Projeto `nexus_nextjs` importado

### 6.2 Variáveis de Ambiente

- [ ] Todas as 5 variáveis configuradas
- [ ] `SUPABASE_SERVICE_ROLE_KEY` marcado como Secret
- [ ] Nenhuma variável vazia

### 6.3 Deploy

- [ ] `git push origin main` feito
- [ ] Vercel inicia build automaticamente
- [ ] Build completa em < 5 minutos
- [ ] Nenhum erro no build log

### 6.4 Verificação Pós-Deploy

- [ ] Deploy marcado como "Production"
- [ ] URL https://[projeto].vercel.app acessível
- [ ] HTTPS válido (cadeado verde)
- [ ] Sem 4xx/5xx errors

## Fase 7: Testes em Produção

### 7.1 Acesso Básico

- [ ] App abre em produção URL
- [ ] HTTPS funciona
- [ ] Sem mixed content warnings
- [ ] Sem console errors

### 7.2 Autenticação

- [ ] Login page carrega
- [ ] Login funciona
- [ ] Redirection funciona
- [ ] Session persiste após refresh

### 7.3 Dados e RLS

- [ ] Operador vê apenas sua filial
- [ ] Supervisor vê todas filiais
- [ ] Dados de teste aparecem corretamente
- [ ] Nenhum erro RLS no console

### 7.4 Funcionalidades

- [ ] Dashboard carrega dados ✓
- [ ] Novo lançamento funciona ✓
- [ ] Score calcula ✓
- [ ] Export funciona ✓
- [ ] Real-time updates funcionam ✓

### 7.5 Health Check

- [ ] `GET /api/health` retorna 200
- [ ] Response time < 1s
- [ ] Database conectado
- [ ] Ambiente correto

```bash
curl https://nexus.minusa.com.br/api/health | jq .
```

## Fase 8: Monitoramento

### 8.1 Logs

- [ ] Vercel Logs sem errros críticos
- [ ] Supabase Logs normais
- [ ] Nenhum RLS violation
- [ ] Nenhum database connection error

### 8.2 Performance

- [ ] Vercel Analytics ativado
- [ ] Core Web Vitals bons (LCP < 2.5s, FID < 100ms, CLS < 0.1)
- [ ] Deploy size < 50MB
- [ ] Response time < 500ms

### 8.3 Alertas

- [ ] Slack notifications configuradas (opcional)
- [ ] Email alerts para erro crítico
- [ ] Monitoramento de uptime (opcional: status.io ou uptime.com)

## Fase 9: Rollback Plan

### 9.1 Git Rollback

```bash
# Se preciso reverter
git revert HEAD~1
git push origin main
# Vercel faz redeploy automaticamente
```

### 9.2 Vercel Rollback

1. Vercel Dashboard → Deployments
2. Clicar no deployment anterior
3. Clicar "Promote to Production"

### 9.3 Database Rollback

- [ ] Backup PostgreSQL acessível
- [ ] Procedimento de rollback documentado

## Fase 10: Comunicação

### 10.1 Notifications

- [ ] Slack #deployments notificado
- [ ] Team message enviada (se aplicável)
- [ ] Changelog documentado

### 10.2 Documentação

- [ ] README.md atualizado
- [ ] DEPLOYMENT.md consultado
- [ ] Usuários sabem como acessar

## Checklist Final

```
✅ Código validado (type-check, lint, build)
✅ Banco de dados pronto (schema, RLS, índices)
✅ Variáveis configuradas (dev + prod)
✅ Testes locais passaram
✅ Git limpo e sincronizado
✅ Vercel variáveis configuradas
✅ Deploy completado com sucesso
✅ Testes em produção passaram
✅ Health check retorna ok
✅ Monitoramento ativo
✅ Rollback plan pronto
✅ Team notificado

🎉 PRONTO PARA PRODUÇÃO!
```

---

**Deploy Date:** ________________  
**Deployed By:** ________________  
**Approved By:** ________________  
**Notes:** ________________________________________________________________________

---

**Versão:** 1.0.0  
**Última atualização:** 2026-04-28  
**Próxima review:** 2026-05-05
