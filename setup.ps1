# NEXUS Setup Script for Windows PowerShell
# Este script prepara o ambiente para desenvolvimento local

Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     NEXUS Next.js 15 — Setup Script       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Verificar Node.js
Write-Host "▸ Verificando Node.js..." -ForegroundColor Yellow
$nodeVersion = node -v 2>&1
if ($nodeVersion -match "not found|is not") {
    Write-Host "✗ Node.js não encontrado!" -ForegroundColor Red
    Write-Host "  Baixe em: https://nodejs.org/" -ForegroundColor Gray
    exit 1
}
Write-Host "  ✓ Node.js $nodeVersion" -ForegroundColor Green

# Verificar npm
Write-Host "▸ Verificando npm..." -ForegroundColor Yellow
$npmVersion = npm -v 2>&1
Write-Host "  ✓ npm $npmVersion" -ForegroundColor Green
Write-Host ""

# Instalar dependências
Write-Host "▸ Instalando dependências..." -ForegroundColor Yellow
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Erro ao instalar dependências" -ForegroundColor Red
    exit 1
}
Write-Host "  ✓ Dependências instaladas" -ForegroundColor Green
Write-Host ""

# Copiar .env.local
Write-Host "▸ Configurando variáveis de ambiente..." -ForegroundColor Yellow
if (-Not (Test-Path ".env.local")) {
    if (Test-Path ".env.local.example") {
        Copy-Item ".env.local.example" ".env.local"
        Write-Host "  ✓ .env.local criado do template" -ForegroundColor Green
    } else {
        Write-Host "  ✗ .env.local.example não encontrado" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  ℹ .env.local já existe" -ForegroundColor Blue
}
Write-Host ""

# Instruções finais
Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║          Setup Completado! ✓              ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Próximas etapas:" -ForegroundColor Cyan
Write-Host "  1. Edite .env.local com suas credenciais Supabase" -ForegroundColor White
Write-Host "  2. Execute: npm run dev" -ForegroundColor White
Write-Host "  3. Abra: http://localhost:3400" -ForegroundColor White
Write-Host ""
Write-Host "Variáveis necessárias em .env.local:" -ForegroundColor Yellow
Write-Host "  - NEXT_PUBLIC_SUPABASE_URL" -ForegroundColor Gray
Write-Host "  - NEXT_PUBLIC_SUPABASE_ANON_KEY" -ForegroundColor Gray
Write-Host "  - SUPABASE_SERVICE_ROLE_KEY" -ForegroundColor Gray
Write-Host ""
Write-Host "Para mais detalhes, veja SETUP_GUIDE.md" -ForegroundColor Yellow
