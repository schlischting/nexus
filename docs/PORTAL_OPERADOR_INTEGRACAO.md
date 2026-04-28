# Portal do Operador - Guia de Integração Completo

**Data:** 2026-04-24  
**Status:** ✅ PRONTO PARA IMPLEMENTAR  
**Componentes:** Schema (Supabase) + Endpoints (PostgREST) + Backend (Python mock TOTVS)

---

## 📋 Visão Geral da Solução

### Problema Negócio
Operador recebe comprovante GETNET em mão (com NSU visível) mas não tem acesso ao sistema TOTVS para validar o número de NF correspondente. Precisa de interface simples: digita NSU → digita NF → confirma.

### Arquitetura Solução

```
[FlutterFlow Portal]
    ↓ (chamadas HTTP)
[Supabase PostgREST + RLS]
    ↓ (queries SQL protegidas)
[PostgreSQL Database]
    ↓ (busca de títulos)
[Python totvs_client.py - Mock]
```

---

## 🔧 Componentes Implementados

### 1. Schema Adjustments (3 ALTER TABLE)
**Arquivo:** `database/MIGRACAO_PORTAL_OPERADOR.sql`

| Ajuste | Propósito | Campo |
|--------|-----------|-------|
| Alter 1 | Permite vínculo sem título | `titulo_totvs_id DROP NOT NULL` |
| Alter 2 | Rastreia NF digitada | `ADD numero_nf_manual VARCHAR(30)` |
| Alter 3 | Diferencia automático vs manual | `ADD tipo_vinculacao VARCHAR(50)` |

**Impacto:** ✅ Sem quebra de dados (apenas adiciona flexibilidade)

### 2. Supabase Endpoints (RLS-Protected)
**Documentado em:** Este arquivo (seção abaixo)

4 endpoints que FlutterFlow consumirá via PostgREST:
1. `POST /operador/buscar-nsu` — Busca transação GETNET
2. `POST /operador/criar-vinculo` — Cria vínculo manual
3. `GET /operador/buscar-titulos-totvs` — Busca títulos (mock ou real)
4. `GET /operador/dashboard-gaps` — Alertas de gaps

### 3. Python TOTVS Client (Mock)
**Arquivo:** `backend/totvs_client.py`

- `TotvsMockClient` classe com 4 métodos principais
- Mock data para 2 filiais (84943067001393, 01234567000180)
- Ready to replace com PASOE real quando API disponível

---

## 🚀 Fluxo Completo: Do NSU à Confirmação

### Passo 1: Operador Abre Portal & Digita NSU

**FlutterFlow Action:**
```
Button "Buscar NSU" → Call Supabase Function
Input: { filial_cnpj: "84943067001393", nsu: "145186923" }
```

**Supabase Endpoint (RLS-Protected):**
```sql
-- POST /rest/v1/transacoes_getnet (com filtros)
SELECT 
  transacao_id, 
  nsu, 
  valor, 
  bandeira, 
  data_transacao,
  numero_autorizacao
FROM transacoes_getnet
WHERE filial_cnpj = current_user_filial()  -- RLS: apenas filial do user
  AND nsu = $1
  AND status = 'pendente'
LIMIT 1;
```

**Response (sucesso):**
```json
{
  "transacao_id": 12345,
  "nsu": "145186923",
  "valor": 7600.00,
  "bandeira": "Visa",
  "data_transacao": "2025-07-30",
  "numero_autorizacao": "600712"
}
```

**Response (NSU não encontrado):**
```json
{
  "error": "NSU 145186923 não encontrado ou já conciliado"
}
```

---

### Passo 2: Operador Digita Número de NF

**FlutterFlow UI:**
- Exibe: "NSU: 145186923 | Valor: R$ 7.600,00 | Bandeira: Visa"
- Input: Campo de texto "Número de NF"
- Validação: Formato "NF-AAAA-XXXXXX"

**Operador digita:** `NF-2026-001234`

---

### Passo 3: Operador Clica "Vincular" → Backend Cria Vínculo

**FlutterFlow Action:**
```
Button "Vincular" → Call Supabase Function
Input: { 
  transacao_getnet_id: 12345,
  numero_nf_manual: "NF-2026-001234",
  filial_cnpj: "84943067001393"
}
```

**Supabase Edge Function (JavaScript/TypeScript):**
```javascript
// POST /functions/v1/criar-vinculo-manual
import { createClient } from '@supabase/supabase-js'

export default async (req) => {
  const supabase = createClient(Deno.env.get('SUPABASE_URL'), Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'))
  
  const { transacao_getnet_id, numero_nf_manual, filial_cnpj } = await req.json()
  
  // 1. Inserir vínculo (título_totvs_id = NULL por enquanto)
  const { data: vinculo, error: vinculoError } = await supabase
    .from('conciliacao_vinculos')
    .insert({
      filial_cnpj,
      transacao_getnet_id,
      titulo_totvs_id: null,  // Será preenchido depois
      numero_nf_manual,
      tipo_vinculacao: 'manual',
      status: 'aguardando_validacao',
      data_criacao: new Date().toISOString()
    })
    .select()
  
  if (vinculoError) {
    return new Response(JSON.stringify({ error: vinculoError.message }), { status: 400 })
  }
  
  // 2. Atualizar transacao_getnet para 'conciliada'
  const { error: updateError } = await supabase
    .from('transacoes_getnet')
    .update({ status: 'conciliada' })
    .eq('transacao_id', transacao_getnet_id)
  
  if (updateError) {
    return new Response(JSON.stringify({ error: updateError.message }), { status: 400 })
  }
  
  // 3. Buscar título TOTVS em background (async)
  // Chamada assíncrona ao mock TOTVS
  buscar_titulo_totvs_async(filial_cnpj, numero_nf_manual, vinculo.vinculo_id)
  
  return new Response(JSON.stringify({
    vinculo_id: vinculo.vinculo_id,
    status: 'criado_com_sucesso',
    mensagem: 'Vínculo criado. Sistema buscando título TOTVS...'
  }), { status: 201 })
}
```

**Response (sucesso):**
```json
{
  "vinculo_id": 99,
  "status": "criado_com_sucesso",
  "mensagem": "Vínculo criado. Sistema buscando título TOTVS..."
}
```

---

### Passo 4: Sistema Busca Título TOTVS (Background)

**Backend Python (async job ou cron):**
```python
from backend.totvs_client import TotvsMockClient

client = TotvsMockClient()  # Modo MOCK

# Buscar título correspondente
titulos = client.buscar_titulos_por_nf(
    filial_cnpj='84943067001393',
    numero_nf='NF-2026-001234'
)

if titulos:
    titulo = titulos[0]
    
    # Atualizar vínculo com título encontrado
    supabase.table('conciliacao_vinculos').update({
        'titulo_totvs_id': titulo.titulo_id,
        'status': 'confirmado'
    }).eq('vinculo_id', 99).execute()
    
    logger.info(f"✅ Vínculo 99: Título {titulo.numero_titulo} associado com sucesso")
else:
    logger.warning(f"⚠️  Vínculo 99: NF 'NF-2026-001234' não encontrada no TOTVS")
```

**Resultado no DB:**
```sql
-- conciliacao_vinculos (após busca TOTVS)
vinculo_id  | transacao_getnet_id | numero_nf_manual | titulo_totvs_id | status     | tipo_vinculacao
99          | 12345               | NF-2026-001234   | 1002             | confirmado | manual

-- transacoes_getnet
transacao_id | nsu        | status      
12345        | 145186923  | conciliada
```

---

### Passo 5: Dashboard Mostra Status

**Query para Dashboard (RLS-protected):**

```sql
-- Alert A: Transações sem vínculo (precisa ação operador)
SELECT 
  COUNT(*) as sem_vinculo_count,
  SUM(valor) as valor_pendente
FROM transacoes_getnet
WHERE filial_cnpj = current_user_filial()
  AND status = 'pendente';

-- Alert B: Vínculos manuais sem título (precisa validação sistema)
SELECT 
  COUNT(*) as vinculo_sem_titulo_count,
  SUM(tg.valor) as valor_em_pendencia
FROM conciliacao_vinculos cv
JOIN transacoes_getnet tg ON cv.transacao_getnet_id = tg.transacao_id
WHERE cv.filial_cnpj = current_user_filial()
  AND cv.titulo_totvs_id IS NULL
  AND cv.tipo_vinculacao = 'manual'
  AND cv.status = 'aguardando_validacao';

-- Alert C: Vínculos confirmados (sucesso)
SELECT 
  COUNT(*) as vinculo_confirmado_count,
  SUM(tg.valor) as valor_conciliado
FROM conciliacao_vinculos cv
JOIN transacoes_getnet tg ON cv.transacao_getnet_id = tg.transacao_id
WHERE cv.filial_cnpj = current_user_filial()
  AND cv.tipo_vinculacao = 'manual'
  AND cv.status = 'confirmado';
```

**FlutterFlow Display:**
```
┌─────────────────────────────┐
│ 📊 DASHBOARD - GAPS OPERADOR │
├─────────────────────────────┤
│                             │
│ 🔴 Sem Vínculo: 45          │
│    Valor: R$ 312.450,50     │
│                             │
│ 🟡 Vínculo sem Título: 12   │
│    Valor: R$ 89.500,00      │
│                             │
│ ✅ Conciliados: 1.133       │
│    Valor: R$ 8.920.300,00   │
│                             │
└─────────────────────────────┘
```

---

## 📚 Referência de Endpoints

### Endpoint 1: Buscar NSU Pendente
```
Method: GET
URL: /rest/v1/transacoes_getnet?select=*&filial_cnpj=eq.{CNPJ}&nsu=eq.{NSU}&status=eq.pendente
Headers: Authorization: Bearer {TOKEN}

Autenticação: Supabase JWT (auth.uid())
RLS Enforcement: Apenas filiais do user (via user_filiais_cnpj)

Response 200:
{
  "transacao_id": 12345,
  "nsu": "145186923",
  "valor": 7600.00,
  "bandeira": "Visa",
  "data_transacao": "2025-07-30",
  "numero_autorizacao": "600712"
}

Response 404:
{ "error": "NSU não encontrado" }
```

### Endpoint 2: Criar Vínculo Manual
```
Method: POST
URL: /functions/v1/criar-vinculo-manual
Body: {
  "transacao_getnet_id": 12345,
  "numero_nf_manual": "NF-2026-001234",
  "filial_cnpj": "84943067001393"
}
Headers: Authorization: Bearer {TOKEN}, Content-Type: application/json

Response 201:
{
  "vinculo_id": 99,
  "status": "criado_com_sucesso",
  "mensagem": "Vínculo criado. Sistema buscando título TOTVS..."
}

Response 400:
{ "error": "NSU já conciliado" }
```

### Endpoint 3: Buscar Títulos TOTVS
```
Method: POST
URL: /functions/v1/buscar-titulos-totvs
Body: {
  "filial_cnpj": "84943067001393",
  "numero_nf": "NF-2026-001234"
}
Headers: Authorization: Bearer {TOKEN}

Response 200:
{
  "titulos": [
    {
      "titulo_id": 1002,
      "numero_titulo": "NF-2026-001234",
      "valor_total": 7600.00,
      "valor_liquido": 7550.00,
      "data_vencimento": "2026-05-30",
      "cliente_nome": "ACME CORP LTDA"
    }
  ]
}

Response 404:
{ "error": "NF não encontrada no TOTVS" }
```

### Endpoint 4: Dashboard Gaps
```
Method: GET
URL: /rest/v1/rpc/dashboard_gaps
Body: { "filial_cnpj": "84943067001393" }
Headers: Authorization: Bearer {TOKEN}

Response 200:
{
  "sem_vinculo": 45,
  "valor_pendente": 312450.50,
  "vinculo_sem_titulo": 12,
  "valor_em_validacao": 89500.00,
  "vinculo_confirmado": 1133,
  "valor_conciliado": 8920300.00
}
```

---

## 🛠️ Arquivos a Implementar

### 1. Supabase Database Migration
**Arquivo:** `database/MIGRACAO_PORTAL_OPERADOR.sql`

**Ação:** Executar no SQL Editor do Supabase Dashboard
```bash
# Ou via CLI:
supabase db push --force
```

**Validação pós-migração:**
```sql
SELECT column_name, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'conciliacao_vinculos'
AND column_name IN ('titulo_totvs_id', 'numero_nf_manual', 'tipo_vinculacao');
```

### 2. Supabase Edge Functions (3 functions)

**`functions/buscar-nsu.ts`**
```typescript
// GET NSU na tabela transacoes_getnet
// RLS filtra por filial_cnpj
// Retorna dados da transação ou erro 404
```

**`functions/criar-vinculo-manual.ts`**
```typescript
// POST insere em conciliacao_vinculos (type='manual')
// Atualiza transacoes_getnet status para 'conciliada'
// Dispara busca assíncrona de título TOTVS
```

**`functions/buscar-titulos-totvs.ts`**
```typescript
// GET chama totvs_client.py (via HTTP ou import)
// Retorna títulos encontrados ou vazio
```

### 3. Python Backend
**Arquivo:** `backend/totvs_client.py` ✅ PRONTO

**Como usar:**
```python
from backend.totvs_client import TotvsMockClient

client = TotvsMockClient()  # Modo MOCK (sem PASOE_URL)

# Buscar NF específica
titulos = client.buscar_titulos_por_nf('84943067001393', 'NF-2026-001234')

# Buscar títulos abertos
abertos = client.buscar_titulos_abertos('84943067001393')

# Buscar por período
periodo = client.buscar_titulos_por_periodo(
    '84943067001393',
    '2026-04-20',
    '2026-04-30'
)
```

### 4. FlutterFlow UI
**Screens necessárias:**
- Screen 1: "Buscar NSU" → input NSU → chama endpoint 1
- Screen 2: "Confirmar NF" → exibe transação → input NF → chama endpoint 2
- Screen 3: "Dashboard Gaps" → chama endpoint 4 → exibe alertas

---

## ✅ Checklist de Deployment

- [ ] Executar `MIGRACAO_PORTAL_OPERADOR.sql` no Supabase
- [ ] Validar 3 colunas criadas: `titulo_totvs_id` (NULL), `numero_nf_manual`, `tipo_vinculacao`
- [ ] Validar índice criado: `idx_conciliacao_tipo_vinculacao`
- [ ] Criar 3 Supabase Edge Functions
- [ ] Deploy `backend/totvs_client.py` em production (ou Lambda/Cloud Function)
- [ ] Testar endpoints com Postman/Insomnia
- [ ] Implementar 3 screens em FlutterFlow
- [ ] Teste E2E: Operador digita NSU → NF → vínculo aparece no DB

---

## 🔗 Próximos Passos

1. **Imediatamente:** Executar migração SQL no Supabase
2. **Semana 1:** Implementar Edge Functions + FlutterFlow screens
3. **Semana 2:** Teste E2E com operadores reais
4. **Semana 3:** Integração com PASOE API real (substituir mock)

---

## 📞 Support & Debugging

### Error: "NSU não encontrado"
→ Verificar se transacao_getnet tem status='pendente'
→ Verificar se filial_cnpj do user corresponde à transação

### Error: "Vínculo não criado"
→ Verificar RLS policies em conciliacao_vinculos
→ Verificar se user tem role 'operador' na filial

### Error: "Título TOTVS não encontrado"
→ Em MOCK: Adicionar dados em MOCK_DATABASE (totvs_client.py)
→ Em PASOE real: Verificar URL e credenciais da API

---

**Versão:** 1.0  
**Status:** ✅ PRONTO PARA IMPLEMENTAÇÃO  
**Aprovado por:** [Aguardando feedback]
