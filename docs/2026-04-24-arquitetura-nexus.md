# Nexus: Arquitetura de Conciliação de Cartões de Crédito

**Data:** 24 de Abril de 2026  
**Versão:** 1.0  
**Status:** Documentação Inicial  
**Equipe:** Engenharia de Dados & Arquitetura de Software

---

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Arquitetura do Sistema](#arquitetura-do-sistema)
3. [Modelagem de Dados](#modelagem-de-dados)
4. [Fluxo de Ingestão](#fluxo-de-ingestão)
5. [Algoritmo de Matching Automático](#algoritmo-de-matching-automático)
6. [Row Level Security (RLS)](#row-level-security-rls)
7. [Componente Mobile/PWA](#componente-mobilepwa)
8. [Plano de Implementação](#plano-de-implementação)

---

## 🎯 Visão Geral

**Nexus** é um sistema de conciliação automatizada de cartões de crédito que integra:

- **Dados de Transações**: Adquirente GETNET (cartões capturados)
- **Dados de Títulos**: Sistema ERP TOTVS (notas fiscais e vendas)
- **Matching Inteligente**: Algoritmo probabilístico para vincular transações a títulos
- **Segurança em Camadas**: RLS rigoroso baseado em filiais
- **Frontend**: FlutterFlow (mobile-first responsivo)
- **Backend**: Supabase + PostgreSQL (serverless)
- **Ingestão**: Scripts Python (pandas + validação)

### Problema Resolvido

Empresas com múltiplas filiais enfrentam:
- ❌ Reconciliação manual de transações (dias de atraso)
- ❌ Erros em parcelamentos (1 transação → N títulos)
- ❌ Divergências de timing (autorização vs. captura)
- ❌ Falta de auditoria clara (rastreamento de quem validou o quê)

**Nexus resolve** automatizando 85-90% das matches e fornecendo interface clara para exceções.

---

## 🏗️ Arquitetura do Sistema

```
┌──────────────────────────────────────────────────────────────┐
│                         CAMADA APRESENTAÇÃO                   │
├──────────────────────────────────────────────────────────────┤
│  FlutterFlow (Web + Mobile)                                   │
│  - Dashboard de Conciliação                                   │
│  - Visualização de Divergências                               │
│  - Validação Manual                                           │
│  - PWA de Leitura (Visão Computacional)                       │
└───────────────────────┬────────────────────────────────────────┘
                        │ GraphQL / REST API
┌───────────────────────▼────────────────────────────────────────┐
│                    CAMADA API & LÓGICA                         │
├──────────────────────────────────────────────────────────────┤
│  Supabase PostgREST                                            │
│  - Real-time Subscriptions                                     │
│  - RLS Enforcement                                             │
│  - Authentication (JWT via Auth)                              │
└───────────────────────┬────────────────────────────────────────┘
                        │ PostgreSQL Protocol
┌───────────────────────▼────────────────────────────────────────┐
│                    CAMADA DADOS                                │
├──────────────────────────────────────────────────────────────┤
│  PostgreSQL 15+                                                │
│  ├─ transacoes_getnet (adquirente)                            │
│  ├─ titulos_totvs (ERP)                                       │
│  ├─ conciliacao_vinculos (linking table, N:N)               │
│  ├─ filiais (dimensão)                                        │
│  └─ user_filiais (RLS mapping)                               │
│                                                                │
│  RLS Policies:                                                 │
│  └─ Usuários veem apenas dados de suas filiais                │
└───────────────────────┬────────────────────────────────────────┘
                        │ ETL / Batch Ingestion
┌───────────────────────▼────────────────────────────────────────┐
│                    CAMADA INGESTA                              │
├──────────────────────────────────────────────────────────────┤
│  Python Scripts (pandas + validação)                           │
│  ├─ import_getnet.py (CSV → Validated JSON → Supabase)      │
│  ├─ Data Cleaning (tipos, formatos, duplicatas)              │
│  ├─ Hash Detection (SHA256 de NSU+Auth+Valor+Data)           │
│  └─ Matching Score Calculation                               │
│                                                                │
│  Origem de Dados:                                             │
│  ├─ GETNET (extrato_getnet.csv)                              │
│  └─ TOTVS (integração API)                                    │
└──────────────────────────────────────────────────────────────┘
```

### Fluxo de Dados (High-Level)

```
GETNET CSV           TOTVS API
    │                    │
    ▼                    ▼
┌─────────────────────────────┐
│ import_getnet.py (Validação)│
│ - Clean & Transform         │
│ - Hash & Deduplicate        │
│ - Score Matching            │
└─────────────┬───────────────┘
              │ JSON Output
              ▼
         Supabase API
         (transacoes_getnet table)
              │
              ▼
    PostgreSQL Database
         (Storage)
              │
              ▼
┌─────────────────────────────┐
│ Matching Algorithm          │
│ (Trigger + PL/pgSQL)        │
│ - Calcula Score (0.0-1.0)   │
│ - Auto-cria vinculos (>0.95)│
│ - Marca divergências        │
└─────────────┬───────────────┘
              │
              ▼
      conciliacao_vinculos
         (Smart Linking)
              │
              ▼
        FlutterFlow UI
       (Validação Manual)
```

---

## 📊 Modelagem de Dados

### Relações Principais

```
┌─────────────────────────────────────────────────┐
│            ENTIDADES & RELACIONAMENTOS          │
└─────────────────────────────────────────────────┘

filiais (1)
    │
    ├─→ (N) transacoes_getnet
    │
    ├─→ (N) titulos_totvs
    │
    └─→ (N) conciliacao_vinculos


transacoes_getnet (1) ──┐
                        ├─→ (N) conciliacao_vinculos
titulos_totvs (1) ──────┘


Exemplo de Matching:
┌──────────────────────┐
│ Transação GETNET     │      ┌──────────────────────┐
│ NSU: 123456          │◄────┤ Vínculo (Score: 0.98)│
│ Auth: ABC123         │      │ Status: confirmado   │
│ Valor: 1.000,00      │      │ Diff Valor: 0,00     │
│ Data: 15/04/2026     │      │ Diff Dias: 1         │
└──────────────────────┘      └──────────────────────┘
                                      │
┌──────────────────────┐              │
│ Título TOTVS         │◄─────────────┘
│ NF: 001234           │
│ Valor: 1.000,00      │
│ Vencimento: 16/04    │
└──────────────────────┘
```

### Schemas Detalhados

#### **Tabela: transacoes_getnet**

| Campo | Tipo | Constraints | Propósito |
|-------|------|-------------|----------|
| `transacao_id` | BIGSERIAL | PK | Identificador único |
| `filial_id` | INTEGER | FK → filiais | Isolamento por filial (RLS) |
| `nsu` | VARCHAR(20) | UNIQUE+INDEX | Número Sequencial Único (adquirente) |
| `numero_autorizacao` | VARCHAR(20) | UNIQUE | Chave de autorização |
| `data_transacao` | DATE | INDEX | Data da transação |
| `valor` | NUMERIC(15,2) | CHECK >0 | Valor em R$ |
| `status` | status_transacao | ENUM | pendente\|conciliada\|divergencia\|cancelada |
| `hash_transacao` | VARCHAR(64) | UNIQUE | SHA256(NSU+Auth+Valor+Data) para dedup |
| `data_ingesta` | TIMESTAMP | DEFAULT NOW() | Rastreamento de ingestão |

**Índices:**
- `idx_transacoes_getnet_filial_data` (filial_id, data_transacao DESC)
- `idx_transacoes_getnet_nsu` (filial_id, nsu)

#### **Tabela: titulos_totvs**

| Campo | Tipo | Constraints | Propósito |
|-------|------|-------------|----------|
| `titulo_id` | BIGSERIAL | PK | Identificador único |
| `filial_id` | INTEGER | FK → filiais | Isolamento por filial (RLS) |
| `numero_titulo` | VARCHAR(30) | UNIQUE+INDEX | Identificador no ERP |
| `numero_nf` | VARCHAR(20) | - | Número da Nota Fiscal |
| `data_emissao` | DATE | - | Data de emissão |
| `data_vencimento` | DATE | INDEX | Prazo de pagamento |
| `valor_total` | NUMERIC(15,2) | CHECK >0 | Valor bruto |
| `valor_liquido` | NUMERIC(15,2) | CHECK >0 | Valor após deduções |
| `cliente_codigo` | VARCHAR(20) | - | Código cliente no ERP |
| `status` | status_titulo | ENUM | pendente\|pago\|vencido\|cancelado |
| `data_ingesta` | TIMESTAMP | DEFAULT NOW() | Rastreamento |

#### **Tabela: conciliacao_vinculos (Linking Table - N:N)**

| Campo | Tipo | Constraints | Propósito |
|-------|------|-------------|----------|
| `vinculo_id` | BIGSERIAL | PK | Identificador único do vínculo |
| `filial_id` | INTEGER | FK → filiais | RLS |
| `transacao_getnet_id` | BIGINT | FK → transacoes_getnet | Link para transação |
| `titulo_totvs_id` | BIGINT | FK → titulos_totvs | Link para título |
| `diferenca_valor` | NUMERIC(15,2) | - | \|valor_tx - valor_titulo\| |
| `diferenca_dias` | SMALLINT | - | \|data_tx - data_titulo\| |
| `score_confianca` | NUMERIC(3,2) | 0.00-1.00 | Probabilidade de match correto |
| `status` | status_vinculo | ENUM | aguardando_validacao\|confirmado\|rejeitado\|manual |
| `usuario_validacao` | VARCHAR(100) | - | Quem validou |
| `data_validacao` | TIMESTAMP | - | Quando foi validado |

**Índices:**
- `idx_conciliacao_filial`
- `idx_conciliacao_status`
- `idx_conciliacao_score DESC` (para ranking de confiança)

---

## 🔄 Fluxo de Ingestão

### Passo 1: Extração CSV (Adquirente GETNET)

O arquivo `extrato_getnet.csv` é fornecido regularmente com estrutura:

```csv
NSU,Autorização,Data,Hora,Valor,Últimos 4 Dígitos,Bandeira,Estabelecimento,Descrição
123456,ABC123,15/04/2026,14:30:45,1000.00,4567,Visa,001234,"COMPRA NO VAREJO"
123457,ABC124,15/04/2026,14:31:22,250.50,4567,Mastercard,001234,"COMPRA ONLINE"
```

### Passo 2: Validação via `import_getnet.py`

```bash
python import_getnet.py \
  --file extrato_getnet.csv \
  --filial_id 1 \
  --dry-run
```

**O script faz:**

1. **Leitura com Pandas**
   - Detecta encoding (UTF-8)
   - Tipos de dados corretos desde o início

2. **Validações Estruturais**
   - NSU: 6-12 dígitos
   - Autorização: 4-6 caracteres alphanumericos
   - Valor: numérico positivo
   - Data: DD/MM/YYYY ou YYYY-MM-DD
   - Hora: HH:MM:SS
   - Bandeira: whitelist {Visa, Mastercard, Elo, Diners, AMEX, Discover}

3. **Detecção de Duplicatas**
   ```python
   hash = SHA256(f"{nsu}|{auth}|{valor}|{data}")
   ```
   Dentro do mesmo arquivo CSV

4. **Cálculo de Métricas**
   - Total de registros válidos
   - Taxa de sucesso
   - Valor agregado
   - Erros detalhados (linha por linha)

5. **Geração de JSON**
   ```json
   {
     "metadata": {
       "data_ingesta": "2026-04-24T14:30:45.123Z",
       "filial_id": 1,
       "total_registros": 5000,
       "valor_total": 125000.50
     },
     "transacoes": [
       {
         "filial_id": 1,
         "nsu": "000123456",
         "numero_autorizacao": "ABC123",
         "data_transacao": "2026-04-15",
         "hora_transacao": "14:30:45",
         "valor": 1000.00,
         "hash_transacao": "abc123def456...",
         "status": "pendente"
       }
     ]
   }
   ```

### Passo 3: Inserção no Supabase

Via API REST de Supabase:

```bash
curl -X POST https://seu-projeto.supabase.co/rest/v1/transacoes_getnet \
  -H "apikey: sua-chave-anon" \
  -H "Authorization: Bearer seu-jwt-token" \
  -H "Content-Type: application/json" \
  -d @extrato_getnet_processed.json
```

### Passo 4: Ingesta TOTVS (Paralelo)

Integração contínua via:
- API REST TOTVS (webhooks)
- ou arquivo CSV periódico
- ou direto via ODBC

Estrutura esperada similar, com:
- numero_titulo (ID único no ERP)
- numero_nf + serie_nf
- cliente_codigo + cliente_nome
- data_emissao, data_vencimento
- valor_total, valor_liquido

---

## 🤖 Algoritmo de Matching Automático

### Estratégia: Scoring Probabilístico

Cada par (transacao_getnet, titulo_totvs) recebe um **score de confiança** (0.0 a 1.0):

```
SCORE = (Peso_Valor × Score_Valor) + (Peso_Data × Score_Data) + (Peso_Tipo × Score_Tipo)

Onde:
  Peso_Valor = 0.50  (mais importante)
  Peso_Data  = 0.30
  Peso_Tipo  = 0.20  (bandeira, tipo de operação)
```

### Cálculo de Score_Valor

```
Diferença % = |Valor_Transação - Valor_Título| / Valor_Título

Se Diferença ≤ 5%:      Score = 0.50 (peso completo)
Se 5% < Diferença ≤ 10%: Score = 0.25 (metade do peso)
Se Diferença > 10%:       Score = 0.00 (sem pontuação)
```

**Justificativa:**
- Diferentes formas de arredondamento (centavos)
- Descontos aplicados entre captura e faturamento
- Taxa de processamento GETNET

### Cálculo de Score_Data

```
Diferença em dias = |Data_Transação - Data_Vencimento_Título|

Se |Dias| ≤ 3:   Score = 0.30 (peso completo)
Se 3 < |Dias| ≤ 7: Score = 0.15 (metade)
Se |Dias| > 7:   Score = 0.00 (sem pontuação)
```

**Justificativa:**
- Autorização ocorre antes da captura (1-2 dias)
- Processadoras levam até 2-3 dias para depositar
- TOTVS pode ter lag na atualização

### Score_Tipo

```
Se Bandeira do Título == Bandeira da Transação:
  Score = 0.20 (peso completo)
Else:
  Score = 0.05 (confiança reduzida)
```

### Decisão Final

```
IF Score > 0.95:
  ✅ Vínculo AUTOMÁTICO (confirmado)
  - Status: 'confirmado'
  - Transação passada para 'conciliada'
  - Título passado para 'pago'

ELSE IF Score > 0.75:
  ⚠️ SUGESTÃO (aguardando_validacao)
  - Exibir no dashboard para operador
  - Permitir aceitar/rejeitar
  - Registrar quem validou e quando

ELSE:
  ❌ IGNORAR (não criar vínculo)
  - Transação permanece em 'pendente'
  - Título permanece em 'pendente'
```

### Casos Especiais

**Parcelamento (1 Transação → N Títulos)**
```
Transação GETNET:
  NSU: 123456
  Valor: 3.000,00
  Data: 15/04

Títulos TOTVS:
  Título 1: 1.000,00 (Vencimento: 15/04)
  Título 2: 1.000,00 (Vencimento: 15/05)
  Título 3: 1.000,00 (Vencimento: 15/06)

⚠️ Algoritmo verifica:
  1. Soma dos títulos = valor transação? SIM
  2. Cada parcela é múltipla? SIM
  3. Sequência mensal? SIM
  → Cria 3 vinculos com score elevado
```

**Múltiplas Transações → 1 Título**
```
Títulos podem ser pagos em múltiplos cartões:
  - Cliente não possui limite em 1 cartão
  - Compra de varejo (10 transações = 1 NF)

Algoritmo:
  1. Agrupa transações por cliente
  2. Verifica se soma = valor título
  3. Se SIM + datas próximas → vínculo
```

---

## 🔐 Row Level Security (RLS)

### Filosofia de Segurança

**Princípio Zero Trust:** Todos os usuários começam sem permissão. RLS é aplicado em **TODAS** as operações (SELECT, INSERT, UPDATE, DELETE).

### Tabela de Acesso: `user_filiais`

```sql
CREATE TABLE user_filiais (
  user_filial_id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL,           -- Foreign key para auth.users
  filial_id INTEGER NOT NULL,      -- Filial permitida
  perfil VARCHAR(50) NOT NULL,     -- 'leitor', 'operador', 'admin'
  data_criacao TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, filial_id)
);
```

### Políticas de RLS

Cada tabela de domínio segue:

```sql
CREATE POLICY rls_<tabela>_own
  ON <tabela> FOR ALL
  USING (filial_id IN (
    SELECT filial_id FROM user_filiais 
    WHERE user_id = auth.uid()
  ));
```

**Aplicado em:**
- `transacoes_getnet`
- `titulos_totvs`
- `conciliacao_vinculos`
- `filiais`

### Exemplo Prático

**Cenário:** Usuário `user@empresa.com` com acesso apenas à filial SP001 (filial_id=1)

```sql
-- ✅ Permitido (filial_id = 1, que está em sua lista)
SELECT * FROM transacoes_getnet 
WHERE filial_id = 1;

-- ❌ Negado (filial_id = 2, não autorizado)
SELECT * FROM transacoes_getnet 
WHERE filial_id = 2;
-- Retorna: 0 registros (sem erro, invisibilidade)

-- ❌ Negado (INSERT em filial não autorizada)
INSERT INTO transacoes_getnet (filial_id, ...) 
VALUES (2, ...);
-- Retorna: permission denied
```

### Controle de Perfis

```
leitor:
  ├─ SELECT transacoes_getnet, titulos_totvs, conciliacao_vinculos
  └─ NÃO pode modificar ou validar

operador:
  ├─ SELECT + UPDATE conciliacao_vinculos (status, validacao)
  ├─ SELECT transacoes_getnet, titulos_totvs
  └─ Registra quem validou e quando (auditoria)

admin:
  ├─ Todas as operações na filial atribuída
  ├─ Gerenciar user_filiais (para sua filial)
  └─ Acessar logs de auditoria
```

### Rastreamento de Auditoria

Cada validação registra:
```sql
UPDATE conciliacao_vinculos SET
  status = 'confirmado',
  usuario_validacao = auth.user_metadata->>'email',
  data_validacao = NOW()
WHERE vinculo_id = 123;
```

No dashboard: "Validado por [user@empresa.com] em [data/hora]"

---

## 📱 Componente Mobile/PWA

### Visão: App Satélite para Leitura de Comprovantes

**Nome do Projeto:** Nexus Verificador (PWA)

### Escopo de Funcionalidades

#### **Fase 1: MVP (Leitura OCR)**

1. **Camera Integration**
   - Captura foto do cupom GETNET
   - Aceita uploads de imagem também

2. **OCR via Visão Computacional**
   - Extração automática de:
     - NSU (número sequencial)
     - Autorização
     - Valor
     - Data/Hora
     - Últimos 4 dígitos do cartão
     - Bandeira
   - Tecnologia: **TensorFlow.js** ou **ML Kit** (on-device, sem servidor)

3. **Validação Local**
   - Valida campos extraídos contra regras de negócio
   - Exibe warning se campos inválidos
   - Permite edição manual de campos

4. **Submissão**
   - Vincula foto ao registro em transacoes_getnet
   - Armazena imagem em Supabase Storage
   - Cria entrada de auditoria

#### **Fase 2: Matching em Tempo Real**

1. **Query em Tempo Real**
   - Após extrair NSU + Auth, consulta Supabase
   - Mostra status de conciliação (pendente, conciliada, divergência)
   - Exibe título TOTVS vinculado (se encontrado)

2. **Notificações Push**
   - Se divergência detectada
   - Se valor discrepante
   - Se vencimento próximo

3. **Dashboard Operacional**
   - Filtro por filial
   - Filtro por status (pendente, validado, divergência)
   - Busca por NSU/Autorização

#### **Fase 3: Análise Inteligente**

1. **Comparação Visual**
   - Lado a lado: foto cupom vs. dados título TOTVS
   - Destacar discrepâncias em vermelho

2. **Histórico por Cliente**
   - Última compra
   - Padrão de gastos
   - Alertas de fraude (compra incomum)

### Arquitetura PWA

```
┌──────────────────────────────────────────┐
│   Nexus Verificador (PWA)                │
│   Built with: Flutter Web / React Native │
├──────────────────────────────────────────┤
│                                          │
│  Funcionalidades:                        │
│  ├─ Camera (getDisplayMedia API)        │
│  ├─ TensorFlow.js OCR (on-device)       │
│  ├─ Service Worker (offline mode)       │
│  └─ IndexedDB (cache local)             │
│                                          │
└──────────┬───────────────────────────────┘
           │ HTTPS / REST API
           ▼
┌──────────────────────────────────────────┐
│   Supabase PostgREST API                 │
│   - Auth via JWT                         │
│   - Real-time subscriptions              │
│   - RLS enforcement (filial_id)          │
└──────────┬───────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────┐
│   PostgreSQL + Storage                   │
│   ├─ transacoes_getnet (update status)   │
│   ├─ comprovantes (Storage bucket)       │
│   └─ logs_verificacao (auditoria)        │
└──────────────────────────────────────────┘
```

### Fluxo de Uso

```
1. Operador abre PWA em smartphone
2. Clica em "Fotografar Cupom"
3. Câmera ativa, captura imagem
4. TensorFlow.js extrai dados (NSU, Auth, Valor, Data)
5. Valida campos localmente
6. Query: SELECT * FROM transacoes_getnet WHERE nsu = ?
7. Resultado:
   a) Encontrou + Conciliado ✅ → "Este comprovante já foi validado"
   b) Encontrou + Pendente ⏳ → "Aguardando validação do operador"
   c) Não encontrou ❌ → "Comprovante não encontrado (fora de período?)"
8. Upload: salva foto em Supabase Storage + metadata
9. Notificação: envia para operador principal se divergência
```

### Benefícios

- ✅ Validação em tempo real
- ✅ Rastreamento visual (auditoria)
- ✅ Funciona offline (modo degradado)
- ✅ Sem instalação (PWA)
- ✅ Suporta iOS/Android/Web

---

## 📈 Plano de Implementação

### Fase 1: Infraestrutura (Semanas 1-2)

**Responsáveis:** Engenheiro de Dados + DevOps

- [x] Schema PostgreSQL no Supabase
- [x] Políticas RLS
- [x] Índices de performance
- [ ] Supabase project setup (console.supabase.com)
- [ ] Migrations via `supabase/migrations/`
- [ ] Testes de RLS (conectar como usuários diferentes)

**Deliverable:** Base de dados pronta, RLS validado

---

### Fase 2: Pipeline de Ingestão (Semanas 2-3)

**Responsáveis:** Engenheiro de Dados

- [x] Script `import_getnet.py` completo
- [ ] Integração TOTVS (API ou CSV)
- [ ] Agendamento com cron ou Airflow
- [ ] Logging e alertas
- [ ] Testes unitários (pandas transformações)
- [ ] Validação em staging

**Deliverable:** Dados fluindo do GETNET → PostgreSQL

---

### Fase 3: Matching Automático (Semanas 3-4)

**Responsáveis:** Engenheiro de Dados + Backend

- [ ] Implementar função `calcular_score_matching` em PL/pgSQL
- [ ] Trigger que cria vinculos automaticamente
- [ ] Dashboard de métricas (% matches automáticos)
- [ ] Testes com dados históricos
- [ ] Fine-tuning de thresholds (0.95, 0.75)

**Deliverable:** Algoritmo funcionando, 85%+ de matches automáticos

---

### Fase 4: FlutterFlow Frontend (Semanas 4-6)

**Responsáveis:** Frontend + Product

- [ ] Design de UI/UX no Figma
- [ ] Página: Dashboard de Conciliação
  - Filtros: filial, data, status
  - Tabela de vinculos com score
  - Ações: aceitar, rejeitar, editar
- [ ] Página: Detalhes da Transação
  - Lado a lado: transacao_getnet vs. titulo_totvs
  - Histórico de validação
- [ ] Página: Exceções
  - Filtro por tipo (divergência, valor, data)
  - Ações rápidas
- [ ] Integração com Supabase Auth
- [ ] Real-time subscriptions (novo vínculo aparece em tempo real)

**Deliverable:** Interface operacional pronta

---

### Fase 5: PWA (Leitura OCR) (Semanas 6-8)

**Responsáveis:** Frontend Mobile

- [ ] Projeto Flutter Web + React Native Web
- [ ] Integração TensorFlow.js OCR
- [ ] Câmera + upload de imagem
- [ ] Validação de campos extraídos
- [ ] Submissão com foto
- [ ] Service Worker (offline)

**Deliverable:** PWA funcional, testado em iOS/Android

---

### Fase 6: Testes & Hardening (Semanas 8-9)

**Responsáveis:** QA + Security

- [ ] Testes de penetração (RLS bypass)
- [ ] Testes de performance (10k+ transações)
- [ ] Testes de concurrent matching
- [ ] Validação de OCR com 100+ fotos reais
- [ ] Backup & disaster recovery

**Deliverable:** Produção pronta

---

## 🚀 Métricas de Sucesso

| Métrica | Meta |
|---------|------|
| % de matches automáticos | ≥ 85% |
| Tempo de ingestão GETNET | < 5 min (10k transações) |
| Latência query (P95) | < 200ms |
| Disponibilidade | 99.9% |
| Taxa de falsos positivos | < 2% |
| Tempo de validação manual | < 10s por exceção |

---

## 📚 Referências

### Documentação Externa

- [Supabase RLS Docs](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL Full-Text Search](https://www.postgresql.org/docs/current/textsearch.html)
- [FlutterFlow Docs](https://docs.flutterflow.io/)
- [TensorFlow.js OCR](https://github.com/naptha/tesseract.js)

### Arquivos do Projeto

- `database/schema_nexus.sql` - Schema completo
- `backend/import_getnet.py` - Script de ingestão
- `backend/.env.example` - Variáveis de ambiente

---

## ✍️ Notas Finais

Este documento reflete o estado inicial do projeto Nexus (24/04/2026). As implementações devem:

1. **Manter Segurança em Primeiro Lugar**
   - RLS em todas as tabelas
   - JWT para autenticação
   - Auditoria de todas as validações

2. **Priorizar Performance**
   - Índices adequados
   - Particionamento se necessário
   - Cache inteligente

3. **Documentar Mudanças**
   - Updates a este arquivo
   - Migration files comentados
   - Changelog separado

4. **Validar em Staging**
   - Testar com dados reais
   - A/B test algoritmo de matching
   - Feedback operacional

---

**Documento Gerado:** 24 de Abril de 2026  
**Versão:** 1.0  
**Status:** Documentação Oficial do Projeto Nexus
