# NEXUS — Fluxo do Operador V2.0

## 📋 Visão Geral

O operador agora tem 3 ações principais no dashboard:
1. **Lançar NSU SEM Vínculo** → NSU chega sozinha, será vinculada depois
2. **Lançar NSU COM Vínculo** → Vincula NSU à NF em 3 passos
3. **Buscar NSU Pendente** → Encontra NSU órfã para vincular agora

---

## 🎯 Casos de Uso

### Caso 1: NSU chega antes da NF

```
Sequência:
1. Cliente passa cartão (NSU gerada)
2. Operador clica "+ Lançar NSU SEM Vínculo"
3. Digita o NSU (ex: 123456789)
4. Sistema busca em transacoes_getnet
5. Mostra: Valor, Bandeira, Data
6. Salva como "pendente" no banco
7. Dias depois, NF é emitida
8. Operador clica "Buscar NSU Pendente"
9. Encontra a NSU e clica "Vincular NF Agora"
10. Abre o wizard para vincular à NF
```

### Caso 2: NSU e NF chegam juntas

```
Sequência:
1. Cliente passa cartão + recebe NF
2. Operador clica "+ Lançar NSU COM Vínculo"
3. STEP 1: Busca NSU (123456789)
4. STEP 2: Busca NF (NF-001234)
5. Sistema calcula score automaticamente
6. STEP 3: Revisa dados + clica "Confirmar"
7. Sistema insere vínculo (confirmado ou sugerido)
```

### Caso 3: NF chega antes da NSU

```
Sequência:
1. NF emitida no TOTVS
2. Operador espera o cliente passar cartão
3. Quando NSU chega, operador clica "+ Lançar NSU SEM Vínculo"
4. Salva como "pendente"
5. Depois clica "Buscar NSU Pendente" e vincula
```

### Caso 4: NSU órfã (nunca teve NF)

```
Sequência:
1. NSU foi lançada como "pendente"
2. Dias passam, nenhuma NF foi encontrada
3. Sistema mostra com status "órfã"
4. Operador pode:
   - Manter como observação (verificar recebimento)
   - Ou criar uma AN (Adiantamento) manualmente
   - Ou contactar supervisor
```

---

## 🖥️ Layout do Dashboard V2

### SEÇÃO 1: Quick Actions
```
┌─────────────────────────────────────────┐
│  🔴 + Lançar NSU SEM Vínculo            │
│  🟢 + Lançar NSU COM Vínculo            │
│  🔍 Buscar NSU Pendente                 │
└─────────────────────────────────────────┘
```

### SEÇÃO 2: Métricas (4 cards)
```
┌──────────────────────────────────────────┐
│ 🔴 NSUs Pendentes   │ 🟡 NSUs Sugeridas │
│     5               │      2             │
│                     │                    │
│ 📋 Títulos Pendentes│ ✅ Conciliados    │
│     8               │     45             │
└──────────────────────────────────────────┘
```

### SEÇÃO 3: Tabs (DataTables)

#### Tab 1: NSUs Pendentes (orphaned)
| NSU | Valor | Bandeira | Tipo | Data | Dias | Ação |
|-----|-------|----------|------|------|------|------|
| 123456789 | R$ 1.050,00 | Visa | Crédito | 15/04 | 13 | [Vincular NF] |

#### Tab 2: Sugestões (0.75-0.95)
| NSU | NF Sugerida | Score | Diff Valor | Diff Dias | Ação |
|-----|---------|-------|-----------|-----------|------|
| 987654321 | NF-001234 | 85% | -2% | 1 dia | [Confirmar] [Rejeitar] |

#### Tab 3: Títulos Sem NSU
| NF | Valor | Data Emissão | Dias Vencimento | Ação |
|----|-------|--------------|-----------------|------|
| NF-001234 | R$ 2.500,00 | 10/04 | 15 dias | [Vincular NSU] |

#### Tab 4: Últimas Conciliações
| NSU | NF | Bandeira | Valor | Data Vínculo | Usuário |
|-----|----|----|-------|--------------|---------|
| 123456789 | NF-001234 | Visa | R$ 1.050,00 | 15/04 14:30 | operador |

---

## 🔌 APIs Utilizadas

### GET /api/search/nsu?q=123456
Busca NSU em `transacoes_getnet`
```json
{
  "transacoes": [
    {
      "id": "uuid",
      "nsu": "123456789",
      "valor": 1050.00,
      "data_venda": "2026-04-15",
      "hora_venda": "14:30:00",
      "bandeira": "Visa",
      "modalidade": "credito",
      "tipo": "credito",
      "status": "pendente",
      "diasPendente": 13
    }
  ]
}
```

### GET /api/search/nf?q=001234
Busca NF em `titulos_totvs`
```json
{
  "titulos": [
    {
      "id": "uuid",
      "numero_nf": "NF-001234",
      "numero_titulo": "TIT-001234",
      "valor": 2500.00,
      "valor_bruto": 2500.00,
      "valor_liquido": 2450.00,
      "data_emissao": "2026-04-10",
      "data_vencimento": "2026-05-10",
      "cliente_codigo": "00001",
      "cliente_nome": "Cliente A",
      "status": "pendente",
      "diasVencimento": 12
    }
  ]
}
```

### POST /api/vinculos/calculate-score
Calcula score de correspondência
```json
{
  "nsu_id": "uuid-nsu",
  "nf_id": "uuid-nf"
}
```

Resposta:
```json
{
  "score": 0.95,
  "breakdown": {
    "valor_diff": "2.50",
    "dias_diff": 1,
    "bandeira_match": true
  },
  "details": {
    "valor_score": "0.475",
    "dias_score": "0.285",
    "bandeira_score": "0.200"
  }
}
```

---

## 📊 Status dos Vínculos

| Status | Significado | O Que Fazer |
|--------|-------------|------------|
| `pendente` | NSU lançada sem NF | Aguardar NF chegar |
| `sugerido` | Match automático 0.75-0.95 | Supervisor valida |
| `confirmado` | Match automático >0.95 | Nada, pronto para exportar |
| `rejeitado` | Score < 0.75 | Operador vincula manualmente |
| `órfã` | NSU muito antiga, sem NF | Contatar supervisor |

---

## 🧮 Cálculo do Score

```
Score Total = (Valor×0.5) + (Dias×0.3) + (Bandeira×0.2)

Valor:
├─ Tolerância: 5%
├─ Score = 1 - (|NSU_valor - NF_valor| / NF_valor)
└─ Peso: 50%

Dias:
├─ Tolerância: 30 dias
├─ Score = 1 - (dias_diff / 30)
└─ Peso: 30%

Bandeira:
├─ Se match: 1.0
├─ Se mismatch: 0.0
└─ Peso: 20%

Resultado:
├─ > 0.95 → ✅ Confirmado (automático)
├─ 0.75-0.95 → ⚠️ Sugerido (supervisor valida)
└─ < 0.75 → ❌ Rejeitado (operador vincula manual)
```

---

## 🎯 Fluxo Step-by-Step do Wizard

### Step 1: Buscar NSU
```
Input: NSU com autocomplete
Display:
├─ Valor
├─ Bandeira + ícone
├─ Tipo (Crédito/Débito)
├─ Data
├─ Dias desde transação
└─ Status atual

Next: Habilitado quando NSU encontrada
```

### Step 2: Vincular NF + Detalhes
```
Input: NF com autocomplete
Display:
├─ Valor
├─ Data Vencimento
├─ Cliente
└─ Status

Select: Modalidade (Débito/Crédito)
Input: Parcelas (se crédito)
Textarea: Observações (opcional)

Score Bar:
├─ Porcentagem dinâmica
├─ Cor: Verde >95% | Amarelo 75-95% | Vermelho <75%
└─ Breakdown: Valor%, Dias, Bandeira

Next: Habilitado quando Score calculado
```

### Step 3: Confirmar
```
Display:
├─ NSU (dados resumidos)
├─ NF (dados resumidos)
├─ Score final (com cor)
├─ Diferenças (valor, dias)
├─ Modalidade + Parcelas
└─ Observações

Alert (se Score < 0.75):
└─ "⚠️ Score baixo. Supervisor pode rejeitar."

Buttons:
├─ [Voltar] → Step 2
├─ [Confirmar] → Insere vínculo
└─ [Cancelar] → Fecha wizard

Result:
├─ Toast: "Vínculo criado! Score: 95%"
└─ Redirect: /operador/dashboard
```

---

## 📝 Checklist de Testes

- [ ] Lançar NSU SEM vínculo
- [ ] Buscar NSU pendente
- [ ] Vincular NSU à NF em 3 steps
- [ ] Score > 95% → Status "confirmado"
- [ ] Score 75-95% → Status "sugerido"
- [ ] Score < 75% → Status "rejeitado"
- [ ] Visualizar todas as 4 abas do dashboard
- [ ] Cada aba mostra dados corretos
- [ ] Botões de ação funcionam
- [ ] Métricas atualizam em tempo real
- [ ] Responsivo em mobile

---

## 🔗 Links de Integração

- **Schema:** `database/schema_nexus.sql`
- **Queries:** `lib/supabase/queries.ts`
- **APIs:** `app/api/search/nsu`, `app/api/search/nf`, `app/api/vinculos/calculate-score`
- **Componentes:** `components/ui/bandeira-badge`, `score-bar`, `dias-badge`
- **Dashboard:** `app/operador/dashboard/page.tsx` (V2)

---

**Última atualização:** 2026-04-28
**Versão:** 2.0
