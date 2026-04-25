# Guia de Setup do Supabase para Nexus

**Data:** 24 de Abril de 2026

---

## 📋 Pré-requisitos

- Conta no [supabase.com](https://supabase.com)
- Projeto Supabase criado (gratuito ou pago)
- CLI do Supabase (opcional, mas recomendado)

---

## 🚀 Passo 1: Criar Projeto no Supabase

1. Acesse [console.supabase.com](https://console.supabase.com)
2. Clique em **"New Project"**
3. Preencha:
   - **Name:** `nexus` ou `nexus-dev`
   - **Database Password:** Salve em local seguro
   - **Region:** Escolha a mais próxima (ex: us-east-1, sa-east-1)
4. Aguarde ~10 minutos para o projeto ficar pronto

---

## 🗄️ Passo 2: Executar Schema SQL

### Opção A: Via Console Web (Recomendado para começar)

1. Acesse seu projeto em console.supabase.com
2. Vá em **SQL Editor** (no menu esquerdo)
3. Clique em **"New Query"**
4. Copie todo o conteúdo de `database/schema_nexus.sql`
5. Cole na query
6. Clique em **"Run"**
7. Aguarde a execução (deve levar < 1 minuto)

**Esperado:** Tabelas criadas sem erros

### Opção B: Via CLI Supabase

```bash
# Instale CLI (uma vez)
npm install -g supabase

# Login
supabase login

# Link seu projeto local ao Supabase
supabase link --project-ref seu-project-ref

# Aplicar migrations
supabase db push

# Ou executar SQL diretamente
psql "postgresql://postgres:senha@db.seu-project.supabase.co:5432/postgres" < database/schema_nexus.sql
```

---

## 🔑 Passo 3: Configurar Variáveis de Ambiente

1. Vá em **Project Settings** → **API**
2. Anote:
   - **Project URL:** `https://seu-projeto.supabase.co`
   - **API Key (anon):** `eyJhbGc...` (pública)
   - **API Key (service_role):** `eyJhbGc...` (privada)

3. Crie arquivo `.env` na pasta `backend/`:

```bash
cp backend/.env.example backend/.env
```

4. Edite `backend/.env`:

```env
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_KEY=sua-chave-publica-anon
SUPABASE_SERVICE_ROLE_KEY=sua-chave-service-role

# Opcional (se conectar direto via psql)
DB_HOST=db.seu-projeto.supabase.co
DB_PORT=5432
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=sua-senha-do-banco
```

⚠️ **Nunca commit `.env` para git!**

---

## 👥 Passo 4: Configurar Usuários e RLS

### Criar Usuário de Teste

1. Vá em **Authentication** → **Users**
2. Clique em **"Add User"**
3. Preencha:
   - Email: `operador@empresa.com`
   - Password: Escolha segura
   - Auto confirm user: ✅ (checkado)

4. Anote o `user_id` (UUID) gerado

### Inserir Mapeamento user_filiais

Execute via SQL Editor:

```sql
-- Insira após criar o usuário
INSERT INTO user_filiais (user_id, filial_id, perfil)
VALUES (
  '550e8400-e29b-41d4-a716-446655440000',  -- UUID do usuário
  1,                                         -- filial_id (SP001)
  'operador'                                 -- perfil
);
```

Agora esse usuário vê apenas dados da filial 1.

---

## 🔐 Passo 5: Testar RLS

### Via SQL Editor

```sql
-- Testando como usuário
SET REQUEST.JWT.CLAIM.SUB = '550e8400-e29b-41d4-a716-446655440000';

-- Isso deve retornar registros (sua filial)
SELECT COUNT(*) FROM transacoes_getnet;

-- Isso deve retornar 0 (filial não autorizada)
SELECT COUNT(*) FROM transacoes_getnet 
WHERE filial_id = 999;
```

### Via Python

```python
from supabase import create_client, Client

url = "https://seu-projeto.supabase.co"
key = "sua-chave-publica-anon"
client: Client = create_client(url, key)

# Login
response = client.auth.sign_in_with_password({
  "email": "operador@empresa.com",
  "password": "sua-senha"
})

jwt_token = response.session.access_token

# Query com token
data = client.table('transacoes_getnet').select('*').execute()

print(f"Registros visíveis: {len(data.data)}")
# Deve mostrar apenas dados de sua filial
```

---

## 📤 Passo 6: Testar Ingestão de Dados

```bash
# Ative venv
source venv/bin/activate  # ou: venv\Scripts\activate (Windows)

# Instale dependências
pip install -r backend/requirements.txt

# Execute validação (dry-run)
python backend/import_getnet.py \
  --file data/extrato_getnet_exemplo.csv \
  --filial_id 1 \
  --dry-run

# Esperado: Relatório com 5 transações válidas
```

Se tudo OK, remova `--dry-run` para inserts reais:

```bash
python backend/import_getnet.py \
  --file data/extrato_getnet_exemplo.csv \
  --filial_id 1
```

**Verifique dados no console:**

1. SQL Editor
2. Execute:
```sql
SELECT COUNT(*) as total_transacoes 
FROM transacoes_getnet 
WHERE filial_id = 1;
```

---

## 🔄 Passo 7: Configurar Triggers (Opcional Agora)

Se quiser testar o matching automático:

```sql
-- Criar função de scoring
CREATE OR REPLACE FUNCTION auto_criar_vinculos()
RETURNS TRIGGER AS $$
BEGIN
  -- Lógica futura de auto-matching
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger (ainda não dispara, preparação para fase 3)
CREATE TRIGGER trigger_auto_matching
  AFTER INSERT ON transacoes_getnet
  FOR EACH ROW
  EXECUTE FUNCTION auto_criar_vinculos();
```

---

## 📊 Passo 8: Monitorar Saúde do Projeto

### Via Dashboard

1. **Database** → **Queries** (veja queries lentas)
2. **Storage** → (prepare para fotos de PWA)
3. **Realtime** → (ative se usar subscriptions)
4. **Authentication** → (monitore usuários)

### Via Logs

```sql
-- Últimas inserções em transacoes_getnet
SELECT * FROM transacoes_getnet 
ORDER BY data_ingesta DESC 
LIMIT 10;

-- Próximas 10 inserções
SELECT data_ingesta, COUNT(*) as total
FROM transacoes_getnet
GROUP BY DATE(data_ingesta)
ORDER BY data_ingesta DESC;
```

---

## 🛡️ Passo 9: Segurança Essencial

### Habilitar HTTPS + CSP Headers

✅ Já vem habilitado no Supabase

### Habilitar 2FA (Opcional)

1. **Project Settings** → **Authentication**
2. **Email Auth** → Habilite MFA

### Limitar API Keys

1. **Project Settings** → **API**
2. **API Key (anon):**
   - Row Level Security: ✅ (sempre)
   - Disable via Console: Nunca publique key de service_role

---

## 🧪 Passo 10: Backup & Disaster Recovery

### Setup Automático (Pago)

1. **Project Settings** → **Backups**
2. Escolha plano (Basic: semanal, Pro: diário)

### Backup Manual (Gratuito)

```bash
# Exportar dump
pg_dump "postgresql://postgres:senha@db.seu-projeto.supabase.co:5432/postgres" \
  > backup_nexus_$(date +%Y%m%d).sql

# Restaurar (se necessário)
psql "postgresql://postgres:senha@db.seu-projeto.supabase.co:5432/postgres" \
  < backup_nexus_20260424.sql
```

---

## 📝 Checklist de Setup Completo

- [ ] Projeto Supabase criado
- [ ] Schema SQL executado (sem erros)
- [ ] `.env` configurado e não commitado
- [ ] Usuário de teste criado
- [ ] RLS testado (usuário vê só sua filial)
- [ ] Dados de exemplo inseridos
- [ ] Query retorna dados corretos
- [ ] Backup configurado
- [ ] 2FA habilitado (recomendado)
- [ ] Documentação lida: `docs/2026-04-24-arquitetura-nexus.md`

---

## 🆘 Troubleshooting

### "Error: Connection refused"
**Solução:** Verifique IP na whitelist ou use VPN/proxy

### "Permission denied on table X"
**Solução:** Verifique RLS policies e user_filiais

### "NSU already exists"
**Solução:** Hash SHA256 detectou duplicata. Limpe CSV

### "ModuleNotFoundError: No module named 'supabase'"
**Solução:** `pip install -r requirements.txt`

---

## 📚 Documentação Oficial

- [Supabase Documentation](https://supabase.com/docs)
- [PostgreSQL RLS](https://www.postgresql.org/docs/current/sql-createrole.html)
- [Supabase CLI](https://supabase.com/docs/guides/cli)

---

**Setup Concluído! Próximo passo: Backend com FlutterFlow**
