# NEXUS — Next.js 15 Rewrite

Sistema de conciliação automática de transações GETNET com títulos TOTVS, desenvolvido com Next.js 15, React 19, TypeScript e Supabase.

## Sobre

O NEXUS é uma aplicação web progressiva (PWA) que realiza reconciliação inteligente entre:

- **GETNET**: Sistema de adquirência de cartões de crédito
- **TOTVS**: ERP com módulo de contas a receber

Utiliza um algoritmo de score matching que leva em conta:
- Diferença de valores (peso 50%, tolerância ±5%)
- Diferença de datas (peso 30%, tolerância ±3 dias)
- Correspondência de NF (peso 20%)

## Stack Tecnológico

### Frontend
- **Next.js 15.0.0** com App Router
- **React 19.0.0** com Server/Client Components
- **TypeScript 5.3.3** com strict mode
- **TailwindCSS** para estilos
- **shadcn/ui** para componentes base
- **React Hook Form** + **Zod** para validação
- **Zustand** para gerenciamento de estado
- **Sonner** para notificações

### Backend
- **Node.js** via Vercel Functions
- **Supabase** para autenticação e banco de dados
- **PostgreSQL** com RLS (Row Level Security)

### Deployment
- **Vercel** (Brasil, São Paulo - sao1)
- **Supabase Hosting** (PostgreSQL gerenciado)

## Estrutura do Projeto

```
nexus_nextjs/
├── app/                       # App Router (Next.js 15)
│   ├── layout.tsx            # Root layout
│   ├── page.tsx              # Redirect auth
│   ├── globals.css           # Estilos globais
│   ├── (auth)/               # Auth routes
│   │   ├── login/page.tsx
│   │   └── signup/page.tsx
│   ├── (operador)/           # Operador routes (RLS by filial)
│   │   ├── dashboard/page.tsx
│   │   └── lancamento/page.tsx
│   ├── (supervisor)/         # Supervisor routes (all filiais)
│   │   └── dashboard/page.tsx
│   └── api/                  # API routes
│       ├── auth/route.ts
│       ├── vinculos/route.ts
│       └── export/route.ts
├── components/               # React Components
│   └── ui/                  # shadcn/ui + custom
│       ├── button.tsx
│       ├── input.tsx
│       ├── dialog.tsx
│       ├── dropdown-menu.tsx
│       ├── gap-card.tsx
│       ├── match-suggestion.tsx
│       └── dashboard-header.tsx
├── lib/                     # Utilities
│   ├── types.ts            # Domain types
│   ├── utils.ts            # Helper functions
│   ├── api-client.ts       # Fetch wrapper
│   ├── auth.ts             # Auth helpers
│   ├── supabase/           # Supabase queries
│   │   ├── client.ts       # Browser client
│   │   ├── server.ts       # Service role
│   │   └── queries.ts      # DB queries
│   └── store/              # Zustand stores
│       ├── auth-store.ts
│       └── dashboard-store.ts
├── package.json
├── tsconfig.json
├── next.config.js
├── tailwind.config.ts
├── postcss.config.js
├── vercel.json
├── .env.local.example
└── .env.production.example
```

## Recursos Principais

### 1. Dashboard Operador
- Visualização de gaps (NSU sem título, Título sem NSU)
- Métricas em tempo real via Supabase subscriptions
- Novo lançamento (wizard 3-step para criar vinculos)
- RLS automático por filial

### 2. Dashboard Supervisor
- Visão de todas as filiais
- Sugestões agrupadas por score (automáticas, pendentes, manual)
- Confirmar/rejeitar vinculos
- Exportar para TOTVS em lote

### 3. Autenticação
- Email + password via Supabase Auth
- JWT tokens com refresh automático
- Perfis: operador_filial, supervisor, admin
- RLS policies por filial_cnpj

### 4. API Routes
- `/api/auth` — Verificar user + perfil + filiais
- `/api/vinculos` — CRUD de vinculos
- `/api/export` — Exportar para TOTVS

## Variáveis de Ambiente

Criar `.env.local` baseado em `.env.local.example`:

```env
# Supabase (public)
NEXT_PUBLIC_SUPABASE_URL=https://[project].supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...

# Supabase (server-side only)
SUPABASE_SERVICE_ROLE_KEY=eyJ...

# App
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_ENABLE_ANALYTICS=true
```

## Instalação

1. **Pré-requisitos**
   - Node.js 18+ (recomendado 20+)
   - npm ou yarn

2. **Clone o repositório**
   ```bash
   cd nexus_nextjs
   ```

3. **Instale dependências**
   ```bash
   npm install
   ```

4. **Configure variáveis**
   ```bash
   cp .env.local.example .env.local
   # Edite .env.local com suas credenciais Supabase
   ```

5. **Execute desenvolvimento**
   ```bash
   npm run dev
   ```
   Acesse http://localhost:3000

## Desenvolvimento

### Scripts Disponíveis

```bash
npm run dev           # Desenvolvimento (hot reload)
npm run build        # Build para produção
npm start            # Inicia server de produção
npm run lint         # ESLint check
npm run type-check   # TypeScript check
npm run format       # Prettier format
```

### Database Setup

Ver `../../docs/CHECKLIST_SUPABASE.md` para:
1. Criar tabelas em PostgreSQL
2. Configurar RLS policies
3. Criar funções (calcular_score_matching, exportar_para_totvs)
4. Criar views (vw_nsu_sem_titulo, vw_titulo_sem_nsu, vw_sugestoes_supervisor)

### Padrões de Código

**Server vs Client Components**
- Use `'use client'` apenas onde necessário (interatividade, hooks)
- Prefira Server Components para queries DB, auth checks
- Server Components com `async` para dados iniciais

**Tipos**
- Types em `lib/types.ts` (nunca duplicar)
- Use `type` para tipos, `interface` raramente
- Strict mode sempre

**Queries**
- Queries em `lib/supabase/queries.ts`
- RLS automático: Supabase filtra por `auth.uid()` + `filial_cnpj`
- Para admin: usar `lib/supabase/server.ts` com service role key

**State Management**
- Zustand stores em `lib/store/`
- Prefira stores para state compartilhado (auth, dashboard)
- Props drilling para state local

**Forms**
- React Hook Form + Zod (na linha)
- Validação em tempo real via `watch()`
- Toast de erro/sucesso via Sonner

## Deployment

### Vercel

1. **Push para GitHub**
   ```bash
   git push origin main
   ```

2. **Connect no Vercel**
   - Importe repositório
   - Configure variáveis em Project Settings
   - Vercel detecta Next.js e faz build automático

3. **Variáveis de Produção**
   ```
   NEXT_PUBLIC_SUPABASE_URL
   NEXT_PUBLIC_SUPABASE_ANON_KEY
   SUPABASE_SERVICE_ROLE_KEY
   NEXT_PUBLIC_APP_URL=https://nexus.minusa.com.br
   ```

4. **Custom Domain**
   - Configurar em Vercel Settings > Domains
   - Apontar DNS para Vercel nameservers

## Testes

### Autenticação
```bash
Email: seu@email.com
Senha: SenhaSegura123!
```

### Fluxo Operador
1. Login como operador
2. Ir para Dashboard
3. Clicar "Novo Lançamento"
4. Buscar NSU
5. Selecionar Título
6. Confirmar vinculo

### Fluxo Supervisor
1. Login como supervisor
2. Ver sugestões por score
3. Confirmar/rejeitar
4. Exportar selecionados para TOTVS

## Troubleshooting

### Erro: "Missing environment variables"
- Verificar `.env.local` com credenciais Supabase
- Executar `npm run dev` novamente

### Erro: "RLS policy violation"
- Verificar user tem filial em `user_filiais_cnpj`
- Verificar policies de RLS no Supabase

### Erro: "Cannot find module"
- Rodar `npm install`
- Verificar `tsconfig.json` paths aliases

### Slow performance
- Verificar índices em PostgreSQL
- Usar `useRealTimeUpdates()` em vez de polling
- Implementar pagination para grandes datasets

## Documentação Adicional

- `SETUP_GUIDE.md` — Step-by-step setup
- `../../database/schema_nexus_v3.0.sql` — Schema PostgreSQL
- `../../docs/FLUXO_NEGOCIO.md` — Fluxo de negócio completo
- `../../docs/CHECKLIST_SUPABASE.md` — Supabase setup

## Support

Para problemas ou dúvidas:
1. Verificar este README
2. Consultar SETUP_GUIDE.md
3. Abrir issue em GitHub

## License

Copyright © 2026 Minusa Tratorpeças Ltda. Todos os direitos reservados.
