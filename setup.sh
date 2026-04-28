#!/bin/bash
# NEXUS Setup Script for macOS/Linux
# Este script prepara o ambiente para desenvolvimento local

set -e

echo -e "\033[36m╔════════════════════════════════════════════╗\033[0m"
echo -e "\033[36m║     NEXUS Next.js 15 — Setup Script       ║\033[0m"
echo -e "\033[36m╚════════════════════════════════════════════╝\033[0m"
echo ""

# Verificar Node.js
echo -e "\033[33m▸ Verificando Node.js...\033[0m"
if ! command -v node &> /dev/null; then
    echo -e "\033[31m✗ Node.js não encontrado!\033[0m"
    echo -e "\033[2m  Baixe em: https://nodejs.org/\033[0m"
    exit 1
fi
NODE_VERSION=$(node -v)
echo -e "\033[32m  ✓ Node.js $NODE_VERSION\033[0m"

# Verificar npm
echo -e "\033[33m▸ Verificando npm...\033[0m"
if ! command -v npm &> /dev/null; then
    echo -e "\033[31m✗ npm não encontrado!\033[0m"
    exit 1
fi
NPM_VERSION=$(npm -v)
echo -e "\033[32m  ✓ npm $NPM_VERSION\033[0m"
echo ""

# Instalar dependências
echo -e "\033[33m▸ Instalando dependências...\033[0m"
npm install
echo -e "\033[32m  ✓ Dependências instaladas\033[0m"
echo ""

# Copiar .env.local
echo -e "\033[33m▸ Configurando variáveis de ambiente...\033[0m"
if [ ! -f ".env.local" ]; then
    if [ -f ".env.local.example" ]; then
        cp .env.local.example .env.local
        echo -e "\033[32m  ✓ .env.local criado do template\033[0m"
    else
        echo -e "\033[31m  ✗ .env.local.example não encontrado\033[0m"
        exit 1
    fi
else
    echo -e "\033[34m  ℹ .env.local já existe\033[0m"
fi
echo ""

# Instruções finais
echo -e "\033[32m╔════════════════════════════════════════════╗\033[0m"
echo -e "\033[32m║          Setup Completado! ✓              ║\033[0m"
echo -e "\033[32m╚════════════════════════════════════════════╝\033[0m"
echo ""
echo -e "\033[36mPróximas etapas:\033[0m"
echo -e "  1. Edite .env.local com suas credenciais Supabase"
echo -e "  2. Execute: npm run dev"
echo -e "  3. Abra: http://localhost:3400"
echo ""
echo -e "\033[33mVariáveis necessárias em .env.local:\033[0m"
echo -e "  \033[2m- NEXT_PUBLIC_SUPABASE_URL\033[0m"
echo -e "  \033[2m- NEXT_PUBLIC_SUPABASE_ANON_KEY\033[0m"
echo -e "  \033[2m- SUPABASE_SERVICE_ROLE_KEY\033[0m"
echo ""
echo -e "\033[33mPara mais detalhes, veja SETUP_GUIDE.md\033[0m"
