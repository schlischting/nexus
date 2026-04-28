# NEXUS Next.js 15 — Setup Guide (15 Passos)

Guia completo para configurar o NEXUS localmente e fazer deploy em produção.

## Pré-Requisitos

- Node.js 18+ (recomendado 20+)
- npm ou yarn
- Git
- Conta no Supabase (gratuita)
- Conta no Vercel (para deploy)

## Passo 1: Clonar Repositório

```bash
cd "d:\Projetos Dev\Nexus"
cd nexus_nextjs
```

## Passo 2: Instalar Dependências

```bash
npm install
```

Este comando instala:
- next, react, typescript
- @supabase/supabase-js, @supabase/ssr
- zustand, react-hook-form, zod
- tailwindcss, shadcn/ui (radix-ui)
- lucide-react, sonner

Tempo estimado: 2-3 minutos

## Passo 3: Configurar Banco de Dados

**Prerequisito**: PostgreSQL rodando com schema_nexus_v3.0 já criado.

Se ainda não criou, execute em seu Supabase SQL Editor:

```bash
# Ver arquivo
../../database/schema_nexus_v3.0.sql

# Copiar todo conteúdo e executar no Supabase SQL Editor
```

Verificar que foram criadas:
- 6 tabelas (filiais, user_filiais_cnpj, user_filiais, transacoes_getnet, titulos_totvs, conciliacao_vinculos)
- 3 views (vw_nsu_sem_titulo, vw_titulo_sem_nsu, vw_sugestoes_supervisor)
- 2 RPC functions (calcular_score_matching, exportar_para_totvs)
- 6 RLS policies

## Passo 4: Criar Projeto no Supabase

1. Ir para https://supabase.com
2. Criar novo projeto (se ainda não tem)
3. Aguardar inicialização (5-10 minutos)
4. Copiar credenciais:
   - Project URL (anon key)
   - Anon Key (public)
   - Service Role Key (segredo — nunca commitar)

## Passo 5: Criar Variáveis de Ambiente

```bash
# Copiar template
cp .env.local.example .env.local

# Editar .env.local
```

Preenchidas com credenciais do Supabase (Passo 4):

```env
NEXT_PUBLIC_SUPABASE_URL=https://[seu-projeto].supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ0eXAiOiJKV1QiLCJhbGc...
SUPABASE_SERVICE_ROLE_KEY=eyJ0eXAiOiJKV1QiLCJhbGc...
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_ENABLE_ANALYTICS=true
```

⚠️ **Importante**: Nunca commit `.env.local`. Já está em `.gitignore`.

## Passo 6: Criar Usuários de Teste

No Supabase Dashboard → Authentication → Users, criar:

**Operador (Filial única)**
- Email: operador@test.com
- Password: Senha123!
- Tipo: operador_filial
- Filial: 12345678901234

**Supervisor (Todas filiais)**
- Email: supervisor@test.com
- Password: Senha123!
- Tipo: supervisor

No SQL Editor, adicionar registros:

```sql
-- Operador filial única
INSERT INTO user_filiais_cnpj (user_id, filial_cnpj)
VALUES ('seu_user_id_operador', '12345678901234');

INSERT INTO user_filiais (user_id, perfil)
VALUES ('seu_user_id_operador', 'operador_filial');

-- Supervisor todas filiais
INSERT INTO user_filiais_cnpj (user_id, filial_cnpj)
VALUES 
  ('seu_user_id_supervisor', '12345678901234'),
  ('seu_user_id_supervisor', '87654321098765');

INSERT INTO user_filiais (user_id, perfil)
VALUES ('seu_user_id_supervisor', 'supervisor');
```

## Passo 7: Inserir Dados de Teste

Adicionar transações GETNET e títulos TOTVS para testar:

```sql
-- Transações GETNET
INSERT INTO transacoes_getnet (
  transacao_id, filial_cnpj, nsu, data_solicitacao, data_venda,
  valor_bruto, valor_taxa, valor_liquido, bandeira, tipo, parcelas,
  cnpj_cliente, nome_cliente, status_transacao
) VALUES (
  'TRX-001', '12345678901234', '123456', NOW(), NOW(),
  1000.00, 50.00, 950.00, 'MASTERCARD', 'credito_a_vista', 1,
  '98765432100000', 'Cliente Teste', 'processado'
);

-- Títulos TOTVS
INSERT INTO titulos_totvs (
  titulo_id, filial_cnpj, numero_nf, especie, serie, numero, parcela,
  data_emissao, data_vencimento, valor_bruto, desconto, acrescimo,
  valor_liquido, cnpj_cliente, nome_cliente, status_titulo
) VALUES (
  'TIT-001', '12345678901234', 'NF-001', 'NF', '1', '001', 1,
  NOW(), NOW() + INTERVAL '30 days', 1000.00, 0, 0, 1000.00,
  '98765432100000', 'Cliente Teste', 'aberto'
);
```

## Passo 8: Executar Desenvolvimento Local

```bash
npm run dev
```

Saída esperada:
```
> next dev
  ▲ Next.js 15.0.0
  - Local:        http://localhost:3000
  - Environments: .env.local

Ready in 2.3s
```

Acesse http://localhost:3000 no navegador.

## Passo 9: Testar Fluxo de Login

1. Ir para http://localhost:3000
2. Ser redirecionado para /auth/login
3. Logar com:
   - Email: operador@test.com
   - Senha: Senha123!
4. Ser redirecionado para /operador/dashboard

## Passo 10: Testar Dashboard Operador

1. Verificar métricas carregadas (NSU sem título, Título sem NSU)
2. Clicar "Novo Lançamento"
3. Buscar NSU: `123456`
4. Selecionar transação que aparecer
5. Buscar NF: `NF-001`
6. Selecionar título
7. Definir modalidade: Crédito à Vista
8. Clicar "Calcular Score"
9. Ver score e confirmar vinculo

## Passo 11: Testar Dashboard Supervisor

1. Logout (clicar usuário > Sair)
2. Logar como:
   - Email: supervisor@test.com
   - Senha: Senha123!
3. Ser redirecionado para /supervisor/dashboard
4. Ver sugestões de reconciliação
5. Confirmar/rejeitar vinculos
6. Selecionar e exportar para TOTVS

## Passo 12: Verificar TypeScript

```bash
npm run type-check
```

Não deve ter erros. Se tiver, corrigir types em `lib/types.ts`.

## Passo 13: Build para Produção

```bash
npm run build
```

Saída esperada:
```
> next build
  ✓ Created .next
  ✓ Compiled successfully
```

Se falhar, verificar erros de TypeScript/ESLint.

## Passo 14: Deploy no Vercel

1. **Push para GitHub**
   ```bash
   git add .
   git commit -m "feat: NEXUS Next.js 15 complete implementation"
   git push origin main
   ```

2. **Conectar no Vercel**
   - Ir para https://vercel.com
   - Clicar "New Project"
   - Importar repositório GitHub
   - Selecionar `nexus_nextjs` folder

3. **Configurar Variáveis**
   - Ir para Settings > Environment Variables
   - Adicionar 5 variáveis:
     ```
     NEXT_PUBLIC_SUPABASE_URL
     NEXT_PUBLIC_SUPABASE_ANON_KEY
     SUPABASE_SERVICE_ROLE_KEY (marcar como secret)
     NEXT_PUBLIC_APP_URL=https://seu-dominio.vercel.app
     NEXT_PUBLIC_ENABLE_ANALYTICS=true
     ```

4. **Deploy**
   - Clicar "Deploy"
   - Aguardar build (3-5 minutos)
   - Copiar URL de produção

## Passo 15: Configurar Custom Domain (Opcional)

1. **Domínio**
   - Já tem domínio `nexus.minusa.com.br`? Sim
   - Ir para Settings > Domains

2. **Apontar DNS**
   - Registrar em seu provedor DNS:
     - Type: CNAME
     - Name: nexus (ou @ se raiz)
     - Value: cname.vercel-dns.com.

3. **SSL Automático**
   - Vercel provisiona certificado Let's Encrypt automaticamente
   - Aguardar 5-15 minutos

4. **Verificar**
   - Acessar https://nexus.minusa.com.br
   - Deve funcionar como desenvolvimento

## Checklist Final

Antes de considerar pronto:

- [ ] `.env.local` configurado localmente
- [ ] Banco de dados com schema_nexus_v3.0 criado
- [ ] Usuários de teste criados (operador + supervisor)
- [ ] Dados de teste inseridos (transações + títulos)
- [ ] `npm run dev` executando sem erros
- [ ] Login funcionando
- [ ] Dashboard operador carregando dados
- [ ] Novo lançamento criando vinculos
- [ ] Dashboard supervisor mostrando sugestões
- [ ] `npm run build` passando
- [ ] Deploy no Vercel com variáveis
- [ ] HTTPS funcionando

## Troubleshooting

### Erro: "getAuthUser is not a function"
**Causa**: Função não importada corretamente
**Solução**: Verificar import em `lib/auth.ts`

### Erro: "RLS policy missing"
**Causa**: Policies não criadas no Supabase
**Solução**: Executar `schema_nexus_v3.0.sql` novamente

### Erro: "SUPABASE_SERVICE_ROLE_KEY not found"
**Causa**: Variável de servidor não configurada
**Solução**: Adicionar em `.env.local` (desenvolvimento) ou Vercel (produção)

### Erro: "Module not found: @supabase/supabase-js"
**Causa**: Dependência não instalada
**Solução**: Rodar `npm install` novamente

### Dashboard lento
**Causa**: Muitos dados, falta de índices
**Solução**: Verificar índices em PostgreSQL (devem estar em schema)

## Próximos Passos

1. **Integração com TOTVS**
   - Implementar export real para ERP
   - Criar endpoint para receber confirmações

2. **Analytics**
   - Configurar Google Analytics
   - Dashboard de métricas

3. **Mobile**
   - PWA com offline support
   - Install prompt

4. **Automação**
   - Cron jobs para reconc. automática
   - Alertas por email/SMS

## Documentação Relacionada

- `README.md` — Overview do projeto
- `../../database/schema_nexus_v3.0.sql` — Schema PostgreSQL completo
- `../../docs/FLUXO_NEGOCIO.md` — Fluxo de negócio detalhado
- `../../docs/CHECKLIST_SUPABASE.md` — Supabase setup checklist

---

**Contato**: rodrigominusa@minusa.com.br
**Versão**: 1.0.0
**Última atualização**: 2026-04-27
