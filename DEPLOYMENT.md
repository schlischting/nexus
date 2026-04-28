# NEXUS — Guia de Deployment

Documentação completa para fazer deploy do NEXUS em produção.

## 1. Setup Local

### Verificar Ambiente

```bash
node -v          # Deve ser 18+
npm -v           # Deve ser 9+
git --version    # Git deve estar instalado
```

### Instalar Dependências

```bash
cd nexus_nextjs
npm install      # Instala todas as dependências
```

### Configurar Variáveis

```bash
cp .env.local.example .env.local

# Edite .env.local com credenciais Supabase reais:
# NEXT_PUBLIC_SUPABASE_URL=https://[projeto].supabase.co
# NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
# SUPABASE_SERVICE_ROLE_KEY=eyJ...
```

## 2. Variáveis de Ambiente

### Ambiente Local (.env.local)

```env
NEXT_PUBLIC_SUPABASE_URL=https://seu-projeto.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
NEXT_PUBLIC_APP_URL=http://localhost:3400
NEXT_PUBLIC_ENABLE_ANALYTICS=true
```

### Ambiente Produção (.env.production)

```env
NEXT_PUBLIC_SUPABASE_URL=https://seu-projeto.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...
NEXT_PUBLIC_APP_URL=https://nexus.minusa.com.br
NEXT_PUBLIC_ENABLE_ANALYTICS=true
```

⚠️ **NUNCA commitar arquivos .env**

## 3. Testes Antes de Deploy

### 3.1 Validação Completa

```bash
npm run validate
```

Executa:
- TypeScript type check
- ESLint linting
- Next.js build

### 3.2 Teste Local

```bash
npm run dev
# Acessa http://localhost:3400
```

Verificar:
- [ ] Login funciona
- [ ] Dashboard carrega dados
- [ ] Real-time updates funcionam
- [ ] API routes respondem

### 3.3 Build de Produção

```bash
npm run build
npm start
```

Deve iniciar sem erros na porta 3400.

## 4. Deploy Vercel

### 4.1 Preparar Git

```bash
git status                    # Verificar mudanças
git add .
git commit -m "NEXUS deployment ready"
git push origin main          # Push para main branch
```

### 4.2 Conectar ao Vercel

1. Ir para https://vercel.com
2. Login com GitHub
3. Clicar "New Project"
4. Selecionar repositório GitHub
5. Importar `nexus_nextjs` folder

### 4.3 Configurar Variáveis

Em Vercel → Settings → Environment Variables:

```
NEXT_PUBLIC_SUPABASE_URL         = https://[projeto].supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY    = eyJ...
SUPABASE_SERVICE_ROLE_KEY        = eyJ... (marcar como Secret)
NEXT_PUBLIC_APP_URL              = https://nexus.minusa.com.br
NEXT_PUBLIC_ENABLE_ANALYTICS     = true
```

### 4.4 Fazer Deploy

Opção 1: Deploy automático
- Vercel faz deploy automaticamente quando faz push para `main`

Opção 2: Deploy manual
- Vercel Dashboard → Deploy button

### 4.5 Verificar Sucesso

```
✓ Deploy completo em 3-5 minutos
✓ URL: https://[projeto].vercel.app
✓ Logs disponíveis em Vercel Dashboard
```

## 5. Deploy Docker (Alternativo)

### 5.1 Build Docker Image

```bash
docker build -t nexus:latest .
```

### 5.2 Executar Container

```bash
docker run -d \
  --name nexus \
  -p 3400:3400 \
  --env-file .env.production \
  nexus:latest
```

### 5.3 Usar Docker Compose

```bash
# Criar .env.production primeiro
docker-compose up -d
```

Verificar:
```bash
docker ps                    # Verifica se container está rodando
docker logs nexus            # Ver logs
curl http://localhost:3400   # Testar health check
```

## 6. Monitoramento

### 6.1 Health Check

```bash
# Deve retornar 200 OK
curl https://nexus.minusa.com.br/api/health

# Resposta esperada:
# {
#   "status": "ok",
#   "timestamp": "2026-04-28T10:00:00Z",
#   "database": "connected",
#   "version": "1.0.0"
# }
```

### 6.2 Monitoramento de Logs

**Vercel:**
- Vercel Dashboard → Deployments → View Logs
- Monitorar erros, warnings, performance

**Supabase:**
- Supabase Dashboard → Database Logs
- Ver queries lentas, erros de RLS

**Sentry (Opcional):**
```bash
npm install @sentry/nextjs
# Configurar em instrumentation.ts
```

### 6.3 Alertas

Configurar alertas para:
- [ ] Build failure
- [ ] Deployment error
- [ ] Database connection loss
- [ ] API response time > 1s
- [ ] RLS policy violations

### 6.4 Performance

Verificar:
```bash
# Vercel Analytics
# Vercel Dashboard → Analytics
# Monitorar:
# - Core Web Vitals
# - Response time
# - Deploy size
```

## 7. Troubleshooting

### Erro: "Missing environment variables"
**Solução:**
1. Verificar Vercel → Settings → Environment Variables
2. Fazer redeploy (`git push` ou manual)
3. Verificar credenciais Supabase

### Erro: "RLS policy violation"
**Solução:**
1. Verificar user tem filial em `user_filiais_cnpj`
2. Verificar RLS policies no Supabase
3. Executar `schema_nexus_v3.0.sql` novamente

### Erro: "Database connection timeout"
**Solução:**
1. Verificar Supabase status em uptime.com
2. Testar conexão em Supabase Dashboard
3. Aumentar timeout em Vercel se necessário

### Deploy lento
**Solução:**
1. Verificar tamanho do `.next` build (deve ser < 50MB)
2. Implementar code splitting
3. Usar `npm run build -- --analyze` para analisar bundle

### Erro 502/503
**Solução:**
1. Verificar logs em Vercel
2. Verificar status de Supabase
3. Fazer manual redeploy

## 8. Rollback

Se algo der errado em produção:

### Via Vercel

1. Vercel Dashboard → Deployments
2. Clicar no deployment anterior
3. Clicar "Promote to Production"

### Via Git

```bash
git revert HEAD~1           # Reverte último commit
git push origin main        # Faz push
# Vercel faz deploy automaticamente
```

### Via Docker

```bash
docker ps -a                # Listar containers
docker start [container-id] # Iniciar versão anterior
```

## 9. Checklist Pré-Deploy

Antes de fazer deploy, verificar:

**Código**
- [ ] `npm run validate` passa (type-check, lint, build)
- [ ] Sem console.log ou debugger statements
- [ ] Sem TODO ou FIXME comments (ou documentados)
- [ ] Código formatado (prettier)

**Banco de Dados**
- [ ] Schema criado em Supabase
- [ ] RLS policies configuradas
- [ ] Índices criados
- [ ] Dados de teste inseridos

**Variáveis**
- [ ] `.env.local` preenchido (desenvolvimento)
- [ ] `.env.production` preenchido (produção)
- [ ] Vercel com variáveis de env (não em git)
- [ ] Secrets marcados como Secret no Vercel

**Testing**
- [ ] Login funciona
- [ ] Dashboard operador carrega dados
- [ ] Dashboard supervisor funciona
- [ ] Novo lançamento cria vinculos
- [ ] Export funciona
- [ ] Real-time updates funcionam

**Deploy**
- [ ] Git commitado e clean (`git status` vazio)
- [ ] Push para main branch
- [ ] Vercel build concluído com sucesso
- [ ] Aplicação abre em produção URL
- [ ] HTTPS working
- [ ] Login funciona em produção
- [ ] RLS funciona (filter by filial)

**Pós-Deploy**
- [ ] Health check retorna 200
- [ ] Monitora logs por 30 minutos
- [ ] Comunica time sobre deploy

## 10. Cronograma de Releases

```
Deploy Schedule:
├── Development     → localhost:3400
├── Preview        → nexus-pr.vercel.app (PRs)
└── Production     → nexus.minusa.com.br (main)

Release Cycle:
├── Weekly releases (segundas 10:00 AM)
├── Emergency hotfixes (immediate)
└── Major features (coordenadas com stakeholders)
```

## Documentação Relacionada

- `README.md` — Overview do projeto
- `SETUP_GUIDE.md` — Setup local (15 passos)
- `../../database/schema_nexus_v3.0.sql` — Database schema
- `../../docs/CHECKLIST_SUPABASE.md` — Supabase setup

## Contato & Suporte

**Tech Lead:** rodrigominusa@minusa.com.br
**Status Page:** (será adicionado)
**Slack Channel:** #nexus-deployments

---

**Versão:** 1.0.0  
**Última atualização:** 2026-04-28  
**Mantido por:** Minusa Tech Team
