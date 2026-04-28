#!/bin/bash
# NEXUS Pre-Deploy Validation Script
# Executa todas as validações antes de fazer deploy

set -e

echo -e "\033[36m╔════════════════════════════════════════════╗\033[0m"
echo -e "\033[36m║     NEXUS Pre-Deploy Validation            ║\033[0m"
echo -e "\033[36m╚════════════════════════════════════════════╝\033[0m"
echo ""

PASSED=0
FAILED=0
WARNINGS=0

# Função para imprimir resultado
print_result() {
  local name=$1
  local result=$2
  local details=$3

  if [ "$result" = "pass" ]; then
    echo -e "\033[32m✓ $name\033[0m"
    PASSED=$((PASSED + 1))
  elif [ "$result" = "warn" ]; then
    echo -e "\033[33m⚠ $name\033[0m"
    if [ -n "$details" ]; then
      echo -e "  \033[2m$details\033[0m"
    fi
    WARNINGS=$((WARNINGS + 1))
  else
    echo -e "\033[31m✗ $name\033[0m"
    if [ -n "$details" ]; then
      echo -e "  \033[2m$details\033[0m"
    fi
    FAILED=$((FAILED + 1))
  fi
}

# 1. Node.js version
echo -e "\033[34m▸ Node & npm\033[0m"
NODE_VERSION=$(node -v)
NPM_VERSION=$(npm -v)
print_result "Node.js $NODE_VERSION" "pass"
print_result "npm $NPM_VERSION" "pass"
echo ""

# 2. Environment variables
echo -e "\033[34m▸ Variáveis de Ambiente\033[0m"
if [ -f ".env.local" ]; then
  if grep -q "NEXT_PUBLIC_SUPABASE_URL" .env.local; then
    print_result ".env.local contém NEXT_PUBLIC_SUPABASE_URL" "pass"
  else
    print_result ".env.local sem NEXT_PUBLIC_SUPABASE_URL" "fail" "Configure em .env.local"
  fi
else
  print_result ".env.local não encontrado" "warn" "Copie de .env.local.example"
fi
echo ""

# 3. TypeScript
echo -e "\033[34m▸ TypeScript Check\033[0m"
if npm run type-check > /dev/null 2>&1; then
  print_result "TypeScript compilation" "pass"
else
  print_result "TypeScript compilation" "fail" "Erros de tipo encontrados"
  npm run type-check || true
fi
echo ""

# 4. ESLint
echo -e "\033[34m▸ Linting (ESLint)\033[0m"
if npm run lint > /dev/null 2>&1; then
  print_result "ESLint check" "pass"
else
  print_result "ESLint check" "fail" "Problemas de linting encontrados"
  npm run lint || true
fi
echo ""

# 5. Build
echo -e "\033[34m▸ Build Next.js\033[0m"
if npm run build > /dev/null 2>&1; then
  print_result "Next.js build" "pass"
  # Check .next directory
  if [ -d ".next" ]; then
    SIZE=$(du -sh .next | cut -f1)
    print_result "Build output (.next)" "pass" "Tamanho: $SIZE"
  fi
else
  print_result "Next.js build" "fail" "Build falhou"
  npm run build || true
fi
echo ""

# 6. Dependencies
echo -e "\033[34m▸ Dependências\033[0m"
OUTDATED=$(npm outdated 2>&1 | tail -n +2 | wc -l)
if [ "$OUTDATED" -gt 0 ]; then
  print_result "Verificar pacotes desatualizados" "warn" "$OUTDATED pacotes podem ser atualizados"
else
  print_result "Todas as dependências atualizadas" "pass"
fi
echo ""

# 7. Git status
echo -e "\033[34m▸ Git\033[0m"
if git rev-parse --git-dir > /dev/null 2>&1; then
  print_result "Git repository" "pass"

  # Check for uncommitted changes
  if [ -z "$(git status --porcelain)" ]; then
    print_result "Sem mudanças não commitadas" "pass"
  else
    print_result "Alterações não commitadas" "warn" "Considere fazer commit/push antes do deploy"
  fi
else
  print_result "Git repository" "fail"
fi
echo ""

# 8. Arquivo de configuração
echo -e "\033[34m▸ Configuração\033[0m"
if [ -f "next.config.js" ]; then
  print_result "next.config.js" "pass"
fi
if [ -f "package.json" ]; then
  print_result "package.json" "pass"
fi
if [ -f "tsconfig.json" ]; then
  print_result "tsconfig.json" "pass"
fi
echo ""

# Resumo
echo -e "\033[36m╔════════════════════════════════════════════╗\033[0m"
echo -e "\033[36m║          Resumo da Validação               ║\033[0m"
echo -e "\033[36m╚════════════════════════════════════════════╝\033[0m"
echo ""
echo -e "\033[32m  Passou: $PASSED\033[0m"
echo -e "\033[33m  Avisos: $WARNINGS\033[0m"
echo -e "\033[31m  Falhas: $FAILED\033[0m"
echo ""

if [ "$FAILED" -eq 0 ]; then
  echo -e "\033[32m✓ Validação Completa - Pronto para Deploy!\033[0m"
  exit 0
else
  echo -e "\033[31m✗ Validação Falhou - Corrija os erros acima\033[0m"
  exit 1
fi
