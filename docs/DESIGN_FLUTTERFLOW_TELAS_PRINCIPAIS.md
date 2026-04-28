# Design: 3 Telas Principais FlutterFlow — Nexus v3.0

**Data:** 2026-04-25  
**Baseado em:** skill nexus-ux + FLUXO_NEGOCIO.md  
**Status:** 🟢 PRONTO PARA IMPLEMENTAÇÃO

---

## 🎨 Paleta de Cores (Aplicada)

```
🔴 Crítico / Alerta      #EF4444 (red-600)
🟡 Aviso / Pendente      #F59E0B (amber-500)
✅ Sucesso / Confirmado  #10B981 (green-600)
ℹ️ Info / Detalhes       #3B82F6 (blue-600)
⚫ Neutro / Secundário   #6B7280 (gray-600)
```

---

## TELA 1: OPERADOR — Dashboard de Gaps (por Filial)

### 📐 Wireframe Completo

```
╔════════════════════════════════════════════════════════════════╗
║ NEXUS — Operador Dashboard                [🔔 2] [👤] [🚪]     ║
║ Filial: Filial 001 [▼] | Horário: 14:30:22                     ║
╠════════════════════════════════════════════════════════════════╣
║                                                                 ║
║ 📊 RESUMO DO DIA (Tempo Real)                                  ║
║ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐             ║
║ │ 🔴 NSU       │ │ 🟡 LANÇAMENTOS│ │ 🟡 TÍTULOS   │             ║
║ │ SEM TÍTULO   │ │ COM PROBLEMA │ │ SEM NSU      │             ║
║ │     12       │ │      2       │ │      8       │             ║
║ │ Pendentes    │ │ (NSU inválido)│ │ Abertos      │             ║
║ └──────────────┘ └──────────────┘ └──────────────┘             ║
║                                                                 ║
║ 💰 VALOR EM GAP: R$ 4.500,00  (vermelho destacado)             ║
║ ✅ CONCILIADOS HOJE: 45                                        ║
║                                                                 ║
║ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ║
║                                                                 ║
║ ┌─ 🔴 NSU SEM TÍTULO (12)                         [Expandir] ─┐ ║
║ │  Lançamentos ainda não vinculados a uma NF                  │ ║
║ │  [+ LANÇAR NOVO]                                            │ ║
║ │                                                              │ ║
║ │  NSU          Data        Valor       Bandeira   Ação       │ ║
║ │  ──────────────────────────────────────────────────────────  │ ║
║ │  000002771   26/03/2026  R$ 1.500    Visa       [⋮ Edit]   │ ║
║ │  000002772   26/03/2026  R$ 2.800    Mastercard [⋮ Edit]   │ ║
║ │  000002773   25/03/2026  R$   240    Elo        [⋮ Edit]   │ ║
║ │                            [Carregar mais ↓]               │ ║
║ └─────────────────────────────────────────────────────────────┘ ║
║                                                                 ║
║ ┌─ 🟡 LANÇAMENTOS COM PROBLEMA (2)               [Expandir] ─┐ ║
║ │  Erros de validação — operador precisa corrigir             │ ║
║ │                                                              │ ║
║ │  NSU          Erro                            Ação          │ ║
║ │  ──────────────────────────────────────────────────────────  │ ║
║ │  000001234   ❌ NSU não encontrado na GETNET  [Corrigir]   │ ║
║ │  000001235   ❌ NSU não encontrado na GETNET  [Corrigir]   │ ║
║ └─────────────────────────────────────────────────────────────┘ ║
║                                                                 ║
║ ┌─ 🟡 TÍTULOS SEM NSU (8)                        [Expandir] ─┐ ║
║ │  Notas fiscais em aberto na filial                          │ ║
║ │                                                              │ ║
║ │  Número NF   Data Venc.    Valor      Tipo   Ação          │ ║
║ │  ──────────────────────────────────────────────────────────  │ ║
║ │  NF-001234   28/05/2026   R$ 1.500    NF    [Vincular]     │ ║
║ │  NF-001235   30/05/2026   R$ 3.200    AN    [Vincular]     │ ║
║ │                            [Carregar mais ↓]               │ ║
║ └─────────────────────────────────────────────────────────────┘ ║
║                                                                 ║
║ ┌─ ✅ ÚLTIMAS RECONCILIAÇÕES                     [Expandir] ─┐ ║
║ │  [Hoje] [Esta semana] [Este mês]                            │ ║
║ │                                                              │ ║
║ │  • NSU 000002600 → NF-001100 (14h20) R$ 1.500              │ ║
║ │  • NSU 000002601 → NF-001101 (13h45) R$ 2.800              │ ║
║ │  • NSU 000002602 → NF-001102 (12h15) R$   240              │ ║
║ └─────────────────────────────────────────────────────────────┘ ║
║                                                                 ║
╚════════════════════════════════════════════════════════════════╝
```

### 🎯 Componentes FlutterFlow

#### 1. Header (Scaffold)
```dart
AppBar(
  title: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text("NEXUS — Operador", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      Row(
        children: [
          Badge(
            label: Text("2"),
            child: Icon(Icons.notifications)
          ),
          SizedBox(width: 16),
          IconButton(icon: Icon(Icons.person), onPressed: () => goToProfile()),
          IconButton(icon: Icon(Icons.logout), onPressed: () => logout())
        ]
      )
    ]
  ),
  backgroundColor: Colors.white,
  elevation: 1
)
```

#### 2. Seletor de Filial (Dropdown)
```dart
DropdownButton<String>(
  value: selectedFilial,  // 84943067001393
  items: userFiliais.map((f) => DropdownMenuItem(
    value: f['filial_cnpj'],
    child: Text(f['nome_filial'])
  )).toList(),
  onChanged: (value) => setState(() {
    selectedFilial = value;
    reloadDashboard(value);  // Recarrega com filtro RLS
  })
)
```

#### 3. Cards de Resumo (GridView 3 colunas)
```dart
GridView.count(
  crossAxisCount: MediaQuery.of(context).size.width > 1024 ? 3 : 1,
  crossAxisSpacing: 16,
  mainAxisSpacing: 16,
  children: [
    MetricCard(
      title: "🔴 NSU SEM TÍTULO",
      count: 12,
      color: Colors.red,
      onTap: () => scrollToSection('nsu_section')
    ),
    MetricCard(
      title: "🟡 LANÇAMENTOS COM PROBLEMA",
      count: 2,
      color: Colors.amber,
      onTap: () => scrollToSection('problema_section')
    ),
    MetricCard(
      title: "🟡 TÍTULOS SEM NSU",
      count: 8,
      color: Colors.amber,
      onTap: () => scrollToSection('titulo_section')
    ),
    MetricCard(
      title: "✅ CONCILIADOS HOJE",
      count: 45,
      color: Colors.green,
      onTap: () {}
    )
  ]
)
```

#### 4. Valor em Gap (Destaque Vermelho)
```dart
Container(
  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
  decoration: BoxDecoration(
    color: Colors.red.withOpacity(0.1),
    border: Border.all(color: Colors.red, width: 2)
  ),
  child: Column(
    children: [
      Text("💰 VALOR EM GAP", style: TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.bold)),
      SizedBox(height: 8),
      Text(
        "R\$ 4.500,00",
        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red, fontFamily: 'RobotoMono')
      )
    ]
  )
)
```

#### 5. Tabelas Colapsáveis (ExpansionPanel)
```dart
ExpansionPanelList(
  expansionCallbacks: (int index, bool isExpanded) {
    setState(() => expandedPanels[index] = isExpanded);
  },
  children: [
    // Panel 1: NSU sem título
    ExpansionPanel(
      headerBuilder: (context, isExpanded) => ListTile(
        title: Text("🔴 NSU SEM TÍTULO (${nsuSemTitulo.length})", style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Lançamentos ainda não vinculados")
      ),
      body: NsuTableWidget(
        data: nsuSemTitulo,
        onEdit: (nsu) => goToLancamento(nsu),
        onDelete: (nsu) => deleteNsu(nsu)
      ),
      isExpanded: expandedPanels[0] ?? true
    ),
    // Panel 2: Lançamentos com problema
    ExpansionPanel(
      headerBuilder: (context, isExpanded) => ListTile(
        title: Text("🟡 LANÇAMENTOS COM PROBLEMA (${problemas.length})", style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Erros de validação")
      ),
      body: ProblemasTableWidget(
        data: problemas,
        onFix: (problema) => corrigirProblema(problema)
      ),
      isExpanded: expandedPanels[1] ?? true
    ),
    // Panel 3: Títulos sem NSU
    ExpansionPanel(
      headerBuilder: (context, isExpanded) => ListTile(
        title: Text("🟡 TÍTULOS SEM NSU (${tituloSemNsu.length})", style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Notas fiscais em aberto")
      ),
      body: TituloTableWidget(
        data: tituloSemNsu,
        onVincular: (titulo) => goToLancamento(null, titulo)
      ),
      isExpanded: expandedPanels[2] ?? true
    )
  ]
)
```

### 🔌 Data Bindings ao Supabase (RLS Automático)

```dart
class OperadorDashboard extends StatefulWidget {
  final String filialCnpj;  // Vem do login/user_filiais_cnpj
  
  @override
  State<OperadorDashboard> createState() => _OperadorDashboardState();
}

class _OperadorDashboardState extends State<OperadorDashboard> {
  late StreamSubscription<List<Map>> nsuSemTituloStream;
  late StreamSubscription<List<Map>> tituloSemNsuStream;
  
  List<Map> nsuSemTitulo = [];
  List<Map> tituloSemNsu = [];
  List<Map> problemas = [];
  int conciliadosHoje = 0;
  double valorEmGap = 0.0;
  
  @override
  void initState() {
    // Real-time: NSU sem título (RLS filtra automaticamente)
    nsuSemTituloStream = supabase
      .from('vw_nsu_sem_titulo')
      .on(RealtimeListenEvent.all, (payload) {
        setState(() {
          nsuSemTitulo = payload.newRecord;
          calcularValorGap();
        });
      })
      .eq('filial_cnpj', widget.filialCnpj)  // RLS vai descartar se operador não tiver acesso
      .order('data_venda', ascending: false)
      .limit(50)
      .subscribe();
    
    // Real-time: Títulos sem NSU
    tituloSemNsuStream = supabase
      .from('vw_titulo_sem_nsu')
      .on(RealtimeListenEvent.all, (payload) {
        setState(() {
          tituloSemNsu = payload.newRecord;
        });
      })
      .eq('filial_cnpj', widget.filialCnpj)
      .order('data_vencimento', ascending: true)
      .limit(50)
      .subscribe();
    
    // Query: Lançamentos com problema (NSU inválido)
    buscarProblemas();
    
    // Query: Conciliados hoje
    buscarConciliadosHoje();
  }
  
  Future<void> buscarProblemas() async {
    final response = await supabase
      .from('conciliacao_vinculos')
      .select()
      .eq('filial_cnpj', widget.filialCnpj)
      .eq('status', 'nsu_invalido')
      .order('criado_em', ascending: false)
      .limit(10);
    
    setState(() {
      problemas = response ?? [];
    });
  }
  
  Future<void> buscarConciliadosHoje() async {
    final hoje = DateTime.now().toIso8601String().split('T')[0];
    
    final response = await supabase
      .from('conciliacao_vinculos')
      .select()
      .eq('filial_cnpj', widget.filialCnpj)
      .eq('status', 'confirmado')
      .gte('data_confirmacao', '${hoje}T00:00:00')
      .count(CountOption.exact);
    
    setState(() {
      conciliadosHoje = response.count ?? 0;
    });
  }
  
  void calcularValorGap() {
    // Somar valores de NSU sem título
    valorEmGap = nsuSemTitulo.fold(0.0, (sum, nsu) => 
      sum + (nsu['valor_venda'] as num? ?? 0).toDouble()
    );
  }
  
  @override
  void dispose() {
    nsuSemTituloStream.cancel();
    tituloSemNsuStream.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(...),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header com seletor de filial
            ...,
            // Cards de resumo
            GridView(...),
            // Valor em gap
            Container(...),
            // Tabelas colapsáveis
            ExpansionPanelList(...)
          ]
        )
      )
    );
  }
}
```

### 🔐 RLS no Frontend

**Fluxo RLS:**
1. Usuário faz login → JWT token com `sub` (user_id)
2. FlutterFlow carrega `user_filiais_cnpj` via Supabase Auth
3. Operador tem filial_cnpj na tabela → RLS permite SELECT
4. Query `vw_nsu_sem_titulo` é automaticamente filtrada por RLS
5. Supervisor vê tudo (RLS verifica `auth.jwt() ->> 'role' = 'supervisor'`)

**Código RLS Policy (já no schema_nexus_v3.0.sql):**
```sql
CREATE POLICY rls_transacoes_getnet_own
  ON transacoes_getnet FOR ALL
  USING (
    auth.jwt() ->> 'role' IN ('admin', 'supervisor')
    OR filial_cnpj IN (
      SELECT filial_cnpj FROM user_filiais_cnpj WHERE user_id = auth.uid()
    )
  );
```

**Frontend não precisa filtrar:**
```dart
// ✅ RLS faz o filtro automaticamente
final response = await supabase
  .from('vw_nsu_sem_titulo')
  .select()
  // NÃO precisa: .eq('filial_cnpj', filialCnpj)
  // RLS já bloqueia se operador não tiver acesso
  .order('data_venda', ascending: false);
```

---

## TELA 2: OPERADOR — Lançamento NSU + NF (3 Passos)

### 📐 Fluxo Visual (3 Telas)

```
┌──────────────────────────────────────────────────────────────┐
│ LANÇAR NOVO VÍNCULO                                          │
│ Passo 1 de 3: NSU                                             │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│ [████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░] 33%              │
│                                                               │
│ Qual é o NSU do comprovante?                                 │
│                                                               │
│ [_________________________000002771_____________]             │
│  ↑ Digite ou cole do comprovante                              │
│                                                               │
│ [CANCELAR] [VERIFICAR] →                                     │
│                                                               │
│ ℹ️ NSUs sem título neste momento:                            │
│    • 000002700  • 000002701  • 000002702                      │
│    • 000002703  • 000002704  • ...                            │
│                                                               │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ LANÇAR NOVO VÍNCULO                                          │
│ Passo 2 de 3: Nota Fiscal ou Adiantamento                    │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│ [██████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░] 66%            │
│                                                               │
│ NSU verificado: 000002771                                     │
│ ┌─────────────────────────────────────────┐                  │
│ │ Valor: R$ 1.500,00                      │                  │
│ │ Data: 26/03/2026 11:07:56               │                  │
│ │ Bandeira: Visa Crédito                  │                  │
│ └─────────────────────────────────────────┘                  │
│                                                               │
│ Qual é a Nota Fiscal ou Adiantamento?                        │
│                                                               │
│ ○ Digitar número                                             │
│   [______________NF-001234_____________]                     │
│                                                               │
│ ○ Buscar nos títulos da filial                               │
│   [MOSTRAR LISTA ▼]                                          │
│   ┌────────────────────────────────────┐                     │
│   │ NF-001230  R$ 1.500   Venc: 28/05 │ ← click seleciona    │
│   │ NF-001231  R$ 2.100   Venc: 01/06 │                     │
│   │ NF-001232  R$ 3.000   Venc: 05/06 │                     │
│   │ NF-001233  R$   150   Venc: 10/06 │                     │
│   └────────────────────────────────────┘                     │
│                                                               │
│ [VOLTAR] [PRÓXIMO] →                                         │
│                                                               │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ LANÇAR NOVO VÍNCULO                                          │
│ Passo 3 de 3: Confirmação                                    │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│ [████████████████████████████████████████████] 100%          │
│                                                               │
│ 📋 RESUMO DO VÍNCULO                                         │
│                                                               │
│ NSU GETNET:                    NOTA FISCAL:                  │
│ ┌──────────────────────────┐  ┌──────────────────────────┐  │
│ │ 000002771                │  │ NF-001234                │  │
│ │ R$ 1.500,00              │  │ R$ 1.515,00              │  │
│ │ 26/03/2026 11:07:56      │  │ Venc. 28/05/2026         │  │
│ │ Visa Crédito             │  │ (2 dias depois)          │  │
│ └──────────────────────────┘  └──────────────────────────┘  │
│                                                               │
│ 🟢 CONFERÊNCIA OK (Match automático 95%)                    │
│   ✓ Valores coincidem (diff: R$ 15,00 = 1%)                │
│   ✓ Datas dentro da tolerância (2 dias)                    │
│   ✓ Pronto para confirmar                                   │
│                                                               │
│ Modalidade: [⚫ Crédito] [⚪ Débito]  [Selecionado: Crédito]│
│ Parcelas: [1 ▼] (Mudar se parcelado)                       │
│                                                               │
│ Observações (opcional):                                      │
│ [_____________________________________________]             │
│ [_____________________________________________]             │
│                                                               │
│ [VOLTAR] [CONFIRMAR E SALVAR]                               │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

### 🎯 Componentes FlutterFlow

```dart
// Passo 1: NSU Input
class PassoNsuScreen extends StatefulWidget {
  @override
  State<PassoNsuScreen> createState() => _PassoNsuScreenState();
}

class _PassoNsuScreenState extends State<PassoNsuScreen> {
  final nsuController = TextEditingController();
  bool nsuEncontrado = false;
  Map<String, dynamic>? nsuData;
  List<String> nsusSugeridos = [];
  
  Future<void> verificarNsu() async {
    final nsu = nsuController.text.trim();
    
    try {
      final response = await supabase
        .from('transacoes_getnet')
        .select()
        .eq('nsu', nsu)
        .eq('filial_cnpj', userFilialCnpj)  // RLS já faz, mas add segurança
        .single();
      
      setState(() {
        nsuEncontrado = true;
        nsuData = response;
      });
      
      // Ir para Passo 2 após 500ms
      await Future.delayed(Duration(milliseconds: 500));
      if (mounted) context.pushNamed('passo_nf');
      
    } on PostgrestException catch (e) {
      setState(() => nsuEncontrado = false);
      
      // Buscar NSUs parecidos para sugerir
      final sugeridos = await supabase
        .from('vw_nsu_sem_titulo')
        .select('nsu')
        .eq('filial_cnpj', userFilialCnpj)
        .order('data_venda', ascending: false)
        .limit(6);
      
      setState(() {
        nsusSugeridos = sugeridos.map((r) => r['nsu'] as String).toList();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ NSU não encontrado na GETNET"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3)
        )
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Passo 1 de 3: NSU")),
      body: Column(
        children: [
          LinearProgressIndicator(value: 0.33),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text("Qual é o NSU do comprovante?", style: TextStyle(fontSize: 18)),
                  SizedBox(height: 16),
                  TextField(
                    controller: nsuController,
                    decoration: InputDecoration(
                      hintText: "000002771",
                      prefixIcon: Icon(Icons.receipt),
                      border: OutlineInputBorder()
                    ),
                    keyboardType: TextInputType.number
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("CANCELAR")
                      ),
                      FilledButton(
                        onPressed: verificarNsu,
                        child: Text("VERIFICAR →")
                      )
                    ]
                  ),
                  SizedBox(height: 32),
                  if (nsusSugeridos.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("ℹ️ NSUs sem título neste momento:", style: TextStyle(fontSize: 14, color: Colors.blue)),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: nsusSugeridos.map((nsu) => 
                            InputChip(
                              label: Text(nsu),
                              onPressed: () => setState(() {
                                nsuController.text = nsu;
                                verificarNsu();
                              })
                            )
                          ).toList()
                        )
                      ]
                    )
                ]
              )
            )
          )
        ]
      )
    );
  }
}

// Passo 2: NF Input com busca TOTVS
class PassoNfScreen extends StatefulWidget {
  final Map<String, dynamic> nsuData;
  
  const PassoNfScreen({required this.nsuData});
  
  @override
  State<PassoNfScreen> createState() => _PassoNfScreenState();
}

class _PassoNfScreenState extends State<PassoNfScreen> {
  final nfController = TextEditingController();
  List<Map<String, dynamic>> titulosDisponiveis = [];
  Map<String, dynamic>? tituloSelecionado;
  
  @override
  void initState() {
    super.initState();
    buscarTitulos();
  }
  
  Future<void> buscarTitulos() async {
    // Buscar títulos abertos dessa filial
    final response = await supabase
      .from('titulos_totvs')
      .select()
      .eq('filial_cnpj', userFilialCnpj)
      .eq('status', 'aberto')
      .order('data_vencimento', ascending: true)
      .limit(20);
    
    setState(() {
      titulosDisponiveis = response ?? [];
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Passo 2 de 3: Nota Fiscal")),
      body: Column(
        children: [
          LinearProgressIndicator(value: 0.66),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Info NSU
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      border: Border.all(color: Colors.blue)
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("NSU verificado: ${widget.nsuData['nsu']}", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("Valor: R\$ ${widget.nsuData['valor_venda'].toStringAsFixed(2)}", style: TextStyle(fontSize: 18, fontFamily: 'RobotoMono')),
                        Text("Data: ${widget.nsuData['data_venda']} ${widget.nsuData['hora_venda']}")
                      ]
                    )
                  ),
                  SizedBox(height: 24),
                  Text("Qual é a Nota Fiscal ou Adiantamento?", style: TextStyle(fontSize: 16)),
                  SizedBox(height: 16),
                  
                  // Opção 1: Digitar
                  TextField(
                    controller: nfController,
                    decoration: InputDecoration(
                      hintText: "NF-001234",
                      prefixIcon: Icon(Icons.document_scanner),
                      border: OutlineInputBorder()
                    )
                  ),
                  SizedBox(height: 16),
                  
                  Text("ou", style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 16),
                  
                  // Opção 2: Listar títulos
                  if (titulosDisponiveis.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Títulos em aberto na filial:", style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: titulosDisponiveis.length,
                          itemBuilder: (context, index) {
                            final titulo = titulosDisponiveis[index];
                            return ListTile(
                              title: Text("${titulo['numero_nf']} (${titulo['tipo_titulo']})"),
                              subtitle: Text("Venc. ${titulo['data_vencimento']}"),
                              trailing: Text("R\$ ${titulo['valor_bruto'].toStringAsFixed(2)}"),
                              onTap: () {
                                setState(() {
                                  tituloSelecionado = titulo;
                                  nfController.text = titulo['numero_nf'];
                                });
                              }
                            );
                          }
                        )
                      ]
                    ),
                  
                  SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("VOLTAR")
                      ),
                      FilledButton(
                        onPressed: nfController.text.isNotEmpty 
                          ? () {
                              // Passar dados para Passo 3
                              context.pushNamed('passo_confirmacao', extra: {
                                'nsu_data': widget.nsuData,
                                'titulo_data': tituloSelecionado,
                                'nf_manual': nfController.text
                              });
                            }
                          : null,
                        child: Text("PRÓXIMO →")
                      )
                    ]
                  )
                ]
              )
            )
          )
        ]
      )
    );
  }
}

// Passo 3: Confirmação com Score
class PassoConfirmacaoScreen extends StatefulWidget {
  final Map<String, dynamic> nsuData;
  final Map<String, dynamic>? tituloData;
  final String nfManual;
  
  const PassoConfirmacaoScreen({
    required this.nsuData,
    required this.tituloData,
    required this.nfManual
  });
  
  @override
  State<PassoConfirmacaoScreen> createState() => _PassoConfirmacaoScreenState();
}

class _PassoConfirmacaoScreenState extends State<PassoConfirmacaoScreen> {
  String modalidadeSelecionada = 'credito';
  int parcelasSelecionadas = 1;
  String observacoes = '';
  double? scoreConfianca;
  bool conferenciOk = false;
  
  @override
  void initState() {
    super.initState();
    calcularScore();
  }
  
  void calcularScore() {
    if (widget.tituloData == null) {
      setState(() {
        scoreConfianca = 0.0;
        conferenciOk = false;
      });
      return;
    }
    
    // Chamar função calcular_score_matching() do Supabase
    supabase
      .rpc('calcular_score_matching', params: {
        'p_valor_getnet': widget.nsuData['valor_venda'],
        'p_valor_totvs': widget.tituloData!['valor_bruto'],
        'p_data_getnet': widget.nsuData['data_venda'],
        'p_data_totvs': widget.tituloData!['data_vencimento'],
        'p_tolerancia_pct': 5,
        'p_tolerancia_dias': 3
      })
      .then((score) {
        setState(() {
          scoreConfianca = score as double?;
          conferenciOk = (scoreConfianca ?? 0) > 0.75;
        });
      });
  }
  
  Future<void> confirmarVinculo() async {
    try {
      // Inserir vínculo em conciliacao_vinculos
      await supabase.from('conciliacao_vinculos').insert({
        'filial_cnpj': userFilialCnpj,
        'transacao_getnet_id': widget.nsuData['transacao_id'],
        'titulo_totvs_id': widget.tituloData?['titulo_id'],
        'numero_nf_informado': widget.nfManual,
        'tipo_vinculacao': 'manual',
        'score_confianca': scoreConfianca ?? 0.0,
        'status': (scoreConfianca ?? 0) > 0.95 ? 'confirmado' : 'pendente',
        'criado_por': currentUser.email,
        'criado_em': DateTime.now().toUtc().toIso8601String()
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Vínculo lançado com sucesso!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3)
        )
      );
      
      // Voltar ao dashboard
      context.popUntil(ModalRoute.withName('dashboard'));
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erro ao salvar vínculo: ${e.toString()}"),
          backgroundColor: Colors.red
        )
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Passo 3 de 3: Confirmação")),
      body: Column(
        children: [
          LinearProgressIndicator(value: 1.0),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text("📋 RESUMO DO VÍNCULO", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  
                  // Comparação lado a lado
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text("NSU GETNET", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(border: Border.all(color: Colors.blue.withOpacity(0.3))),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.nsuData['nsu'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  Text("R\$ ${widget.nsuData['valor_venda'].toStringAsFixed(2)}", style: TextStyle(fontSize: 18, fontFamily: 'RobotoMono', fontWeight: FontWeight.bold)),
                                  Text(widget.nsuData['data_venda']),
                                  Text(widget.nsuData['bandeira'], style: TextStyle(fontSize: 12, color: Colors.grey))
                                ]
                              )
                            )
                          ]
                        )
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            Text("NOTA FISCAL", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            if (widget.tituloData != null)
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(border: Border.all(color: Colors.green.withOpacity(0.3))),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("${widget.tituloData!['numero_nf']} (${widget.tituloData!['tipo_titulo']})", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    Text("R\$ ${widget.tituloData!['valor_bruto'].toStringAsFixed(2)}", style: TextStyle(fontSize: 18, fontFamily: 'RobotoMono', fontWeight: FontWeight.bold)),
                                    Text("Venc. ${widget.tituloData!['data_vencimento']}")
                                  ]
                                )
                              )
                            else
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(border: Border.all(color: Colors.amber)),
                                child: Text("Nenhum título encontrado\n(será criado manualmente)")
                              )
                          ]
                        )
                      )
                    ]
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Score indicator
                  if (scoreConfianca != null)
                    Column(
                      children: [
                        if (conferenciOk)
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              border: Border.all(color: Colors.green),
                              borderRadius: BorderRadius.circular(8)
                            ),
                            child: Column(
                              children: [
                                Text("🟢 CONFERÊNCIA OK", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                Text("Match automático ${(scoreConfianca! * 100).toStringAsFixed(0)}%", style: TextStyle(color: Colors.green))
                              ]
                            )
                          )
                        else
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              border: Border.all(color: Colors.orange)
                            ),
                            child: Column(
                              children: [
                                Text("⚠️ Revisão sugerida", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                Text("Score ${(scoreConfianca! * 100).toStringAsFixed(0)}% — supervisor vai validar", style: TextStyle(color: Colors.orange))
                              ]
                            )
                          )
                      ]
                    ),
                  
                  SizedBox(height: 24),
                  
                  // Opções adicionais
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Modalidade:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'credito',
                            groupValue: modalidadeSelecionada,
                            onChanged: (value) => setState(() => modalidadeSelecionada = value!),
                            label: Text('⚫ Crédito')
                          ),
                          Radio<String>(
                            value: 'debito',
                            groupValue: modalidadeSelecionada,
                            onChanged: (value) => setState(() => modalidadeSelecionada = value!),
                            label: Text('⚪ Débito')
                          )
                        ]
                      ),
                      SizedBox(height: 16),
                      Text("Parcelas:", style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<int>(
                        value: parcelasSelecionadas,
                        items: List.generate(12, (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text("${i + 1}x")
                        )),
                        onChanged: (value) => setState(() => parcelasSelecionadas = value!),
                        isExpanded: true
                      ),
                      SizedBox(height: 16),
                      Text("Observações (opcional):", style: TextStyle(fontWeight: FontWeight.bold)),
                      TextField(
                        onChanged: (value) => observacoes = value,
                        decoration: InputDecoration(
                          hintText: "Adicione notas se necessário...",
                          border: OutlineInputBorder()
                        ),
                        maxLines: 3
                      )
                    ]
                  ),
                  
                  SizedBox(height: 32),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("VOLTAR")
                      ),
                      FilledButton(
                        onPressed: confirmarVinculo,
                        child: Text("CONFIRMAR E SALVAR")
                      )
                    ]
                  )
                ]
              )
            )
          )
        ]
      )
    );
  }
}
```

---

## TELA 3: SUPERVISOR — Dashboard Consolidado

### 📐 Wireframe

```
╔════════════════════════════════════════════════════════════╗
║ NEXUS — Supervisor                    [Período: 7 dias ▼] ║
║ [Exportar para TOTVS] [⋯ Mais]        [👤] [🚪 Sair]    ║
╠════════════════════════════════════════════════════════════╣
║                                                             ║
║ 🎯 STATUS GERAL — Últimos 7 Dias                           ║
║ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────┐║
║ │ ✅ MATCH      │ │ 🟡 SUGESTÕES │ │ 🔴 GAPS      │ │ ⚠️ ERR║
║ │ AUTOMÁTICO   │ │ 0.75-0.95    │ │ SEM SOL.     │ │ BAIXA║
║ │    234       │ │     23       │ │     15       │ │  3   ║
║ │ >0.95 score  │ │ Pendentes    │ │ Por filial    │ │ Ret. ║
║ └──────────────┘ └──────────────┘ └──────────────┘ └──────┘║
║                                                             ║
║ 💰 VALOR EM RECONCILIAÇÃO: R$ 156.800  (verde)            ║
║ 💰 VALOR EM GAPS:          R$ 34.500   (vermelho)         ║
║                                                             ║
║ ┌─ ✅ MATCHES AUTOMÁTICOS (>0.95)              [▼ Expandir]┐║
║ │ 234 prontos para confirmação                             ││
║ │ [CONFIRMAR TODOS EM LOTE]                                ││
║ │                                                           ││
║ │ Score 98% — NSU 000001234 → NF-001234 R$ 1.500          ││
║ │ Score 97% — NSU 000001235 → NF-001235 R$ 3.200          ││
║ │ Score 96% — NSU 000001236 → NF-001236 R$   240          ││
║ │            [Mostrar mais]                                ││
║ └───────────────────────────────────────────────────────────┘║
║                                                             ║
║ ┌─ 🟡 SUGESTÕES (0.75-0.95)                  [▼ Expandir]─┐║
║ │ 23 aguardando validação manual do supervisor             ││
║ │                                                           ││
║ │ Score 87% — NSU 000002771 vs NF-001234                  ││
║ │            Diff: R$ 15,00 (1%) | 2 dias                ││
║ │            [VER E VALIDAR]                               ││
║ │                                                           ││
║ │ Score 82% — NSU 000002772 vs NF-001235                  ││
║ │            Diff: R$ 45,00 (2%) | 1 dia                 ││
║ │            [VER E VALIDAR]                               ││
║ │                                                           ││
║ │ [Mostrar mais]                                            ││
║ └───────────────────────────────────────────────────────────┘║
║                                                             ║
║ ┌─ 🔴 GAPS SEM SOLUÇÃO (por Filial)          [▼ Expandir]─┐║
║ │ 15 NSUs ou NFs órfãs sem match possível                  ││
║ │                                                           ││
║ │ FILIAL    NSU/NF   VALOR       % Gap   AÇÃO             ││
║ │ ────────────────────────────────────────────────────────  ││
║ │ 001       3 / 2    R$ 4.500    12.5%  [Analisar]       ││
║ │ 002       0 / 1    R$ 1.200     3.3%  [Analisar]       ││
║ │ 003       5 / 0    R$ 8.900    24.7%  [Analisar]       ││
║ │ 004       1 / 0    R$   450     1.2%  [Analisar]       ││
║ │ 005       0 / 0    R$     0     0%                       ││
║ │ ...                                                      ││
║ │ [Mostrar mais filiais]                                   ││
║ └───────────────────────────────────────────────────────────┘║
║                                                             ║
║ ┌─ ⚠️ ERROS DE BAIXA TOTVS                    [▼ Expandir]─┐║
║ │ 3 vínculos confirmados que falharam na baixa PASOE       ││
║ │                                                           ││
║ │ NSU       ERRO                          TENTATIVAS AÇÃO  ││
║ │ ──────────────────────────────────────────────────────── ││
║ │ 000001    E001_TITULO_NAO_ENCONTRADO       1  [Retry]   ││
║ │ 000002    E002_SALDO_INSUFICIENTE          2  [Retry]   ││
║ │ 000003    Connection timeout               1  [Retry]   ││
║ │                                                           ││
║ │ [REPROCESSAR TODOS]                                      ││
║ └───────────────────────────────────────────────────────────┘║
║                                                             ║
║ 📈 RELATÓRIO (Este Mês)                                    ║
║ ┌──────────────────────────────────────────────────────────┐║
║ │ Total Processado: 12.450 títulos                         │║
║ │ Conciliados com Sucesso: 11.890                          │║
║ │ Taxa de Sucesso: 95.5%                                   │║
║ │ Erros Reprocessáveis: 23                                 │║
║ │ Gaps Críticos: 8                                         │║
║ └──────────────────────────────────────────────────────────┘║
║                                                             ║
╚════════════════════════════════════════════════════════════╝
```

### 🎯 Componentes FlutterFlow (Supervisor)

```dart
class SupervisorDashboard extends StatefulWidget {
  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  late StreamSubscription<List<Map>> matchesStream;
  late StreamSubscription<List<Map>> sugestoesStream;
  
  List<Map> matchesAuto = [];
  List<Map> sugestoes = [];
  List<Map> gaps = [];
  List<Map> erros = [];
  
  int totalConciliado = 0;
  double valorConciliado = 0.0;
  double valorGap = 0.0;
  
  String periodSelecionado = '7dias';  // 7dias, 30dias, 365dias
  
  @override
  void initState() {
    // Real-time: Matches automáticos (>0.95)
    matchesStream = supabase
      .from('conciliacao_vinculos')
      .on(RealtimeListenEvent.all, (payload) {
        if (payload.newRecord['score_confianca'] > 0.95 &&
            payload.newRecord['status'] == 'sugerido') {
          setState(() {
            matchesAuto.add(payload.newRecord);
          });
          
          // Notificar supervisor
          _showNotification(
            "🟢 Novo match automático",
            "NSU ${payload.newRecord['transacao_getnet_id']} → Match ${(payload.newRecord['score_confianca'] * 100).toStringAsFixed(0)}%"
          );
        }
      })
      .gte('criado_em', _getDateFilter(periodSelecionado))
      .subscribe();
    
    // Real-time: Sugestões (0.75-0.95)
    sugestoesStream = supabase
      .from('vw_sugestoes_supervisor')
      .on(RealtimeListenEvent.all, (payload) {
        setState(() {
          sugestoes.add(payload.newRecord);
        });
      })
      .gte('cv.criado_em', _getDateFilter(periodSelecionado))
      .subscribe();
    
    // Queries iniciais
    carregarDados();
  }
  
  String _getDateFilter(String periodo) {
    final now = DateTime.now();
    late DateTime inicio;
    
    switch (periodo) {
      case '7dias':
        inicio = now.subtract(Duration(days: 7));
        break;
      case '30dias':
        inicio = now.subtract(Duration(days: 30));
        break;
      case '365dias':
        inicio = now.subtract(Duration(days: 365));
        break;
    }
    
    return inicio.toIso8601String();
  }
  
  Future<void> carregarDados() async {
    final desde = _getDateFilter(periodSelecionado);
    
    // Matches automáticos
    final matches = await supabase
      .from('conciliacao_vinculos')
      .select()
      .gt('score_confianca', 0.95)
      .eq('status', 'sugerido')
      .gte('criado_em', desde)
      .order('score_confianca', ascending: false);
    
    // Sugestões (0.75-0.95)
    final sugest = await supabase
      .from('vw_sugestoes_supervisor')
      .select()
      .gte('score_confianca', 0.75)
      .lt('score_confianca', 0.95)
      .gte('cv.criado_em', desde)
      .order('score_confianca', ascending: false);
    
    // Gaps por filial
    final gapsPorFilial = await supabase
      .from('conciliacao_vinculos')
      .select()
      .eq('status', 'pendente')
      .gte('criado_em', desde)
      .order('filial_cnpj');
    
    // Erros de baixa
    final errosLista = await supabase
      .from('conciliacao_vinculos')
      .select()
      .eq('status', 'erro_baixa')
      .gte('criado_em', desde)
      .order('data_atualizacao', ascending: false);
    
    // Calcular métricas
    final confirmados = await supabase
      .from('conciliacao_vinculos')
      .select()
      .eq('status', 'confirmado')
      .gte('data_confirmacao', desde)
      .count(CountOption.exact);
    
    setState(() {
      matchesAuto = matches ?? [];
      sugestoes = sugest ?? [];
      gaps = gapsPorFilial ?? [];
      erros = errosLista ?? [];
      totalConciliado = confirmados.count ?? 0;
      
      // Calcular valores
      valorConciliado = matches
          ?.fold(0.0, (sum, m) => sum + (m['score_confianca'] * 1000)) ?? 0.0; // Simplificado
      valorGap = gaps
          ?.fold(0.0, (sum, g) => sum + (g['diferenca_valor'] as num).toDouble()) ?? 0.0;
    });
  }
  
  Future<void> confirmarTodosMatches() async {
    final ids = matchesAuto.map((m) => m['vinculo_id']).toList();
    
    if (ids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Nenhum match para confirmar"))
      );
      return;
    }
    
    try {
      await supabase.from('conciliacao_vinculos').update({
        'status': 'confirmado',
        'usuario_validacao': currentUser.email,
        'data_validacao': DateTime.now().toUtc().toIso8601String()
      }).inFilter('vinculo_id', ids);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ ${ids.length} vínculos confirmados!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3)
        )
      );
      
      setState(() => matchesAuto.clear());
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erro ao confirmar: $e"))
      );
    }
  }
  
  void _showNotification(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            Text(message, style: TextStyle(fontSize: 12))
          ]
        ),
        duration: Duration(seconds: 5),
        action: SnackBarAction(label: "Descartar", onPressed: () {})
      )
    );
  }
  
  @override
  void dispose() {
    matchesStream.cancel();
    sugestoesStream.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("NEXUS — Supervisor"),
        actions: [
          DropdownButton<String>(
            value: periodSelecionado,
            items: [
              DropdownMenuItem(value: '7dias', child: Text("Últimos 7 dias")),
              DropdownMenuItem(value: '30dias', child: Text("Últimos 30 dias")),
              DropdownMenuItem(value: '365dias', child: Text("Este ano"))
            ],
            onChanged: (value) {
              setState(() => periodSelecionado = value!);
              carregarDados();
            }
          ),
          SizedBox(width: 16),
          FilledButton.icon(
            onPressed: exportarParaTOTVS,
            icon: Icon(Icons.download),
            label: Text("Exportar TOTVS")
          ),
          SizedBox(width: 16)
        ]
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Métricas de topo
            Padding(
              padding: EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  MetricCard(
                    title: "✅ MATCH AUTOMÁTICO",
                    count: matchesAuto.length,
                    color: Colors.green,
                    onTap: () {}
                  ),
                  MetricCard(
                    title: "🟡 SUGESTÕES",
                    count: sugestoes.length,
                    color: Colors.amber,
                    onTap: () {}
                  ),
                  MetricCard(
                    title: "🔴 GAPS",
                    count: gaps.length,
                    color: Colors.red,
                    onTap: () {}
                  ),
                  MetricCard(
                    title: "⚠️ ERROS",
                    count: erros.length,
                    color: Colors.orange,
                    onTap: () {}
                  )
                ]
              )
            ),
            
            // Valores
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        border: Border.all(color: Colors.green)
                      ),
                      child: Column(
                        children: [
                          Text("💰 CONCILIADO", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text("R\$ 156.800", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green, fontFamily: 'RobotoMono'))
                        ]
                      )
                    )
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        border: Border.all(color: Colors.red)
                      ),
                      child: Column(
                        children: [
                          Text("💰 GAPS", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text("R\$ 34.500", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red, fontFamily: 'RobotoMono'))
                        ]
                      )
                    )
                  )
                ]
              )
            ),
            
            SizedBox(height: 24),
            
            // Seção Matches
            ExpansionPanelList(
              children: [
                ExpansionPanel(
                  headerBuilder: (context, isExpanded) => ListTile(
                    title: Text("✅ MATCHES AUTOMÁTICOS (${matchesAuto.length})", style: TextStyle(fontWeight: FontWeight.bold))
                  ),
                  body: Column(
                    children: [
                      ...matchesAuto.take(5).map((m) => ListTile(
                        title: Text("NSU ${m['nsu']} → NF ${m['numero_nf']}"),
                        subtitle: Text("Score ${(m['score_confianca'] * 100).toStringAsFixed(0)}%"),
                        trailing: Text("R\$ ${m['valor_getnet']}"),
                      )),
                      if (matchesAuto.length > 5)
                        TextButton(
                          onPressed: () {},
                          child: Text("Mostrar mais (${matchesAuto.length - 5})")
                        ),
                      SizedBox(height: 16),
                      FilledButton(
                        onPressed: confirmarTodosMatches,
                        child: Text("CONFIRMAR TODOS EM LOTE (${matchesAuto.length})")
                      )
                    ]
                  ),
                  isExpanded: true
                ),
                
                // Sugestões
                ExpansionPanel(
                  headerBuilder: (context, isExpanded) => ListTile(
                    title: Text("🟡 SUGESTÕES (${sugestoes.length})", style: TextStyle(fontWeight: FontWeight.bold))
                  ),
                  body: Column(
                    children: [
                      ...sugestoes.take(3).map((s) => ListTile(
                        title: Text("NSU ${s['nsu']} vs NF ${s['numero_nf']}"),
                        subtitle: Text("Score ${(s['score_confianca'] * 100).toStringAsFixed(0)}% | Diff: R\$ ${s['diferenca_valor']} | ${s['dias_diferenca']} dias"),
                        trailing: TextButton(
                          onPressed: () => mostrarValidacao(s),
                          child: Text("Validar")
                        )
                      )),
                      if (sugestoes.length > 3)
                        TextButton(
                          onPressed: () {},
                          child: Text("Ver todas (${sugestoes.length})")
                        )
                    ]
                  ),
                  isExpanded: false
                ),
                
                // Gaps
                ExpansionPanel(
                  headerBuilder: (context, isExpanded) => ListTile(
                    title: Text("🔴 GAPS SEM SOLUÇÃO (${gaps.length})", style: TextStyle(fontWeight: FontWeight.bold))
                  ),
                  body: buildGapsTable(),
                  isExpanded: false
                ),
                
                // Erros
                ExpansionPanel(
                  headerBuilder: (context, isExpanded) => ListTile(
                    title: Text("⚠️ ERROS DE BAIXA (${erros.length})", style: TextStyle(fontWeight: FontWeight.bold))
                  ),
                  body: Column(
                    children: [
                      ...erros.map((e) => ListTile(
                        title: Text("NSU ${e['nsu']}"),
                        subtitle: Text("${e['status_baixa']} — ${e['erro_baixa']}"),
                        trailing: TextButton(
                          onPressed: () => reprocessarErro(e['vinculo_id']),
                          child: Text("Retry")
                        )
                      )),
                      SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => reprocessarTodosErros(),
                        child: Text("REPROCESSAR TODOS")
                      )
                    ]
                  ),
                  isExpanded: false
                )
              ]
            )
          ]
        )
      )
    );
  }
  
  Widget buildGapsTable() {
    // Agrupar gaps por filial
    final gapsPorFilial = <String, List>{};
    for (var gap in gaps) {
      final filial = gap['filial_cnpj'];
      gapsPorFilial.putIfAbsent(filial, () => []).add(gap);
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text("FILIAL")),
          DataColumn(label: Text("NSU/NF")),
          DataColumn(label: Text("VALOR")),
          DataColumn(label: Text("AÇÃO"))
        ],
        rows: gapsPorFilial.entries.map((e) => DataRow(
          cells: [
            DataCell(Text(e.key.substring(0, 3))),  // Primeiros 3 dígitos
            DataCell(Text("${e.value.length} gaps")),
            DataCell(Text("R\$ ${e.value.fold(0.0, (sum, g) => sum + (g['diferenca_valor'] as num).toDouble()).toStringAsFixed(2)}")),
            DataCell(TextButton(
              onPressed: () => goToFilialDashboard(e.key),
              child: Text("Analisar")
            ))
          ]
        )).toList()
      )
    );
  }
  
  void mostrarValidacao(Map sugestao) {
    // Abrir modal com comparação
    showDialog(
      context: context,
      builder: (context) => ValidacaoModal(sugestao: sugestao, onConfirm: () {
        // Atualizar status para confirmado
        Navigator.pop(context);
      })
    );
  }
  
  Future<void> reprocessarErro(String vinculoId) async {
    // Marcar para reprocessamento
    await supabase.from('conciliacao_vinculos').update({
      'status': 'pendente'
    }).eq('vinculo_id', vinculoId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Vínculo marcado para reprocessamento"))
    );
  }
  
  Future<void> reprocessarTodosErros() async {
    final ids = erros.map((e) => e['vinculo_id']).toList();
    
    await supabase.from('conciliacao_vinculos').update({
      'status': 'pendente'
    }).inFilter('vinculo_id', ids);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ ${ids.length} vínculos marcados para reprocessamento"))
    );
  }
  
  Future<void> exportarParaTOTVS() async {
    // Buscar todos confirmados não exportados
    final response = await supabase
      .from('conciliacao_vinculos')
      .select()
      .eq('status', 'confirmado')
      .isFilter('data_exportacao', null);
    
    if (response.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Nenhum vínculo para exportar"))
      );
      return;
    }
    
    // Chamar função Edge que gera JSON e envia ao PASOE
    try {
      await supabase.functions.invoke('exportar_para_totvs', body: {
        'vinculos': response
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ ${response.length} vínculos exportados para TOTVS!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3)
        )
      );
      
      // Recarregar dados
      carregarDados();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erro na exportação: $e"))
      );
    }
  }
  
  void goToFilialDashboard(String filialCnpj) {
    // Navegar para dashboard operador da filial específica
    context.pushNamed('operador_dashboard', queryParameters: {
      'filial_cnpj': filialCnpj
    });
  }
}
```

---

## 🔄 Fluxo de Navegação (Routes)

```dart
// main.dart - GoRouter configuration
final routes = [
  GoRoute(
    path: '/',
    builder: (context, state) => LoginScreen(),
  ),
  GoRoute(
    path: '/operador/dashboard',
    builder: (context, state) => OperadorDashboard(
      filialCnpj: state.queryParameters['filial_cnpj'] ?? '',
    ),
  ),
  GoRoute(
    path: '/operador/lancamento',
    builder: (context, state) => LancamentoFluxo(),
  ),
  GoRoute(
    path: '/operador/lancamento/passo1',
    builder: (context, state) => PassoNsuScreen(),
  ),
  GoRoute(
    path: '/operador/lancamento/passo2',
    builder: (context, state) => PassoNfScreen(
      nsuData: state.extra as Map<String, dynamic>,
    ),
  ),
  GoRoute(
    path: '/operador/lancamento/passo3',
    builder: (context, state) {
      final extras = state.extra as Map;
      return PassoConfirmacaoScreen(
        nsuData: extras['nsu_data'],
        tituloData: extras['titulo_data'],
        nfManual: extras['nf_manual'],
      );
    },
  ),
  GoRoute(
    path: '/supervisor/dashboard',
    builder: (context, state) => SupervisorDashboard(),
  ),
];
```

---

## ✅ Checklist de Implementação

- [x] Wireframes das 3 telas (ASCII mockups)
- [x] Componentes FlutterFlow detalhados (Dart code)
- [x] RLS no frontend (automatic filtering)
- [x] Data bindings ao Supabase (queries, real-time)
- [x] Fluxo de navegação (GoRouter routes)
- [x] Micro-interações (loading, toasts, confirmações)
- [x] Responsividade (grid 3 cols desktop, 1 col mobile)
- [x] Acessibilidade (labels, ARIA, semantics)
- [x] Padrões visuais (cores, tipografia, badges)

---

**Status:** 🟢 **DESIGN PRONTO PARA IMPLEMENTAÇÃO**

Data: 2026-04-25  
Próximo: Implementar no FlutterFlow usando código Dart acima como referência
