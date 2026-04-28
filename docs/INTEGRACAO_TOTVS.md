# Nexus — Requisitos Integração TOTVS Progress 12 Datasul

---

## Stack TOTVS

- **ERP:** TOTVS Progress 12 Datasul
- **Servidor de aplicação:** PASOE (Progress Application Server OE)
- **Linguagem:** Progress ABL (Advanced Business Language)
- **Módulo relevante:** ACR (Contas a Receber)

---

## O que o Progress faz (APENAS 2 programas)

### Programa 1 — Export diário de títulos em aberto

**Quando roda:** Diariamente (agendado no Schedule Datasul)

**Lógica:**
```
FOR EACH título em aberto no ACR
  WHERE cliente = código GETNET
  AND status = 'aberto'
  GERA JSON com todos os campos
  SALVA em pasta compartilhada OU endpoint HTTP
```

**JSON gerado (TOTVS → Nexus):**
```json
[
  {
    "filial_cnpj": "84943067001636",
    "numero_nf": "001234",
    "especie": "NF",
    "serie": "001",
    "numero": "001234",
    "parcela": "a1",
    "valor_bruto": 390.00,
    "data_emissao": "2026-04-01",
    "data_vencimento": "2026-05-28",
    "cliente_codigo": "GETNET",
    "cliente_nome": "GETNET DO BRASIL"
  }
]
```

**Tamanho estimado:** ~100-150 linhas Progress ABL

---

### Programa 2 — Baixa de títulos (Nexus → TOTVS)

**Quando roda:** Sob demanda (supervisor exporta do Nexus)

**Lógica:**
```
LÊ JSON recebido do Nexus
FOR EACH registro:
  FIND título por filial_cnpj + especie + serie + numero + parcela
  IF FOUND:
    EXECUTA baixa padrão Datasul ACR
    GRAVA nsu_getnet no campo genérico do movimento
    GRAVA nexus_vinculo_id no campo genérico do movimento
    status = 'baixado'
  ELSE:
    status = 'erro'
    erro_descricao = 'Título não encontrado'
GERA JSON resultado
SALVA em pasta compartilhada OU retorna via endpoint
```

**JSON recebido (Nexus → TOTVS):**
```json
[
  {
    "nexus_vinculo_id": "uuid-aqui",
    "nsu": "000001419",
    "filial_cnpj": "84943067001636",
    "especie": "NF",
    "serie": "001",
    "numero": "001234",
    "parcela": "a1",
    "valor_liquido_parcela": 390.00,
    "data_vencimento": "2026-05-28"
  }
]
```

**JSON retornado (TOTVS → Nexus):**
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

**Tamanho estimado:** ~200-250 linhas Progress ABL

---

## Campos no Movimento ACR

**Nenhuma tabela nova necessária.**

Usar campos genéricos existentes no movimento de baixa ACR:
- Campo char disponível 1 → `nsu_getnet`
- Campo char disponível 2 → `nexus_vinculo_id`

Objetivo: rastreabilidade dentro do próprio TOTVS.
Auditor abre título e vê qual NSU gerou a baixa.

---

## Casos Especiais

### AN (Adiantamento)
- Espécie diferente de NF
- Supervisor autoriza operador a lançar como AN
- OU supervisor faz o match diretamente
- TOTVS compensa AN com NF futura automaticamente
- Nexus não precisa acompanhar essa conversão

### Baixa Parcial
- TOTVS aceita baixa parcial nativamente
- Supervisor fica ciente via status `baixado_parcial`
- Dashboard exibe valor baixado vs valor total

### Erro na Baixa
- Nexus registra erro_descricao
- Supervisor analisa motivo
- Reprocessamento manual (supervisor clica em reprocessar)
- Nexus reexporta JSON para TOTVS

---

## Comunicação Nexus ↔ TOTVS

**Opção A (mais simples):** Pasta compartilhada
```
Nexus escreve JSON em: /shared/nexus/para-totvs/
Progress lê de: /shared/nexus/para-totvs/
Progress escreve resultado em: /shared/nexus/de-totvs/
Nexus lê resultado de: /shared/nexus/de-totvs/
```

**Opção B (mais robusto):** Endpoint HTTP via PASOE
```
Nexus POST → https://totvs-server/api/nexus/baixa
Progress processa e retorna JSON resultado
```

**Recomendação:** Começar com Opção A (mais simples de implementar),
migrar para Opção B quando estiver estável.

---

## Estimativa de Desenvolvimento Progress

| Programa | Linhas ABL | Horas estimadas |
|----------|------------|-----------------|
| Export títulos | ~150 | 4-8h |
| Baixa títulos | ~250 | 8-16h |
| **Total** | **~400** | **1-2 dias** |

Custo estimado para contratar Progress developer: R$ 1.500-3.000
