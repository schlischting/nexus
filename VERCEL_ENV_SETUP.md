# Configurar Variáveis de Ambiente no Vercel

## Passo 1: Acesse o Vercel Dashboard
1. Vá para https://vercel.com/schlischtings-projects/nexus
2. Clique em **Settings** (Configurações)
3. Vá para **Environment Variables**

## Passo 2: Adicione as Variáveis

Copie e cole cada uma:

### 1. NEXT_PUBLIC_SUPABASE_URL
- **Name:** `NEXT_PUBLIC_SUPABASE_URL`
- **Value:** `https://isqzpklktaygklevatxb.supabase.co`
- **Envs:** Production, Preview, Development ✓

### 2. NEXT_PUBLIC_SUPABASE_ANON_KEY
- **Name:** `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- **Value:** `sb_publishable_x6Z2TMrbRu12-Sbk888YqQ_WJYu1VG4`
- **Envs:** Production, Preview, Development ✓

### 3. SUPABASE_SERVICE_ROLE_KEY
- **Name:** `SUPABASE_SERVICE_ROLE_KEY`
- **Value:** (Cole a chave secreta de seu .env.local)
- **Envs:** Production, Preview, Development ✓

### 4. NEXT_PUBLIC_APP_URL
- **Name:** `NEXT_PUBLIC_APP_URL`
- **Value:** `https://nexus-nxsog4lx4-schlischtings-projects.vercel.app` (ou seu domínio customizado)
- **Envs:** Production ✓

## Passo 3: Deploy
Após adicionar todas, vá para **Deployments** e clique em **Redeploy** no último deployment.
