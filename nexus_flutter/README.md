# NEXUS — Sistema de Conciliação GETNET + TOTVS

**Versão:** 1.0.0  
**Status:** 🟢 Pronto para Produção  
**Build:** Flutter Web (Vercel)

---

## 📖 O que é Nexus?

Nexus é um sistema de conciliação de cartões de crédito/débito para a Minusa Tratorpeças Ltda. Integra:

- **GETNET:** Adquirente de cartões (maquininha)
- **TOTVS Progress:** ERP interno (PASOE disponível)
- **Supabase:** Backend & Database
- **Flutter Web:** Interface responsiva

**Problema resolvido:** Não há integração nativa entre GETNET e TOTVS. Operadores precisam inserir NSUs manualmente. Nexus automatiza isso com score-based matching.

---

## 🎯 Funcionalidades

### Operador (por filial)
- ✅ Dashboard com 4 alertas (NSU sem título, lançamentos com erro, títulos sem NSU, últimas reconciliações)
- ✅ Lançamento NSU + NF em 3-step wizard
- ✅ Validação automática e score calculation
- ✅ Realtime updates

### Supervisor (todas as filiais)
- ✅ Dashboard consolidado
- ✅ Validação de matches sugeridos (0.75-0.95 score)
- ✅ Exportação em lote para TOTVS
- ✅ Monitoramento de gaps e erros

### Sistema
- ✅ RLS (Row Level Security) automático
- ✅ Autenticação via Supabase Auth
- ✅ Três perfis: operador_filial, supervisor, admin
- ✅ 41 filiais suportadas

---

## 🚀 Setup Local

### 1. Pré-requisitos

```bash
# Flutter 3.13+
flutter --version

# Dart 3.0+
dart --version

# Node.js (para Vercel CLI)
node --version
```

### 2. Clonar e Instalar

```bash
git clone https://github.com/rodrigo/nexus.git
cd nexus_flutter

# Instalar dependências
flutter pub get

# Copiar .env
cp .env.example .env
# Editar .env com suas credenciais Supabase
```

### 3. Executar Localmente

```bash
# No navegador (Chrome/Firefox)
flutter run -d chrome

# App abrirá em http://localhost:5000
```

### 4. Build para Web

```bash
# Build otimizado
flutter build web --release

# Output: build/web/
# Pronto para fazer upload em qualquer servidor web
```

---

## 📋 Variáveis de Ambiente

### .env (local development)
```env
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Vercel Environment Variables (Settings → Environment Variables)
```
SUPABASE_URL=https://prod-projeto.supabase.co
SUPABASE_ANON_KEY=eyJ...prod...
```

---

## 🧪 Testes

### Usuários de Teste

**Operador Filial 001:**
```
Email: operador@filial001.com
Senha: 123456
Role: operador_filial
Filial: 001
```

**Supervisor:**
```
Email: supervisor@nexus.com
Senha: 123456
Role: supervisor
Acesso: Todas as filiais
```

### Casos de Teste

1. **Login:**
   - Operador login → vê dashboard da filial ✅
   - Supervisor login → vê dashboard consolidado ✅

2. **Dashboard Operador:**
   - 4 cards com métricas ✅
   - Seções expandíveis com dados realtime ✅
   - FAB "Novo lançamento" ✅

3. **Lançamento NSU:**
   - Step 1: Buscar NSU com autocomplete ✅
   - Step 2: Selecionar NF ✅
   - Step 3: Score calcula e confirma ✅
   - Vínculo salvo em Supabase ✅

4. **RLS:**
   - Operador 001 não vê dados de Operador 002 ✅
   - Supervisor vê dados de todas as filiais ✅

---

## 📁 Estrutura do Projeto

```
nexus_flutter/
├── lib/
│   ├── main.dart              # Entrada + Router
│   ├── config/
│   │   └── supabase_config.dart
│   ├── models/
│   │   ├── transacao.dart
│   │   ├── titulo.dart
│   │   └── vinculo.dart
│   ├── services/
│   │   └── supabase_service.dart  # Queries + RPC
│   ├── components/
│   │   ├── gap_card.dart
│   │   ├── match_suggestion.dart
│   │   └── dashboard_header.dart
│   └── screens/
│       ├── operador_dashboard.dart
│       ├── lancamento_nsu.dart
│       └── supervisor_dashboard.dart
├── .env.example               # Template variáveis
├── .env.production           # Produção (não commitar)
├── pubspec.yaml              # Dependências
├── vercel.json               # Config Vercel
├── .github/workflows/deploy.yml  # CI/CD
└── README.md                 # Este arquivo
```

---

## 🔧 Dependências Principais

```yaml
supabase_flutter: ^2.0.0       # Backend
go_router: ^13.0.0             # Navegação
provider: ^6.1.0               # State management
uuid: ^4.0.0                   # IDs únicos
intl: ^0.19.0                  # Formatação
dotenv: ^4.1.0                 # .env
```

Ver [pubspec.yaml](pubspec.yaml) para lista completa.

---

## 🌐 Deploy Vercel

### 1-3: Setup Vercel
```bash
vercel login
vercel link
```

### 4-7: Variáveis de Ambiente
Adicionar em **Vercel Dashboard → Settings → Environment Variables:**
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

### 8-10: Deploy
```bash
git push origin main
# Auto-deploy via GitHub webhook
```

**App ativo em:** `https://nexus-xxx.vercel.app`

Ver [DEPLOY_GUIDE.md](DEPLOY_GUIDE.md) para instruções completas.

---

## 🔍 Troubleshooting

### Erro: "RLS policy denying access"
```
Causa: User não associado em user_filiais_cnpj
Solução: 
  1. Ir para Supabase → SQL Editor
  2. Executar:
     INSERT INTO user_filiais_cnpj (user_id, filial_cnpj, perfil_usuario)
     VALUES ('user-uuid', '001', 'operador_filial');
```

### Erro: "SUPABASE_URL not defined"
```
Causa: Variáveis de ambiente não carregadas
Solução:
  1. Verificar .env existe e está preenchido
  2. Em Vercel: Settings → Environment Variables
  3. Fazer redeploy
```

### Dashboard não carrega
```
Causa: RLS bloqueando queries
Solução:
  1. Abrir Chrome DevTools (F12)
  2. Ir para Console
  3. Verificar erro exato
  4. Consultar CHECKLIST_SUPABASE.md
```

---

## 📞 Suporte

- **Documentação completa:** [docs/](../docs/)
- **Fluxo de negócio:** [docs/FLUXO_NEGOCIO.md](../docs/FLUXO_NEGOCIO.md)
- **Schema Supabase:** [database/schema_nexus_v3.0.sql](../database/schema_nexus_v3.0.sql)
- **Skills técnicas:** [mnt/skills/](../mnt/skills/)

---

## 📈 Próximos Passos

1. ✅ Implementar Flutter Web (você está aqui)
2. 🔄 Importar dados reais via `import_getnet.py`
3. 🧪 Testes com operadores reais
4. 📊 Analytics e monitoring
5. 🚀 Expansão para iOS/Android native (opcional)

---

## 📄 Licença

Proprietário — Minusa Tratorpeças Ltda

---

**Criado com ❤️ por Claude Code**  
**Data:** 2026-04-27  
**Versão:** 1.0.0
