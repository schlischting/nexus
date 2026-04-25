# Nexus: Sistema de Conciliação de Cartões de Crédito

**Status:** Inicialização Completa (24/04/2026)  
**Versão:** 1.0 MVP  
**Stack:** FlutterFlow + Supabase (PostgreSQL) + Python

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  Nexus: Automação Inteligente de Reconciliação de Cartões  │
│                                                             │
│  ✅ Schema PostgreSQL com RLS                              │
│  ✅ Script de Ingestão (Python/Pandas)                    │
│  ✅ Algoritmo de Matching Automático                      │
│  ✅ Documentação Arquitetônica Completa                   │
│  ✅ Roadmap de Implementação (6-9 semanas)               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 O Que é Nexus?

Nexus resolve um problema crítico em empresas com múltiplas filiais: **reconciliação manual de cartões de crédito**.

**Sem Nexus:**
- ❌ Operador abre planilhas Excel
- ❌ Busca manualmente transações GETNET em compras TOTVS
- ❌ Digita em formulários
- ❌ Leva **dias** para reconciliar
- ❌ Taxa alta de erros

**Com Nexus:**
- ✅ Ingestão automática GETNET + TOTVS
- ✅ Matching algoritmo (85%+ automático)
- ✅ Dashboard claro para exceções
- ✅ Validação em **minutos**
- ✅ Rastreamento completo (auditoria)

---

## 📦 O Que Você Recebe

```
Nexus/
├── database/
│   └── schema_nexus.sql              [Schema PostgreSQL com RLS]
├── backend/
│   ├── import_getnet.py              [Script Python para ingestão]
│   ├── requirements.txt               [Dependências Python]
│   └── .env.example                  [Template de variáveis]
├── data/
│   └── extrato_getnet_exemplo.csv    [Dado de teste]
├── docs/
│   └── 2026-04-24-arquitetura-nexus.md [Documentação completa]
├── mobile-app/
│   └── README.md                     [Escopo do PWA]
└── README.md                         [Este arquivo]
```

---

## 🚀 Quick Start

### 1. Setup do Banco de Dados

```bash
# Acesse console.supabase.com
# 1. Crie um novo projeto Nexus
# 2. Vá em SQL Editor
# 3. Abra um novo query
# 4. Cole o conteúdo de database/schema_nexus.sql
# 5. Execute

-- Ou via CLI do Supabase:
supabase db push --db-url "postgresql://user:password@host:5432/nexus" < database/schema_nexus.sql
```

### 2. Setup do Script Python

```bash
# Clone o repositório
cd "d:\Projetos Dev\Nexus"

# Crie virtual env
python -m venv venv
source venv/bin/activate  # No Windows: venv\Scripts\activate

# Instale dependências
pip install -r backend/requirements.txt

# Configure variáveis de ambiente
cp backend/.env.example backend/.env
# Edite backend/.env com suas credenciais Supabase
```

### 3. Teste de Ingestão

```bash
# Teste com dry-run (validação sem enviar)
python backend/import_getnet.py \
  --file data/extrato_getnet_exemplo.csv \
  --filial_id 1 \
  --dry-run

# Esperado: Relatório mostrando 5 transações válidas
```

### 4. Leia a Arquitetura

```bash
# Abra a documentação completa
open docs/2026-04-24-arquitetura-nexus.md
```

---

## 📋 Estrutura de Dados

### Tabelas Principais

| Tabela | Descrição | Chave |
|--------|-----------|-------|
| `filiais` | Dimensão de lojas/filiais | `filial_id` |
| `transacoes_getnet` | Transações de cartão (adquirente) | `transacao_id` |
| `titulos_totvs` | Títulos a receber (ERP) | `titulo_id` |
| `conciliacao_vinculos` | Linking table (N:N) com scoring | `vinculo_id` |
| `user_filiais` | Mapeamento usuário → filial (RLS) | `user_filial_id` |

### Relacionamentos

```
filiais (1) 
  ├─→ (N) transacoes_getnet
  ├─→ (N) titulos_totvs
  └─→ (N) conciliacao_vinculos

transacoes_getnet (1) ──┐
                        ├─→ (N) conciliacao_vinculos
titulos_totvs (1) ──────┘
```

---

## 🔐 Segurança: Row Level Security (RLS)

**Todos os usuários veem apenas dados de suas filiais**, mesmo que consultassem o banco diretamente.

```sql
-- Exemplo: Usuário de SP só vê filial_id=1
SELECT * FROM transacoes_getnet;
-- Retorna apenas transações onde filial_id IN (1)

-- Tenta acessar outro filial:
SELECT * FROM transacoes_getnet WHERE filial_id = 2;
-- Retorna: 0 registros (invisibilidade total)
```

---

## 🤖 Algoritmo de Matching

3 fatores determinam o score (0.0 a 1.0):

1. **Valor** (50% do score)
   - Diferença ≤ 5%: score completo
   - Diferença > 10%: zero pontos

2. **Data** (30% do score)
   - Diferença ≤ 3 dias: score completo
   - Diferença > 7 dias: zero pontos

3. **Tipo/Bandeira** (20% do score)
   - Bandeira bate: score completo
   - Bandeira diferente: pontos reduzidos

**Decisão Final:**
- Score > 0.95 → ✅ **Automático** (conciliado)
- 0.75 < Score < 0.95 → ⏳ **Validação Manual**
- Score < 0.75 → ❌ **Ignorar** (possível fraude/erro)

---

## 📱 Roadmap (6-9 semanas)

### Semana 1-2: Infraestrutura ✅
- [x] Schema PostgreSQL
- [x] RLS Policies
- [ ] Supabase setup (seu projeto)

### Semana 2-3: Ingestão ✅
- [x] Script `import_getnet.py`
- [ ] Integração TOTVS
- [ ] Agendamento com cron

### Semana 3-4: Matching
- [ ] Função PL/pgSQL
- [ ] Trigger automático
- [ ] Dashboard de métricas

### Semana 4-6: Frontend (FlutterFlow)
- [ ] Dashboard de conciliação
- [ ] Página de detalhes
- [ ] Validação manual

### Semana 6-8: PWA (Leitura OCR)
- [ ] Camera capture
- [ ] TensorFlow.js OCR
- [ ] Verificação em tempo real

### Semana 8-9: Testes & Deploy
- [ ] Testes de penetração
- [ ] Performance testing
- [ ] Produção

---

## 💡 Exemplos de Uso

### Ingerir Transações GETNET

```bash
python backend/import_getnet.py \
  --file /path/to/extrato_getnet.csv \
  --filial_id 1
```

**Retorno:** JSON com transações validadas + relatório

### Consultar Transações via Supabase

```javascript
// JavaScript/Flutter
const { data, error } = await supabase
  .from('transacoes_getnet')
  .select('*')
  .eq('filial_id', 1)
  .eq('status', 'pendente')
  .order('data_transacao', { ascending: false });
```

**Nota:** RLS filtra automaticamente por `filial_id` do usuário

### Validar Vínculo Manualmente

```javascript
// Operador aceita sugestão de matching
const { data, error } = await supabase
  .from('conciliacao_vinculos')
  .update({
    status: 'confirmado',
    usuario_validacao: user.email,
    data_validacao: new Date()
  })
  .eq('vinculo_id', 123);
```

---

## 🧪 Testes

```bash
# Testes unitários do import_getnet.py
pytest backend/ -v

# Cobertura
pytest backend/ --cov=backend --cov-report=html
```

---

## 📚 Documentação

| Arquivo | Propósito |
|---------|-----------|
| `docs/2026-04-24-arquitetura-nexus.md` | **Guia arquitetônico completo** |
| `database/schema_nexus.sql` | Schema com comentários |
| `backend/import_getnet.py` | Script com docstrings |
| Este README | Overview e quick start |

---

## 🤝 Contribuindo

1. **Para adicionar novos campos ao schema:**
   - Edite `database/schema_nexus.sql`
   - Crie migration via Supabase CLI
   - Update `import_getnet.py` se necessário

2. **Para melhorar o matching:**
   - Edite `calcular_score_matching()` em `database/schema_nexus.sql`
   - Ajuste pesos (Peso_Valor, Peso_Data, Peso_Tipo)
   - Test com dados históricos

3. **Para adicionar validações:**
   - Edite funções `validar_*()` em `backend/import_getnet.py`
   - Adicione testes em `pytest`

---

## ⚠️ Considerações de Segurança

- ✅ RLS ativado em **TODAS** tabelas
- ✅ Senhas/tokens em `.env` (nunca commit)
- ✅ Autenticação via Supabase Auth (JWT)
- ✅ Auditoria em `usuario_validacao` + `data_validacao`
- ✅ Hash SHA256 para deduplicação (não reversível)

---

## 📊 Métricas de Sucesso

Depois de 3 meses em produção:

| Métrica | Meta |
|---------|------|
| Matches automáticos | ≥ 85% |
| Tempo ingestão | < 5 min (10k transações) |
| Latência query (P95) | < 200ms |
| Tempo validação exceção | < 10s |
| Taxa falsos positivos | < 2% |

---

## 🆘 Troubleshooting

### "Permission denied" ao acessar tabela
**Solução:** Verifique RLS policies. Seu user_id está em `user_filiais` com a filial correta?

### Script Python: "ModuleNotFoundError: No module named 'pandas'"
**Solução:**
```bash
pip install -r backend/requirements.txt
```

### "Hash já visto" - muitas duplicatas
**Solução:** Verifique se o CSV tem linhas duplicadas. Use `extrato_getnet_exemplo.csv` como referência de formato.

---

## 📞 Suporte

- 📖 Documentação: `docs/2026-04-24-arquitetura-nexus.md`
- 🐛 Issues: Crie em `issues/`
- 💬 Dúvidas: Abra discussão em `discussions/`

---

## 📄 Licença

Propriedade do projeto. Não distribuir sem autorização.

---

## ✍️ Versões

| Data | Versão | Mudanças |
|------|--------|----------|
| 24/04/2026 | 1.0 | Release inicial |

---

**Nexus: Automação Inteligente de Reconciliação**  
*Desenvolvido com rigor arquitetônico para escalabilidade e segurança.*
