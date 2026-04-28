# Nexus — Fluxo de Negócio Definitivo
**Versão:** 3.0 (validada em sessão de análise 25/04/2026)

---

## 🏢 Contexto da Empresa

- **Empresa:** Minusa Tratorpeças Ltda
- **CNPJ Matriz:** 84.943.067/0001-50
- **Filiais:** 41 CNPJs únicos
- **ERP:** TOTVS Progress 12 Datasul (PASOE disponível)
- **Adquirente:** GETNET (1 arquivo consolidado com todas as filiais)
- **Problema:** Nenhuma integração entre maquininha de cartão e ERP

---

## 📋 Regra de Negócio Central

> **Toda transação GETNET tem um título correspondente no TOTVS.**
> Se não tem NF → tem AN (Adiantamento). Nunca fica órfã.
> Todos os títulos do cliente GETNET são de cartão (estorno do cliente para GETNET).

---

## 🔄 Os 3 Cenários de Venda

### Cenário 1 — Cartão + Nota juntos
```
Cliente passa cartão → NF emitida no mesmo momento
Operador vincula NSU à NF no portal
```

### Cenário 2 — Cartão antes da Nota
```
Cliente passa cartão
→ Financeiro cria AN manualmente no TOTVS
→ Operador vincula NSU à AN no portal
→ Nexus baixa a AN via PASOE
→ Dias depois: NF emitida
→ AN abate saldo da NF automaticamente no TOTVS
→ Nexus não precisa fazer nada
```

### Cenário 3 — Nota antes do Cartão
```
NF emitida no TOTVS
→ Cliente volta depois e paga no cartão
→ Operador vincula NSU à NF existente
```

---

## 👥 Perfis de Usuário

| Perfil | Acesso | Responsabilidade |
|--------|--------|-----------------|
| `operador_filial` | Só sua filial | Lança NSU + NF, vê gaps da filial |
| `supervisor` | Todas as filiais | Valida matches, resolve AN, exporta para TOTVS |
| `admin` | Total + parâmetros | Configurações do sistema |

---

## 🔄 Fluxo Completo do Sistema

```
IMPORTAÇÕES DIÁRIAS (automáticas)
├── Excel GETNET → import_getnet.py → transacoes_getnet
└── Export TOTVS → titulos_totvs (programa Progress)

OPERADOR NA FILIAL
├── Vê 🔴 NSUs sem título vinculado
├── Vê 🟡 Títulos sem NSU
├── Digita NSU (do comprovante físico)
├── Digita número da NF (ou AN)
├── Informa modalidade (débito/crédito)
└── Informa quantidade de parcelas

VALIDAÇÃO AUTOMÁTICA (Nexus)
├── NSU existe em transacoes_getnet?
│   ├── NÃO → status: nsu_invalido
│   │         fica pipocando para operador corrigir
│   └── SIM → busca títulos da NF informada
│             em titulos_totvs

MATCH AUTOMÁTICO (engine Nexus)
Campos por prioridade:
1. filial_cnpj (obrigatório — vem do login)
2. numero_nf (operador informou)
3. valor bruto aproximado (tolerância configurável, default 5%)
4. data aproximada (tolerância configurável, default 3 dias)

Score:
├── > 0.95 → match automático confirmado
├── 0.75-0.95 → sugestão para supervisor
│               com % de chance exibido
└── < 0.75 → sem sugestão, gap registrado

SUPERVISOR NA MATRIZ
├── Valida matches sugeridos (0.75-0.95)
├── Resolve casos de AN
│   (autoriza operador ou faz match diretamente)
├── Vê gaps de todas as filiais
├── Confirma vínculos
└── Exporta JSON para TOTVS (manual, sob demanda)

TOTVS (programa Progress)
├── Recebe JSON do Nexus
├── Localiza título por: filial + especie + serie + numero + parcela
├── Executa baixa com valor_liquido_parcela
├── Grava NSU no campo genérico do movimento ACR
└── Retorna JSON com status (ok/erro por título)

NEXUS (após retorno TOTVS)
└── Atualiza status do vínculo
    ├── baixado → concluído
    ├── baixado_parcial → supervisor ciente
    └── erro_baixa → supervisor analisa e reprocessa
```

---

## 📊 Parcelamento

- **1 NSU = 1 título sempre** (na prática)
- NF com múltiplos cartões → TOTVS gera títulos separados por cartão
- Cada título tem seu próprio NSU
- Parcelas no TOTVS: sem padrão (a1, 01, b2...) — identificadas por especie+serie+numero+parcela

---

## 🔴 Dashboard Operador (por filial)

```
🔴 NSUs sem título vinculado     12
   [lista de NSUs pendentes]
   [botão: informar NF]

🔴 Lançamentos com problema       2
   NSU: 000001419 — NSU não encontrado na GETNET
   [editar]

🟡 Títulos sem NSU da GETNET      8
   [lista de NFs pendentes]

✅ Conciliados hoje               45
```

---

## 🟡 Dashboard Supervisor (todas filiais)

```
✅ Match automático (>0.95)      234   [confirmar em lote]
🟡 Sugestões pendentes            23   [validar um a um]
🔴 Gaps sem solução               15   [ver por filial]
⚠️ Erros de baixa                  3   [reprocessar]

FILIAL    NSU s/ título   NF s/ NSU   Valor gap
001            3               2      R$ 4.500
002            0               1      R$ 1.200
003            5               0      R$ 8.900
```

---

## 📁 Comunicação Nexus ↔ TOTVS (JSON)

### Nexus → TOTVS (baixa)
```json
[
  {
    "nexus_vinculo_id": "uuid-aqui",
    "nsu": "000001419",
    "filial_cnpj": "84943067001636",
    "duplicata_especie": "NF",
    "duplicata_serie": "001",
    "duplicata_numero": "001234",
    "duplicata_parcela": "a1",
    "modalidade": "credito",
    "valor_liquido_parcela": 390.00,
    "data_vencimento": "2026-05-28",
    "status": "pendente"
  }
]
```

### TOTVS → Nexus (resultado)
```json
[
  {
    "nexus_vinculo_id": "uuid-aqui",
    "nsu": "000001419",
    "status": "baixado",
    "data_baixa": "2026-04-25",
    "erro_descricao": null
  }
]
```

---

## ⚙️ Parâmetros Configuráveis (tabela config)

| Parâmetro | Default | Descrição |
|-----------|---------|-----------|
| tolerancia_valor_pct | 5% | Tolerância % no match de valor |
| tolerancia_dias | 3 | Tolerância em dias no match de data |
| score_auto | 0.95 | Score mínimo para match automático |
| score_sugestao | 0.75 | Score mínimo para sugestão ao supervisor |

---

## 🔗 Integração TOTVS Progress

### Programa 1 — Export diário (TOTVS → Nexus)
```
FOR EACH título em aberto
  WHERE cliente = GETNET
  OUTPUT JSON com:
  filial_cnpj, especie, serie, numero, parcela,
  valor_bruto, data_vencimento
```

### Programa 2 — Baixa (Nexus → TOTVS)
```
FOR EACH registro no JSON recebido:
  FIND título por filial+especie+serie+numero+parcela
  RUN baixa com valor_liquido_parcela
  WRITE nsu_getnet no campo ACR genérico
  WRITE nexus_vinculo_id no campo ACR genérico
  RETURN status ok/erro
```

### Tabela no TOTVS
**Nenhuma nova tabela necessária.**
Apenas campos genéricos no movimento ACR:
- `nsu_getnet` (char)
- `nexus_vinculo_id` (char)
