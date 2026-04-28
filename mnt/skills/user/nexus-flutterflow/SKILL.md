# Skill: Nexus FlutterFlow

**Versão:** 1.0  
**Data:** 2026-04-25  
**Escopo:** Estrutura de telas, integração RLS, componentes, real-time, perfis

---

## Arquitetura Geral

### Stack
- **Frontend:** FlutterFlow (Flutter web + mobile)
- **Backend:** Supabase PostgreSQL + REST API + RLS
- **Auth:** Supabase Auth (JWT)
- **Real-time:** Supabase Realtime (WebSocket)

### Estrutura de Navegação
```
App Root
├── Auth (Login/Register/Reset)
├── Operador Filial
│   ├── Dashboard (gaps por filial)
│   ├── Lançamento Manual (NSU + NF)
│   ├── Histórico (vinculos desta filial)
│   └── Perfil
└── Supervisor
    ├── Dashboard Consolidado (todas filiais)
    ├── Sugestões (0.75-0.95 score)
    ├── Reprocessar Erros
    ├── Exportar TOTVS
    └── Relatórios
└── Admin
    ├── Configurações (parâmetros scoring)
    ├── Usuários (RBAC)
    └── Logs de Auditoria
```

---

## Estrutura de Telas

### 1. Login Screen
```
┌─────────────────────────────┐
│   NEXUS - Conciliação       │
│                             │
│  [Email: _____________]     │
│  [Senha: _____________]     │
│                             │
│  [ENTRAR] [RECUPERAR SENHA] │
│                             │
│  © 2026 Minusa             │
└─────────────────────────────┘
```

**Componentes:**
- TextFormField: email (validator: regex email)
- TextFormField: password (obscureText: true)
- ElevatedButton: onPressed → authenticate()
- Link: "Esqueceu senha?" → resetPassword()

**Lógica:**
```dart
Future<void> authenticate() async {
  final response = await supabase.auth.signInWithPassword(
    email: emailController.text,
    password: passwordController.text
  );
  
  if (response.user != null) {
    // Fetch user profile + perfil
    final profile = await supabase
      .from('user_filiais_cnpj')
      .select()
      .eq('user_id', response.user!.id)
      .single();
    
    // Route por perfil
    if (profile['perfil'] == 'operador_filial') {
      context.pushReplacementNamed('operador_dashboard', queryParameters: {
        'filial_cnpj': profile['filial_cnpj']
      });
    }
  }
}
```

---

### 2. Operador Dashboard (por Filial)

```
┌─────────────────────────────────┐
│ DASHBOARD — Filial 84.943...    │
│ [Horário: 14:30]                │
├─────────────────────────────────┤
│                                 │
│ 🔴 NSU SEM TÍTULO          12   │
│    Pendentes de vínculo        │
│    [VER LISTA] [LANÇAR NOVO]   │
│                                 │
│ 🟡 TÍTULOS SEM NSU         8    │
│    Notas em aberto             │
│    [VER LISTA]                 │
│                                 │
│ ✅ CONCILIADOS HOJE        45   │
│    Desde 00:00                 │
│                                 │
│ 📊 VALOR EM GAP:  R$ 4.500     │
│                                 │
├─────────────────────────────────┤
│ [MENU] [SINCRONIZAR] [PERFIL]   │
└─────────────────────────────────┘
```

**Componentes:**
```dart
class OperadorDashboard extends StatefulWidget {
  final String filialCnpj;
  
  @override
  State<OperadorDashboard> createState() => _OperadorDashboardState();
}

class _OperadorDashboardState extends State<OperadorDashboard> {
  late StreamSubscription<List<Map>> nsuSemTituloStream;
  
  @override
  void initState() {
    // Realtime: NSU sem título desta filial
    nsuSemTituloStream = supabase
      .from('vw_nsu_sem_titulo')
      .on(RealtimeListenEvent.all, (payload) {
        setState(() {
          nsuSemTituloList = payload.newRecord;
        });
      })
      .eq('filial_cnpj', widget.filialCnpj)
      .subscribe();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard — ${widget.filialCnpj}')),
      body: Column(
        children: [
          // Card 1: NSU sem título
          AlertCard(
            title: 'NSU SEM TÍTULO',
            count: nsuSemTituloList.length,
            color: Colors.red,
            onPressed: () => context.pushNamed('nsu_list', extra: widget.filialCnpj)
          ),
          // Card 2: Títulos sem NSU
          AlertCard(
            title: 'TÍTULOS SEM NSU',
            count: tituloSemNsuList.length,
            color: Colors.amber,
            onPressed: () => context.pushNamed('titulo_list', extra: widget.filialCnpj)
          ),
          // Card 3: Conciliados hoje
          StatsCard(
            title: 'CONCILIADOS HOJE',
            value: conciliadosHoje.toString(),
            color: Colors.green
          )
        ]
      )
    );
  }
}
```

**Integração RLS:**
```dart
// Tudo via Supabase: RLS filtra automaticamente por filial_cnpj
// Operador vê apenas: filial_cnpj IN (SELECT filial_cnpj FROM user_filiais_cnpj WHERE user_id = auth.uid())
```

---

### 3. Lançamento Manual (Operador)

```
┌──────────────────────────────────┐
│ LANÇAR VÍNCULO                   │
│ Filial: 84.943.067/0001-393     │
├──────────────────────────────────┤
│                                  │
│ NSU (do comprovante):            │
│ [________000002771_______]       │
│                                  │
│ NF ou Adiantamento (AN):         │
│ [__________NF-001234_________]   │
│                                  │
│ Modalidade:                      │
│ [⚫ Crédito ⚪ Débito]            │
│                                  │
│ Parcelas:                        │
│ [____1____]                      │
│                                  │
│ Observações (opcional):          │
│ [____________________________]    │
│ [____________________________]    │
│                                  │
│ [CANCELAR] [SALVAR]              │
└──────────────────────────────────┘
```

**Lógica:**
```dart
Future<void> salvarVinculo() async {
  // 1. Validar NSU existe em transacoes_getnet
  final nsuCheck = await supabase
    .from('transacoes_getnet')
    .select('transacao_id, valor')
    .eq('filial_cnpj', filialCnpj)
    .eq('nsu', nsuController.text)
    .single();
  
  if (nsuCheck == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ NSU não encontrado na GETNET'))
    );
    return;
  }
  
  // 2. Buscar título TOTVS por NF
  final titulos = await totvs.buscar_titulos_por_nf(
    filialCnpj, 
    nfController.text
  );
  
  final tituloId = titulos.isNotEmpty ? titulos[0]['titulo_id'] : null;
  
  // 3. Inserir vínculo
  await supabase.from('conciliacao_vinculos').insert({
    'filial_cnpj': filialCnpj,
    'transacao_getnet_id': nsuCheck['transacao_id'],
    'titulo_totvs_id': tituloId,
    'numero_nf_manual': nfController.text,
    'tipo_vinculacao': 'manual',
    'score_confianca': tituloId != null ? 0.95 : 0.00,
    'status': tituloId != null ? 'confirmado' : 'pendente',
    'criado_por': currentUser.email,
    'criado_em': DateTime.now().toUtc()
  });
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('✅ Vínculo lançado com sucesso'))
  );
  
  Navigator.pop(context);
}
```

---

### 4. Supervisor Dashboard (Consolidado)

```
┌─────────────────────────────────┐
│ SUPERVISOR — Visão Consolidada  │
│ [Período: Últimos 7 dias]       │
├─────────────────────────────────┤
│                                 │
│ ✅ MATCH AUTOMÁTICO (>0.95)    │
│    234 vínculos prontos         │
│    [CONFIRMAR LOTE]             │
│                                 │
│ 🟡 SUGESTÕES (0.75-0.95)       │
│    23 pendentes de validação    │
│    [VER E VALIDAR]              │
│                                 │
│ 🔴 GAPS SEM SOLUÇÃO            │
│    15 NSUs/NFs órfãs            │
│    [ANALISAR POR FILIAL]        │
│                                 │
│ ⚠️ ERROS DE BAIXA TOTVS         │
│    3 reprocessar                │
│    [REPROCESSAR]                │
│                                 │
├─────────────────────────────────┤
│ FILIAL    NSU/NF    VALOR       │
│ 001       3    2    R$ 4.500    │
│ 002       0    1    R$ 1.200    │
│ 003       5    0    R$ 8.900    │
│           ...                    │
└─────────────────────────────────┘
```

**Componentes & Realtime:**
```dart
class SupervisorDashboard extends StatefulWidget {
  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  late StreamSubscription<List<Map>> autoMatchStream;
  late StreamSubscription<List<Map>> sugestoesStream;
  
  @override
  void initState() {
    // Real-time: Matches automáticos (> 0.95)
    autoMatchStream = supabase
      .from('conciliacao_vinculos')
      .on(RealtimeListenEvent.all, (payload) {
        if (payload.newRecord['score_confianca'] > 0.95 &&
            payload.newRecord['status'] == 'sugerido') {
          setState(() {
            autoMatches.add(payload.newRecord);
          });
        }
      })
      .subscribe();
    
    // Real-time: Sugestões (0.75-0.95)
    sugestoesStream = supabase
      .from('vw_sugestoes_supervisor')
      .on(RealtimeListenEvent.all, (payload) {
        setState(() {
          sugestoes.add(payload.newRecord);
        });
      })
      .subscribe();
  }
  
  Future<void> confirmarLote() async {
    // Confirmar todos matches automáticos em lote
    final ids = autoMatches.map((m) => m['vinculo_id']).toList();
    
    await supabase.from('conciliacao_vinculos').update({
      'status': 'confirmado',
      'usuario_validacao': currentUser.email,
      'data_validacao': DateTime.now().toUtc()
    }).inFilter('vinculo_id', ids);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ ${ids.length} vínculos confirmados'))
    );
  }
}
```

---

### 5. Validação de Sugestões (Supervisor)

```
┌────────────────────────────────┐
│ VALIDAR SUGESTÃO              │
│ Score: 87% (muito provável)   │
├────────────────────────────────┤
│                                │
│ NSU GETNET:     000002771     │
│ Valor:          R$ 1.500,00   │
│ Data:           2026-03-26    │
│                                │
│ vs.                            │
│                                │
│ NF TOTVS:       NF-001234     │
│ Valor:          R$ 1.515,00   │
│ Vencimento:     2026-05-28    │
│                                │
│ Diferença Valor: R$ 15,00 (1%) │
│ Diferença Data:  2 dias        │
│                                │
│ [NÃO É] [SIM, CONFIRMAR]      │
└────────────────────────────────┘
```

**Lógica:**
```dart
Future<void> confirmarSugestao(String vinculoId, bool aprova) async {
  if (!aprova) {
    // Rejeitar
    await supabase.from('conciliacao_vinculos').update({
      'status': 'rejeitado',
      'usuario_validacao': currentUser.email,
      'data_validacao': DateTime.now().toUtc()
    }).eq('vinculo_id', vinculoId);
  } else {
    // Confirmar e exportar para TOTVS
    await supabase.from('conciliacao_vinculos').update({
      'status': 'confirmado',
      'usuario_validacao': currentUser.email,
      'data_validacao': DateTime.now().toUtc()
    }).eq('vinculo_id', vinculoId);
    
    // Chamar função Edge para exportar JSON e enviar a TOTVS
    await supabase.functions.invoke('exportar_para_totvs', body: {
      'vinculo_id': vinculoId
    });
  }
  
  setState(() {
    // Carregar próxima sugestão
    carregarProxima();
  });
}
```

---

## Integração Supabase RLS no Front

### Setup Inicial
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://seu-project.supabase.co',
    anonKey: 'sua-anon-key',
    authFlowType: AuthFlowType.pkce  // Important para web/mobile
  );
  
  runApp(const MyApp());
}
```

### Queries com RLS
```dart
// Operador: vê apenas sua filial (automático via RLS)
final gap = await supabase
  .from('vw_nsu_sem_titulo')
  .select()
  // NÃO PRECISA FILTRAR POR filial_cnpj — RLS faz automaticamente
  .order('data_venda', ascending: false)
  .limit(50);

// Supervisor: vê tudo (RLS permite automaticamente)
final allGaps = await supabase
  .from('vw_nsu_sem_titulo')
  .select()
  .order('filial_cnpj')
  .order('data_venda', ascending: false);

// Admin: bypass total
// (mesma query, mas RLS não filtra)
```

### Exemplo: Listar Gaps com Filtro
```dart
Future<List<Map>> buscarNsuSemTitulo(String filialCnpj) async {
  try {
    final response = await supabase
      .from('vw_nsu_sem_titulo')
      .select()
      .eq('filial_cnpj', filialCnpj)  // Explícito para operador, ignorado por RLS se sem permissão
      .order('data_venda', ascending: false);
    
    return List<Map>.from(response);
  } on PostgrestException catch (error) {
    if (error.code == 'PGRST116') {  // RLS violation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Sem permissão para esta filial'))
      );
    }
    return [];
  }
}
```

---

## Componentes de Alerta

### AlertCard (🔴🟡✅)
```dart
class AlertCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final VoidCallback onPressed;
  
  const AlertCard({
    required this.title,
    required this.count,
    required this.color,
    required this.onPressed
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color)
                  ),
                  SizedBox(height: 8),
                  Text(
                    count.toString(),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                  )
                ]
              ),
              Icon(Icons.arrow_forward_ios, color: color)
            ]
          )
        )
      )
    );
  }
}
```

### StatusBadge (Pendente/Confirmado/Erro)
```dart
class StatusBadge extends StatelessWidget {
  final String status;
  
  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch(status) {
      'pendente' => (Colors.orange, Icons.schedule, 'Pendente'),
      'confirmado' => (Colors.green, Icons.check_circle, 'Confirmado'),
      'erro_baixa' => (Colors.red, Icons.error, 'Erro na Baixa'),
      'rejeitado' => (Colors.grey, Icons.close, 'Rejeitado'),
      _ => (Colors.blue, Icons.help, 'Desconhecido')
    };
    
    return Chip(
      backgroundColor: color.withOpacity(0.2),
      label: Text(label, style: TextStyle(color: color)),
      avatar: Icon(icon, color: color, size: 16)
    );
  }
}
```

---

## Real-time Subscriptions para Gaps

### Operador: Notificação NSU novo (🔴)
```dart
StreamSubscription<List<Map>> subscribeNsuSemTitulo(String filialCnpj) {
  return supabase
    .from('vw_nsu_sem_titulo')
    .on(RealtimeListenEvent.insert, (payload) {
      if (payload.newRecord['filial_cnpj'] == filialCnpj) {
        _showNotification(
          title: '🔴 NSU novo pendente',
          body: 'NSU ${payload.newRecord['nsu']} aguarda vínculo'
        );
        setState(() {
          nsuList.insert(0, payload.newRecord);
        });
      }
    })
    .eq('filial_cnpj', filialCnpj)
    .subscribe();
}
```

### Supervisor: Notificação de Sugestão (0.75-0.95)
```dart
StreamSubscription<List<Map>> subscribeSugestoes() {
  return supabase
    .from('vw_sugestoes_supervisor')
    .on(RealtimeListenEvent.insert, (payload) {
      final score = payload.newRecord['score_confianca'] as double;
      if (score >= 0.75 && score < 0.95) {
        _showNotification(
          title: '🟡 Nova sugestão',
          body: 'Score ${(score*100).toStringAsFixed(0)}% — ${payload.newRecord['nsu']}'
        );
      }
    })
    .subscribe();
}
```

---

## Perfis e Permissões

### Model: UserProfile
```dart
class UserProfile {
  final String userId;
  final String email;
  final String perfil; // 'operador_filial', 'supervisor', 'admin'
  final List<String> filialsCnpj; // Filiais permitidas (operador_filial)
  
  UserProfile({
    required this.userId,
    required this.email,
    required this.perfil,
    required this.filialsCnpj
  });
  
  bool canAccessFilial(String filialCnpj) {
    return perfil == 'admin' || 
           perfil == 'supervisor' || 
           filialsCnpj.contains(filialCnpj);
  }
  
  bool canConfirmBatch() => perfil == 'supervisor' || perfil == 'admin';
  bool canExportToTOTVS() => perfil == 'supervisor' || perfil == 'admin';
  bool canEditParameters() => perfil == 'admin';
}
```

### Navigation Guard
```dart
Future<void> checkPermission(String requiredRole) async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    context.pushReplacementNamed('login');
    return;
  }
  
  // Fetch profile
  final profiles = await supabase
    .from('user_filiais_cnpj')
    .select()
    .eq('user_id', user.id);
  
  if (profiles.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Perfil não configurado'))
    );
    return;
  }
  
  final perfil = profiles[0]['perfil'];
  
  // Validar permissão
  if (requiredRole == 'supervisor' && perfil != 'supervisor' && perfil != 'admin') {
    context.pushReplacementNamed('operador_dashboard');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Acesso restrito a supervisores'))
    );
  }
}
```

---

## Checklist FlutterFlow

- [ ] Auth com Supabase (PKCE flow)
- [ ] RLS policies testadas (3 perfis)
- [ ] Real-time subscriptions para gaps
- [ ] Dashboard operador com alertas 🔴🟡✅
- [ ] Dashboard supervisor consolidado
- [ ] Lançamento manual (NSU + NF)
- [ ] Validação de sugestões (supervisor)
- [ ] Exportação para TOTVS (JSON)
- [ ] Status badges (pendente/confirmado/erro)
- [ ] Notificações em tempo real
- [ ] Nav guards por perfil
- [ ] Logout & session management
- [ ] Loading states & error handling
- [ ] Responsividade (web + mobile)
