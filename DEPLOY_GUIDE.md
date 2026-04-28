# 🚀 Guia de Deploy — Nexus para Vercel

**Data:** 2026-04-27  
**Tempo estimado:** 30 minutos

---

## ✅ PRÉ-REQUISITOS

- [ ] Flutter 3.13+ instalado (`flutter --version`)
- [ ] GitHub conta com repo do projeto
- [ ] Vercel conta criada (vercel.com)
- [ ] Supabase projeto criado (schema v3.0 rodando)
- [ ] Variáveis de ambiente definidas

---

## PASSO 1-3: Setup Vercel

### PASSO 1: Criar Projeto em Vercel

```bash
# Opção A: Via CLI
npm i -g vercel
vercel login
cd nexus_flutter
vercel

# Opção B: Via Web
# 1. Ir para vercel.com/dashboard
# 2. Clicar "New Project"
# 3. Selecionar GitHub repo
# 4. Escolher "Other" (Flutter)
```

**Status esperado:** Projeto criado em Vercel, projeto URL: `https://nexus-xxx.vercel.app`

---

### PASSO 2: Conectar GitHub

```bash
# No Vercel Dashboard:
# 1. Ir para Settings → Git
# 2. Conectar GitHub account
# 3. Selecionar repo: rodrigo/nexus
# 4. Auto-deploy em push ativado ✅
```

**Status esperado:** GitHub conectado, auto-deploy habilitado.

---

### PASSO 3: Configurar Build Command

```bash
# No Vercel Dashboard → Settings → Build & Development
# Build Command: flutter build web --release
# Output Directory: build/web
# Framework: Other
```

**Status esperado:** Build settings salvos.

---

## PASSO 4-7: Variáveis de Ambiente

### PASSO 4: Obter Credenciais Supabase

```bash
# No Supabase Dashboard:
# 1. Ir para Project Settings → API
# 2. Copiar URL (ex: https://xxx.supabase.co)
# 3. Copiar Anon Key (ex: eyJ...)
```

---

### PASSO 5: Adicionar Variáveis em Vercel

```bash
# No Vercel Dashboard → Settings → Environment Variables
# Adicionar:

Name: SUPABASE_URL
Value: https://xxx.supabase.co
Environments: Production, Preview, Development

Name: SUPABASE_ANON_KEY
Value: eyJ...
Environments: Production, Preview, Development
```

**Status esperado:** Variáveis definidas.

---

### PASSO 6: Atualizar .env.production

```bash
# Editar .env.production com valores reais:
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=seu-anon-key
```

**Não commitar valores reais!** Use Vercel env vars.

---

### PASSO 7: Validar Configuração

```bash
# Testar locally:
flutter run -d chrome --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

**Status esperado:** App abre em localhost:5000 ✅

---

## PASSO 8-10: Build e Deploy

### PASSO 8: Fazer Push para GitHub

```bash
git add .
git commit -m "Implementação Flutter completa para Vercel"
git push origin main
```

**Status esperado:** GitHub recebe commit, Vercel recebe webhook.

---

### PASSO 9: Monitorar Build em Vercel

```bash
# No Vercel Dashboard:
# 1. Ir para Deployments
# 2. Procurar último deploy (deve estar em "Building")
# 3. Clicar para ver logs
# 4. Esperar build completar (~2-3 min)
```

**Status esperado:** Build completo, status: "Ready" ✅

---

### PASSO 10: Testar Deploy

```bash
# No Vercel Dashboard:
# 1. Copiar URL: https://nexus-xxx.vercel.app
# 2. Abrir em navegador
# 3. Login com operador@filial001.com / 123456
# 4. Verificar dashboard carregando ✅
```

**Status esperado:** App rodando em produção!

---

## 🎯 CHECKLIST FINAL

- [ ] Flutter 3.13+ instalado
- [ ] GitHub repo criado com projeto
- [ ] Vercel projeto criado
- [ ] GitHub conectado a Vercel
- [ ] Build command configurado
- [ ] SUPABASE_URL setada em Vercel env
- [ ] SUPABASE_ANON_KEY setada em Vercel env
- [ ] .env.production preenchido (valores locais/staging)
- [ ] Deploy workflow testado
- [ ] App acessível em https://nexus-xxx.vercel.app
- [ ] Login funciona
- [ ] Dashboard carrega sem erros

---

## ⚠️ ERROS COMUNS

| Erro | Causa | Solução |
|------|-------|---------|
| **Build fails: "dart: command not found"** | Flutter SDK não instalado em Vercel | Use `flutter-action@v2` em deploy.yml |
| **"SUPABASE_URL not defined"** | Env var não está em Vercel env | Adicionar em Vercel Dashboard |
| **"RLS policy denying access"** | User sem permissão no Supabase | Verificar user_filiais_cnpj |
| **"Blank page"** | JavaScript desabilitado ou cache | Hard refresh (Ctrl+Shift+R) |
| **"Cannot find build/web"** | Flutter build falhou | Verificar flutter build web logs |

---

## 📞 PRÓXIMOS PASSOS

1. **Monitorar produção** com Vercel Analytics
2. **Configurar Sentry** para error tracking
3. **Setup CI/CD** com GitHub Actions (deploy automático)
4. **Importar dados reais** via `import_getnet.py`
5. **Testar com usuários reais** (operadores das filiais)

---

**🎉 Deploy completo! Nexus está live em produção.**

Data: 2026-04-27  
Próximo: Monitorar e otimizar performance
