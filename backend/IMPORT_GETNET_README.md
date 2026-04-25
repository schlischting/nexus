# Importador GETNET Excel (ADTO) → Nexus

**Versão:** 2.0 (atualizada 24/04/2026)  
**Arquivo de Entrada:** ADTO_*.xlsx (Excel)  
**Saída:** JSON pronto para Supabase

---

## 🎯 Visão Geral

Script Python que lê o arquivo Excel **ADTO_23042026.xlsx** (ou similar) e:

1. Lê a aba **"Detalhado"** (pulando as 7 primeiras linhas de header)
2. Filtra apenas transações com `TIPO DE LANÇAMENTO == 'Vendas'`
3. Descarta linhas nulas ou duplicadas
4. Valida todos os campos críticos
5. Gera relatório detalhado
6. Exporta JSON pronto para Supabase

---

## 📊 Arquivo Excel Esperado

### Características

| Aspecto | Detalhes |
|---------|----------|
| **Formato** | .xlsx (Excel 2007+) |
| **Aba Esperada** | "Detalhado" |
| **Linhas Puladas** | Primeiras 7 (header) |
| **Shape Real** | 8.990 linhas × 26 colunas |
| **Registros Úteis** | 4.378 (apenas "Vendas") |

### Colunas Mapeadas

| Campo Excel | Atributo Interno | Tipo | Obrigatório |
|------------|-----------------|------|-----------|
| ESTABELECIMENTO COMERCIAL | codigo_ec | string | ✅ (filtro: não nulo) |
| CPF / CNPJ | filial_cnpj | string | ✅ (regex dígitos) |
| NÚMERO COMPROVANTE DE VENDA (NSU) | nsu | string | ✅ (não '-') |
| AUTORIZAÇÃO | numero_autorizacao | string | ✅ |
| DATA DA VENDA | data_venda | datetime | ✅ (formato: '2026-03-26 00:00:00') |
| VALOR DA VENDA | valor_venda | float | ✅ (não '-') |
| BANDEIRA / MODALIDADE | bandeira | string | ✅ (ex: 'Visa Crédito') |
| TIPO DE LANÇAMENTO | tipo_lancamento | string | ✅ (filtro: == 'Vendas') |

---

## 🚀 Como Usar

### 1. Preparar Ambiente

```bash
# Clone o repositório
cd "d:\Projetos Dev\Nexus"

# Crie virtual env
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Instale dependências
pip install -r backend/requirements.txt
```

### 2. Executar em Modo DRY-RUN (Recomendado Primeiro)

```bash
# Teste com validação, sem inserção
python backend/import_getnet.py \
  --file ADTO_23042026.xlsx \
  --filial-cnpj "12345678000195" \
  --dry-run
```

**O que você verá:**
- Relatório completo de processamento
- Quantidade de linhas válidas, descartadas, com erro
- Distribuição de tipos (Vendas, Negociações, etc.)
- Primeiros 5 erros de validação
- Arquivo JSON gerado: `ADTO_23042026_processed.json`

### 3. Validar Saída

```bash
# Verifique o JSON gerado
cat ADTO_23042026_processed.json | head -50
```

Esperado:
```json
{
  "metadata": {
    "data_ingesta": "2026-04-24T14:30:45.123Z",
    "filial_cnpj": "12345678000195",
    "total_registros": 4378,
    "valor_total": 1250000.50
  },
  "transacoes": [
    {
      "filial_cnpj": "12345678000195",
      "nsu": "123456",
      "numero_autorizacao": "ABC001",
      "data_transacao": "2026-03-26",
      "hora_transacao": "14:30:45",
      "valor": 255.00,
      "bandeira": "Visa",
      "codigo_ec": "001234",
      "tipo_lancamento": "Vendas",
      "hash_transacao": "abc123def456...",
      "status": "pendente"
    }
  ]
}
```

### 4. Produção (Inserir no Supabase)

Uma vez validado:

```bash
# Remove --dry-run para inserção real
python backend/import_getnet.py \
  --file ADTO_23042026.xlsx \
  --filial-cnpj "12345678000195"
```

⚠️ **Requer:**
- `.env` configurado com credenciais Supabase
- Schema SQL já executado (`database/schema_nexus.sql`)
- Usuário de teste mapeado em `user_filiais`

---

## 📋 Filtros Aplicados

### Ordem de Processamento

```
1. TIPO_LANÇAMENTO != 'Vendas'  → DESCARTAR
   └─ Filtra automaticamente:
      - Negociações Realizadas (3.492)
      - Saldo Anterior (537)
      - Cancelamento/Chargeback (37)
      - Pagamento Realizado (4)

2. ESTABELECIMENTO_COMERCIAL nulo → DESCARTAR
   └─ São subtotais/linhas vazias

3. NSU nulo OU NSU == '-' → DESCARTAR

4. VALOR_VENDA nulo OU VALOR_VENDA == '-' → DESCARTAR

5. VALIDAÇÕES ESTRUTURAIS
   └─ Data inválida
   └─ Bandeira desconhecida
   └─ CNPJ não bate com filial
   └─ Autorização vazia

6. DETECÇÃO DE DUPLICATAS
   └─ Hash SHA256(NSU + Auth + Valor + Data)
   └─ Se já visto no mesmo arquivo → flag como duplicata
```

---

## 📊 Relatório de Exemplo

Depois de executar, você verá:

```
================================================================================
RELATÓRIO DE INGESTÃO GETNET - ADTO
================================================================================
Data: 2026-04-24 14:30:45
Filial CNPJ: 12345678000195
Arquivo: ADTO_23042026.xlsx
Modo: DRY-RUN (sem inserção)
--------------------------------------------------------------------------------

📊 RESUMO DE PROCESSAMENTO:
  Total de linhas no Excel:        8,990
  Processadas:                     8,990
    ├─ Filtradas (não 'Vendas'):   4,612
    ├─ Descartes (nulos):            213
    ├─ Válidas (inserção):         4,378 ✅
    └─ Com erro (validação):         123 ❌
  Duplicatas detectadas:           45
  Valor total importado:           R$ 1,250,000.50

📋 DISTRIBUIÇÃO DE TIPOS (DESCARTADOS):
  ├─ Negociações Realizadas: 3,492
  ├─ Saldo Anterior: 537
  ├─ Cancelamento/Chargeback: 37
  └─ Pagamento Realizado: 4

📈 TAXA DE SUCESSO: 48.7%

⚠️  ERROS DE VALIDAÇÃO (mostrando 5 primeiros de 123):
  Linha 1,234 (NSU 654321):
    └─ Autorização vazia ou inválida; Bandeira inválida ou desconhecida: "Cartão Desconhecido"
  Linha 1,567 (NSU 654322):
    └─ CNPJ não bate: 98765432000100 vs 12345678000195
  ...

================================================================================
```

---

## 🔧 Troubleshooting

### Erro: "Aba 'Detalhado' não encontrada"

**Solução:** Verifique nome exato da aba no Excel. Pode estar:
- "DETALHADO" (maiúsculas)
- "detalhado" (minúsculas)
- Com espaços: "Detalhado "

Edite a linha no script:
```python
sheet_name='Detalhado'  # ← mudar aqui
```

### Erro: "Colunas faltantes no Excel"

**Solução:** Arquivo pode ter estrutura diferente. Verifique:
1. Se é o Excel correto (ADTO_*.xlsx)
2. Se tem 26 colunas
3. Nomes exatos das colunas em `COLUNAS_MAPEAMENTO`

### Muitos erros de "Bandeira inválida"

**Solução:** Adicionar novo padrão em `validar_bandeira()`:

```python
bandeiras_conhecidas = {
    'visa': 'Visa',
    'sua_bandeira_nova': 'SuaBandeira',  # ← adicionar
    # ...
}
```

### Warnings sobre linhas nulas

**Esperado:** Subtotais do Excel são descartados silenciosamente.
Verifique `import_getnet.log` para detalhes.

---

## 📈 Métricas Esperadas

Com base no arquivo ADTO_23042026.xlsx:

| Métrica | Valor Esperado |
|---------|---|
| Total de linhas | ~8.990 |
| Tipo "Vendas" | ~4.378 |
| Taxa de sucesso | ~48-50% |
| Duplicatas | < 1% |
| Valor total | > R$ 1M |

---

## 🔐 Segurança

- ✅ Hash SHA256 para deduplicação (não reversível)
- ✅ CNPJ validado com regex (apenas dígitos)
- ✅ Sem dados sensíveis em logs (apenas NSU/Auth para erro)
- ✅ Arquivo JSON é intermediário (não commitado)
- ✅ RLS aplicado na inserção Supabase

---

## 🚀 Próximos Passos

1. ✅ Validar com `--dry-run`
2. ✅ Revisar relatório e erros
3. ⬜ Ajustar bandeiras/filtros se necessário
4. ⬜ Executar sem `--dry-run` para produção
5. ⬜ Verificar dados no Supabase: `SELECT COUNT(*) FROM transacoes_getnet WHERE filial_cnpj = '...'`

---

## 📞 Suporte

- Ver `docs/2026-04-24-arquitetura-nexus.md` para contexto geral
- Logs completos em `import_getnet.log`
- JSON de saída em `ADTO_*_processed.json`

---

**Script atualizado para Excel GETNET real - Pronto para produção!**
