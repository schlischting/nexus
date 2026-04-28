# Skill: Nexus UX

**Versão:** 1.0  
**Data:** 2026-04-25  
**Escopo:** Dashboards, fluxos, padrões visuais, micro-interações

---

## Paleta de Cores

### Status Padrão
```
🔴 Crítico / Alerta      #DC3545 (red-600)
🟡 Aviso / Pendente      #FFC107 (amber-500)
✅ Sucesso / Confirmado  #28A745 (green-600)
ℹ️ Info / Informação     #17A2B8 (cyan-600)
⚫ Neutro / Secundário   #6C757D (gray-600)
```

### Grades
```
Verde (Confirmado/Pago)      #10B981  rgb(16, 185, 129)
Amarelo (Pendente/Aviso)     #F59E0B  rgb(245, 158, 11)
Vermelho (Erro/Crítico)      #EF4444  rgb(239, 68, 68)
Azul (Info/Detalhes)         #3B82F6  rgb(59, 130, 246)
Cinza (Inativo/Desabilitado) #9CA3AF  rgb(156, 163, 175)
```

### Variações
```
-- Light Theme (default)
Background:     #FFFFFF
Surface:        #F9FAFB
Text Primary:   #1F2937 (gray-900)
Text Secondary: #6B7280 (gray-600)
Border:         #E5E7EB (gray-200)

-- Dark Theme (opcional)
Background:     #111827 (gray-900)
Surface:        #1F2937 (gray-800)
Text Primary:   #F3F4F6 (gray-100)
Border:         #374151 (gray-700)
```

---

## Dashboard Operador (por Filial)

### Layout Principal
```
┌─────────────────────────────────────────┐
│  NEXUS — Operador                       │
│  Filial: [Dropdown: 001 / 002 / ...]    │ ← Selecionar filial
│  [🔔 Notificações] [👤 Perfil] [🚪 Sair]│
├─────────────────────────────────────────┤
│                                          │
│  📊 RESUMO DO DIA                       │
│  ┌──────────┬──────────┬──────────┐     │
│  │ 🔴 NSU s/│ 🟡 NF s/ │ ✅ Concil│
│  │  Título  │   NSU    │  iados   │     │
│  │    12    │    8     │    45    │     │
│  └──────────┴──────────┴──────────┘     │
│                                          │
│  💰 VALOR EM GAP: R$ 4.500,00           │
│                                          │
│  ┌─────────────────────────────────────┐ │
│  │ 🔴 NSU SEM TÍTULO              [>] │ │
│  │    Lançamentos ainda não vinculados  │ │
│  │    [+ LANÇAR NOVO]                  │ │
│  ├─────────────────────────────────────┤ │
│  │ NSU      Data        Valor     Ação │ │
│  │ 000002771 26/03/2026 R$1.500  [...]│ │
│  │ 000002772 26/03/2026 R$2.800  [...]│ │
│  │ 000002773 25/03/2026 R$  240  [...]│ │
│  │                     [Carregar mais] │ │
│  └─────────────────────────────────────┘ │
│                                          │
│  ┌─────────────────────────────────────┐ │
│  │ 🟡 TÍTULOS SEM NSU                 │ │
│  │    Notas fiscais em aberto          │ │
│  ├─────────────────────────────────────┤ │
│  │ NF       Data Venc.  Valor    Ação  │ │
│  │ NF-001234 28/05/2026 R$1.500  [...]│ │
│  │ NF-001235 30/05/2026 R$3.200  [...]│ │
│  │                     [Carregar mais] │ │
│  └─────────────────────────────────────┘ │
│                                          │
│  ✅ ÚLTIMAS RECONCILIAÇÕES               │
│    [Hoje] [Esta semana] [Este mês]      │
│    • NSU 000002600 → NF-001100 (14h20)  │
│    • NSU 000002601 → NF-001101 (13h45)  │
│                                          │
└─────────────────────────────────────────┘
```

### Componentes
- **Header:** Branding NEXUS + seletor filial + notificação badge + menu
- **Cards de Resumo:** Números grandes (36pt bold) + ícone + descrição
- **Valor em Gap:** Destaque visual com cor vermelha
- **Tabelas:** Scrolláveis (mobile), paginadas (25 linhas)
- **Ações Rápidas:** Botões no final de cada linha (⋮ menu ou ícone de ação)

### Interações
```dart
-- Atualizar em tempo real (Realtime subscription)
quando: novo NSU adicionado → animar entrada, incrementar contador

-- Abrir painel de detalhes (modal bottom sheet)
ao clicar em NSU → mostrar: data, valor, bandeira, NSU, Auth

-- Lançar novo (navegação)
botão "+ LANÇAR NOVO" → ir para tela de lançamento manual
```

---

## Dashboard Supervisor (Consolidado - Todas Filiais)

### Layout Principal
```
┌──────────────────────────────────────────┐
│  NEXUS — Supervisor                      │
│  Período: [Últimos 7 dias ▼]             │
│  [Exportar TOTVS] [⋯ Mais]               │
├──────────────────────────────────────────┤
│                                           │
│  🎯 STATUS GERAL                         │
│  ┌────────┬────────┬────────┬────────┐   │
│  │ ✅ Match│ 🟡 Suge│ 🔴 Gaps│ ⚠️ Erro│   │
│  │ Automá │ stões  │  s/sol │ Baixa │   │
│  │  234   │  23    │  15    │  3    │   │
│  └────────┴────────┴────────┴────────┘   │
│                                           │
│  💰 VALOR EM RECONCILIAÇÃO: R$ 156.800   │
│  💰 VALOR EM GAPS:          R$ 34.500    │
│                                           │
│  ┌─ ✅ MATCHES AUTOMÁTICOS (>0.95)  [>]─┐│
│  │ 234 prontos para confirmação           ││
│  │ [CONFIRMAR TODOS EM LOTE]              ││
│  └──────────────────────────────────────┘│
│                                           │
│  ┌─ 🟡 SUGESTÕES (0.75-0.95)          [>]─┐
│  │ 23 aguardando validação                ││
│  │ [VER PRÓXIMA] [VER TODAS]              ││
│  └──────────────────────────────────────┘│
│                                           │
│  ┌─ 🔴 GAPS POR FILIAL                [>]─┐
│  │ Filial    NSU/NF   Valor          Ação ││
│  │ 001       3 / 2    R$ 4.500       [..] ││
│  │ 002       0 / 1    R$ 1.200       [..] ││
│  │ 003       5 / 0    R$ 8.900       [..] ││
│  │ 004       1 / 0    R$ 450         [..] ││
│  │ 005       0 / 0    R$ 0           [..] ││
│  │ ...                                     ││
│  └──────────────────────────────────────┘│
│                                           │
│  ┌─ ⚠️ ERROS DE BAIXA TOTVS            [>]─┐
│  │ NSU      Erro              Tentativas ││
│  │ 000001   E001_TITULO_NAO_ENCONTRADO  1 ││
│  │ 000002   E002_SALDO_INSUFICIENTE    2 ││
│  │ 000003   Connection timeout         1 ││
│  │ [REPROCESSAR TODOS]                   ││
│  └──────────────────────────────────────┘│
│                                           │
│  📈 RELATÓRIO (Este mês)                 │
│  │ Total Processado │ Sucesso │ Taxa    │
│  │ 12.450 títulos   │ 11.890  │ 95.5%  │
│                                           │
└──────────────────────────────────────────┘
```

### Componentes Especiais
- **Métricas de Topo:** 4 cards com contador grande + cor temática
- **Valor em Reconciliação:** Destaque verde (sucesso)
- **Valor em Gaps:** Destaque vermelho (alerta)
- **Seções Colapsáveis:** Expandir/recolher com altura variável
- **Tabela de Gaps:** Sortável por filial, valor; clicável para detalhes
- **Ações em Massa:** "Confirmar Todos", "Reprocessar Todos"

### Interações
```dart
-- Confirmar todos matches automaticamente
ao clicar "CONFIRMAR TODOS" → 
  mostrar confirmação (count) → 
  atualizar status para 'confirmado' →
  mostrar toast de sucesso →
  recarregar dashboard

-- Ver próxima sugestão (modal)
ao clicar "VER PRÓXIMA" →
  abrir modal com sugestão em grande (comparison view) →
  botões: [NÃO É] [SIM, CONFIRMAR] →
  ao confirmar, atualizar e carregar próxima

-- Analisar por filial
ao clicar filial em gaps → ir para dashboard operador dessa filial
```

---

## Fluxo de Lançamento NSU + NF (Operador)

### Tela 1: Selecionar NSU

```
┌──────────────────────────────────┐
│ LANÇAR NOVO VÍNCULO             │
│ Passo 1 de 3: NSU               │
├──────────────────────────────────┤
│                                  │
│ Qual é o NSU do comprovante?    │
│                                  │
│ [__________000002771__________] │
│  ↑ Digite ou cole do papel       │
│                                  │
│ [CANCELAR] [VERIFICAR] →         │
│                                  │
│ ℹ️ NSUs sem título neste momento:│
│    000002700, 000002701,        │
│    000002702, 000002703, ...    │
│                                  │
└──────────────────────────────────┘
```

**Lógica:**
- Input: máscara opcional (apenas números)
- Botão "VERIFICAR": buscar NSU na DB
  - ✅ Se existe → ir para Passo 2
  - ❌ Se não existe → mostrar erro em vermelho + sugerir NSUs parecidos

### Tela 2: Selecionar NF

```
┌──────────────────────────────────┐
│ LANÇAR NOVO VÍNCULO             │
│ Passo 2 de 3: Nota Fiscal       │
├──────────────────────────────────┤
│                                  │
│ NSU verificado: 000002771        │
│ Valor: R$ 1.500,00              │
│ Data: 26/03/2026                │
│                                  │
│ Qual é a Nota Fiscal ou AN?    │
│                                  │
│ ○ Informar número NF/AN          │
│   [__________NF-001234_______]   │
│                                  │
│ ○ Buscar nos títulos da filial   │
│   [MOSTRAR LISTA ▼]              │
│   ┌──────────────────────────┐   │
│   │ NF-001230 R$1.500 28/05  │   │
│   │ NF-001231 R$2.100 01/06  │   │
│   │ NF-001232 R$3.000 05/06  │   │
│   │ NF-001233 R$  150 10/06  │   │
│   └──────────────────────────┘   │
│                                  │
│ [VOLTAR] [PRÓXIMO] →             │
│                                  │
└──────────────────────────────────┘
```

**Lógica:**
- 2 opções: digitar manual ou listar (busca em TOTVS)
- Se digitar: validar formato (NF-XXXXX ou AN-XXXXX)
- Se listar: carregar títulos abertos, clicável para selecionar
- Ao selecionar, comparar valor (alerta se diferença > tolerância)

### Tela 3: Resumo & Confirmar

```
┌──────────────────────────────────┐
│ LANÇAR NOVO VÍNCULO             │
│ Passo 3 de 3: Confirmação       │
├──────────────────────────────────┤
│                                  │
│ 📋 RESUMO DO VÍNCULO            │
│                                  │
│ NSU GETNET:                      │
│  000002771                       │
│  Valor: R$ 1.500,00             │
│  Data: 26/03/2026 11:07:56      │
│  Bandeira: Visa Crédito          │
│                                  │
│ NOTA FISCAL:                     │
│  NF-001234                       │
│  Valor: R$ 1.515,00             │
│  Vencimento: 28/05/2026          │
│                                  │
│ 🟢 CONFERÊNCIA OK (Match automático)│
│   Valores e datas coincidem      │
│   Score: 95%                     │
│                                  │
│ Modalidade: ⚫ Crédito ⚪ Débito  │
│ Parcelas: [1 ▼]                  │
│                                  │
│ Observações (opcional):          │
│ [____________________________]    │
│ [____________________________]    │
│                                  │
│ [VOLTAR] [CONFIRMAR E SALVAR]    │
│                                  │
└──────────────────────────────────┘
```

**Lógica:**
- Mostrar resumo lado a lado (GETNET vs TOTVS)
- Indicador visual: ✅ se conferência OK, ⚠️ se há diferenças
- Score de confiança em grande
- Ao confirmar: salvar no DB, mostrar toast, voltar ao dashboard

---

## Fluxo de Validação Supervisor

### Modal: Comparação de Sugestão

```
┌────────────────────────────────────┐
│ VALIDAR SUGESTÃO                  │ ← Título
│ [Sugestão 1 de 23]                │
│ ────────────────────────────────── │
│                                    │
│ Score: 87%  ████████░░ Provável   │ ← Barra visual
│                                    │
│ GETNET          TOTVS             │
│ ─────────────── ─────────────────  │
│ NSU 000002771   NF-001234         │
│ R$ 1.500,00     R$ 1.515,00       │ ← Destacar diferença
│ 26/03/2026      Venc. 28/05       │
│ 2 dias antes ←━━━━━━━→            │
│                                    │
│ Diferenças:                       │
│ • Valor: R$ 15,00 (1%)           │
│ • Data: 2 dias                    │
│                                    │
│ ────────────────────────────────── │
│ [❌ NÃO]  [✅ SIM, CONFIRMAR]    │
│                                    │
└────────────────────────────────────┘
```

**Componentes:**
- Barra de score: visual (width = score%)
- Comparação lado a lado: visual prominent
- Diferenças listadas em bullets
- Botões grandes: fácil de tocar/clicar

### Interação
```
ao clicar "SIM, CONFIRMAR":
  → Atualizar status para 'confirmado'
  → Chamar função Edge para exportar JSON
  → Mostrar toast "✅ Vínculo confirmado"
  → Carregar próxima sugestão (animação)

ao clicar "NÃO":
  → Atualizar status para 'rejeitado'
  → Mostrar campo observação (opcional)
  → Mostrar toast "Sugestão rejeitada"
  → Carregar próxima sugestão
```

---

## Padrões Visuais de Status

### Badges (In-line)

```
Status Vínculo:
┌────────────────┐
│ 🟡 Pendente    │ ← Orange, ícone clock
└────────────────┘

┌────────────────┐
│ ✅ Confirmado  │ ← Green, ícone check_circle
└────────────────┘

┌────────────────┐
│ ⚠️ Erro Baixa  │ ← Red, ícone error
└────────────────┘

┌────────────────┐
│ 🚫 Rejeitado   │ ← Gray, ícone close
└────────────────┘
```

### Ícones por Tipo de Título
```
NF (Nota Fiscal)            📄
AN (Aviso Nota)             ⚠️
Título com NSU              ✅
Título sem NSU              ❌
NSU com score alto (>0.95)  🎯
NSU com score médio         ⚡
NSU com score baixo (<0.75) ❓
Erro de sistema             🔥
```

### Micro-animações
```
-- Quando NSU novo aparece (realtime)
entrada: slide_in_from_top (100ms) + fade_in
cor de fundo destaca-se por 2 segundos

-- Quando confirmar sugestão
transição: fade_out (100ms) + slide_out_to_right (200ms)
próxima sugestão entra: slide_in_from_left (200ms)

-- Quando carregar dados
loading: shimmer skeleton por 500-2000ms

-- Notificação de sucesso
toast: slide_in_from_bottom (300ms), permanecer 3s, slide_out (300ms)
```

---

## Tipografia

### Hierarquia
```
Headlines (títulos de página/seções)
  font: Roboto Bold / Inter Bold
  size: 28-32pt
  color: gray-900
  line-height: 1.3

Subtitles (subseções, labels grandes)
  font: Roboto Medium / Inter SemiBold
  size: 18-20pt
  color: gray-700
  line-height: 1.4

Body (texto corrido, descrições)
  font: Roboto Regular / Inter Regular
  size: 14-16pt
  color: gray-600
  line-height: 1.6

Labels (labels de campos, tabelas)
  font: Roboto Regular / Inter Medium
  size: 12-14pt
  color: gray-600
  text-transform: uppercase
  letter-spacing: 0.5px

Numbers (valores monetários, contadores)
  font: Roboto Mono
  size: 18-36pt
  color: (depends on context)
  font-weight: bold
```

### Exemplos
```
Título Principal:
"DASHBOARD — Filial 001" (28pt, Bold, gray-900)

Label de Campo:
"NSU (DO COMPROVANTE):" (12pt, Regular, UPPERCASE, gray-600)

Valor em Destaque:
"R$ 4.500,00" (36pt, Bold, Mono, red-600)

Descrição:
"Lançamentos ainda não vinculados a uma Nota Fiscal" (14pt, Regular, gray-600)
```

---

## Responsividade

### Breakpoints
```
Mobile      < 600px   (phones: 360-480px)
Tablet      600-1024px
Desktop     ≥ 1025px
```

### Ajustes por Breakpoint
```
Mobile (<600px):
  • Layout em coluna única
  • Cards empilhados
  • Tabelas: horizontal scroll ou stack (nome + valor em cada linha)
  • Botões: 100% width, stacked

Tablet (600-1024px):
  • Grid 2 colunas
  • Tabelas: scrolláveis horizontalmente
  • Botões: lado a lado se houver espaço

Desktop (≥1025px):
  • Grid 3-4 colunas
  • Tabelas: full width, sem scroll
  • Botões: lado a lado
```

### Exemplo: Card de Resumo
```
Mobile:
┌──────────────────┐
│ 🔴 NSU s/título  │
│      12          │
└──────────────────┘
┌──────────────────┐
│ 🟡 Títulos s/NSU │
│       8          │
└──────────────────┘

Tablet/Desktop:
┌──────────────┬──────────────┬──────────────┐
│ 🔴 NSU s/tít │ 🟡 Títulos s/│ ✅ Concili   │
│     12       │      8       │     45       │
└──────────────┴──────────────┴──────────────┘
```

---

## Acessibilidade

### Contraste
- Mínimo WCAG AA: 4.5:1 para texto normal, 3:1 para grande
- Texto em vermelho deve incluir ícone ou padrão (não apenas cor)

### Navegação
- Tab order: lógico (top→bottom, left→right)
- Focus visible: outline 2px, color #3B82F6
- Links: underline + color (não apenas cor)

### Semântica
- Labels associados a inputs (htmlFor)
- ARIA labels para ícones sem texto
- Heading hierarchy: h1 > h2 > h3 (não pular níveis)
- Lists: usar <ul>/<ol>, não divs

### Exemplo
```dart
Widget build(BuildContext context) {
  return Semantics(
    label: "NSU sem título, 12 pendentes",
    child: Card(
      child: Column(
        children: [
          Semantics(
            heading: true,
            child: Text("🔴 NSU SEM TÍTULO")
          ),
          Text("12", semanticsLabel: "Quantidade: doze")
        ]
      )
    )
  );
}
```

---

## Checklist UX

- [ ] Paleta de cores definida e consistente
- [ ] Dashboard operador com 3 alertas (🔴🟡✅)
- [ ] Dashboard supervisor com 5 seções
- [ ] Fluxo de lançamento em 3 passos claro
- [ ] Modal de validação com comparação visual
- [ ] Micro-animações suaves (100-300ms)
- [ ] Responsividade mobile/tablet/desktop testada
- [ ] Tipografia hierárquica clara
- [ ] Acessibilidade WCAG AA verificada
- [ ] Notificações em tempo real visíveis
- [ ] Loading states em todas queries
- [ ] Error states com mensagens claras
- [ ] Confirmações para ações críticas
- [ ] Toast/snackbar para feedback
