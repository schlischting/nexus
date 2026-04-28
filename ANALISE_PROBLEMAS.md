# Análise Detalhada: Desalinhamentos entre Código e Dados Reais

**Data da Análise:** 24 de Abril de 2026  
**Arquivo Analisado:** `ADTO 23042026.xlsx`  
**Script Analisado:** `backend/import_getnet.py`  
**Schema Analisado:** `database/schema_nexus.sql`

---

## 📊 DADOS REAIS DO EXCEL

### Estrutura

| Aspecto | Valor |
|---------|-------|
| Total de linhas | 8.990 |
| Colunas | 26 |
| Aba utilizada | "Detalhado" |
| Skip rows | 7 |

### Distribuição por TIPO DE LANÇAMENTO

| Tipo | Quantidade | % | Status |
|------|-----------|---|--------|
| **Vendas** | **4.378** | **48.7%** | ✅ Importar |
| Negociações Realizadas | 3.492 | 38.8% | ❌ Descartar |
| Nulos/Subtotais | 542 | 6.0% | ❌ Descartar |
| Saldo Anterior | 537 | 6.0% | ❌ Descartar |
| Cancelamento/Chargeback | 37 | 0.4% | ❌ Descartar |
| Pagamento Realizado | 4 | 0.0% | ❌ Descartar |

### Dados Críticos

**NSU (NÚMERO COMPROVANTE DE VENDA)**
- Non-null: 8.448 (93.9%)
- Valores '-': 4.033 (45%) ← relacionados a tipos não-Vendas
- Nulos: 542
- **Únicos: 1.023**
- **⚠️ Formato especial:** vem com espaços! Ex: `'000002771   '` (com 3 espaços)
- Amostra: `['000002771   ', '-', '145186923   ', ...]`

**AUTORIZAÇÃO**
- Non-null: 8.448
- Valores '-': 4.033 (mesmo que NSU)
- Nulos: 542

**VALOR DA VENDA**
- Non-null: 8.448
- Valores '-': 4.033
- **Min:** -23.664,14 ⚠️ (negativo!)
- **Max:** 314.830,00
- **Total GERAL:** R$ 79.879.629,33
- **Total VENDAS APENAS:** R$ 80.239.617,33
- **Média:** R$ 18.327,92
- **Formato:** String (inteiros '255', floats '28479.2')

**DATA DA VENDA**
- Formato: `'2026-03-26 00:00:00'` (timestamp completo)
- Valores '-': 4.033
- Alguns NaN (além de '-')

**HORA DA VENDA**
- **Existe como coluna separada!** (coluna 15 no Excel)
- Formato: `'11:07:56'`, `'14:40:06'`, etc.

**CNPJs**
- Únicos: 41 (não 40 como informado)
- Vazios: 542
- Formato: `'84.943.067/0014-74'` (com formatação)

**BANDEIRA**
- Visa Crédito: 3.940 (45.5%)
- Mastercard Crédito: 3.622 (42.0%)
- Elo Crédito: 698 (8.1%)
- Amex Crédito: 188 (2.2%)
- Nulos: 542 (6.0%)

---

## 🔴 PROBLEMAS IDENTIFICADOS

### [PROBLEMA 1] Mapeamento de Colunas com Acentos

**Localização:** `import_getnet.py`, linhas 47-56

**Problema:**
```python
COLUNAS_MAPEAMENTO = {
    'nsu': 'NÚMERO COMPROVANTE DE VENDA (NSU)',  # ❌ Falta acento em NÚMERO
    'numero_autorizacao': 'AUTORIZAÇÃO',  # ❌ Falta acento
    'tipo_lancamento': 'TIPO DE LANÇAMENTO'  # ❌ Falta acento em LANÇAMENTO
}
```

**Realidade:**
- Excel tem: `'NÚMERO COMPROVANTE DE VENDA (NSU)'` (com acentos)
- Script procura por: `'NUMERO COMPROVANTE DE VENDA (NSU)'` (sem acentos)
- **Resultado:** KeyError ao tentar acessar coluna

**Risco:** ⚠️ **CRÍTICO** - Script falha ao ler arquivo

---

### [PROBLEMA 2] NSU com Espaços em Branco

**Localização:** `import_getnet.py`, linhas 83-88

**Problema:**
```python
def validar_nsu(nsu: str) -> bool:
    """NSU não pode ser nulo ou '-'."""
    nsu_limpo = str(nsu).strip()  # ← strip() remove espaços
    return nsu_limpo and nsu_limpo != '-'
```

**Realidade:**
- NSU no Excel: `'000002771   '` (12 caracteres, espaços no final)
- Após `.strip()`: `'000002771'` ✓
- **Mas:** Pode haver NSU só com espaços? Teste necessário

**Risco:** ⚠️ **BAIXO** - `.strip()` está correto

---

### [PROBLEMA 3] Autorização Vazia ou '-' Aceita

**Localização:** `import_getnet.py`, linhas 91-95

**Problema:**
```python
def validar_autorizacao(auth: str) -> bool:
    """Autorização: deve ter pelo menos 1 caractere (não nulo)."""
    return bool(str(auth).strip())  # ← Aceita qualquer string não-vazia
```

**Realidade:**
- 4.033 valores são '-' (não deveriam passar)
- Script atual **rejeita** se vazio/nulo ✓
- **Mas:** Deve também rejeitar '-' explicitamente

**Risco:** ⚠️ **MÉDIO** - Valores '-' estão sendo processados

---

### [PROBLEMA 4] DATA e HORA Separadas vs Timestamp

**Localização:** `import_getnet.py`, linhas 98-115

**Problema:**
```python
# Script extrai data:
data_obj = datetime.strptime(str(data_str).strip(), fmt)

# Schema espera:
data_transacao DATE NOT NULL
hora_transacao TIME NOT NULL
```

**Realidade:**
- Excel: Coluna 14 `'DATA DA VENDA'` = `'2026-03-26 00:00:00'` (timestamp)
- Excel: Coluna 15 `'HORA DA VENDA'` = `'11:07:56'` (hora separada)
- Script extrai **ambos** do timestamp OK ✓
- **Mas:** Não usa coluna HORA DA VENDA, usa hora do timestamp

**Risco:** ⚠️ **BAIXO-MÉDIO** - Hora do timestamp é `00:00:00`, não a hora real!

---

### [PROBLEMA 5] Valores Negativos em VALOR_VENDA

**Localização:** `import_getnet.py`, linhas 119-138

**Problema:**
```python
def validar_valor(valor_str) -> Tuple[bool, Optional[float]]:
    if valor_float <= 0:
        return False, None  # ← Rejeita valores <= 0
    return True, valor_float
```

**Realidade:**
- Existem valores: `-23.664,14` no arquivo
- **Mas:** Esses -23.664,14 NÃO são de tipo 'Vendas' (são de Negociações/Cancelamentos)
- Script filtra por TIPO antes de validar valor ✓ (OK)
- Valores negativos em 'Vendas' são raros/inexistentes

**Risco:** ⚠️ **BAIXO** - Filtro por tipo protege

---

### [PROBLEMA 6] Schema: CHECK valor > 0

**Localização:** `database/schema_nexus.sql`, linha 37

**Problema:**
```sql
valor NUMERIC(15, 2) NOT NULL CHECK (valor > 0),
```

**Realidade:**
- Só valores de 'Vendas' são inseridos
- Vendas tem valores positivos ✓
- Check está correto

**Risco:** ✅ **NENHUM**

---

### [PROBLEMA 7] Hash SHA256 com Valores Negativos/Vazios

**Localização:** `import_getnet.py`, linhas 167-174

**Problema:**
```python
def gerar_hash_transacao(nsu: str, auth: str, valor: str, data_str: str) -> str:
    chave = f"{nsu}|{auth}|{valor}|{data_str}"
    return hashlib.sha256(chave.encode()).hexdigest()
```

**Realidade:**
- Hash feito APÓS validação ✓
- Se falhar validação, não chega aqui
- OK

**Risco:** ✅ **NENHUM**

---

### [PROBLEMA 8] Distribuição por Tipo Não Validada

**Localização:** `import_getnet.py`, linhas 256-268

**Problema:**
```python
tipo_lancamento = str(row.get(COLUNAS_MAPEAMENTO['tipo_lancamento'], '')).strip()

if tipo_lancamento not in [TIPO_LANCAMENTO_VALIDO]:  # ← Busca por 'Vendas'
    # Contar por tipo para relatório
    if tipo_lancamento:
        self.metricas['distribuicao_tipos'][tipo_lancamento] = \
            self.metricas['distribuicao_tipos'].get(tipo_lancamento, 0) + 1
    self.metricas['filtradas_tipo_lancamento'] += 1
    continue
```

**Realidade:**
- Tipo esperado: `'Vendas'` (sem acento)
- Tipo no Excel: `'Vendas'` ✓ (SEM acento, OK!)
- Script filtra corretamente

**Risco:** ✅ **NENHUM**

---

### [PROBLEMA 9] Encoding de Output

**Localização:** `import_getnet.py`, linhas 1-40

**Problema:**
- Script não força encoding UTF-8 no output
- Windows PowerShell/CMD pode estar em cp1252 (Latin-1)
- Acentos podem aparecer como '?' ou erro

**Realidade:**
- Pandas lê OK
- Output pode ter problemas com acentos

**Risco:** ⚠️ **MÉDIO** - Output em console pode estar corrompido (ver relatório anterior)

---

## 📋 RESUMO DE DESALINHAMENTOS

| # | Problema | Gravidade | Afetado | Status |
|---|----------|-----------|---------|--------|
| 1 | Acentos em nomes de colunas | 🔴 CRÍTICO | import_getnet.py | Script falha |
| 2 | NSU com espaços | 🟡 BAIXO | import_getnet.py | Tratado com strip() |
| 3 | Autorização '-' não rejeitada | 🟡 MÉDIO | import_getnet.py | Precisa validação |
| 4 | Hora do timestamp vs HORA DA VENDA | 🟡 MÉDIO | import_getnet.py | Hora errada (00:00:00) |
| 5 | Valores negativos | 🟡 BAIXO | schema_nexus.sql | Filtro por tipo protege |
| 6 | Encoding UTF-8 no output | 🟡 MÉDIO | import_getnet.py | Cosmético, não crítico |
| 7 | CNPJs: 41 vs 40 esperados | 🟢 BAIXO | doc | Informação desatualizada |
| 8 | Filtro tipo_lancamento | ✅ OK | import_getnet.py | Funciona |
| 9 | Filtragem por nulos | ✅ OK | import_getnet.py | Funciona |

---

## ✅ PRÓXIMAS AÇÕES RECOMENDADAS

1. **[CRÍTICO]** Corrigir nomes de colunas com acentos
   - Use índices de coluna (mais robusto)
   - Ou normalize acentos na entrada

2. **[MÉDIO]** Validar Autorização != '-'
   - Adicionar check explícito

3. **[MÉDIO]** Usar coluna HORA DA VENDA separada
   - Trocar de timestamp para valor real

4. **[MÉDIO]** Forçar encoding UTF-8
   - Adicionar ao início do script

5. **[INFORMAÇÃO]** Atualizar contagem de CNPJs (40 → 41)

---

## 🔍 VERIFICAÇÕES ADICIONAIS

- Comportamento exato de acentos Python 3.12 Windows UTF-8
- Se coluna HORA DA VENDA está sempre preenchida
- Se NSU com espaços é padrão ou exceção
