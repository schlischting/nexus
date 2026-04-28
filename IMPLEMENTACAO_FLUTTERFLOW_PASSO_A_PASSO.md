# 🚀 Implementação FlutterFlow — Nexus v3.0

**Data:** 2026-04-27  
**Status:** ROTEIRO EXECUTÁVEL  
**Tempo estimado:** 8-10 horas de trabalho

---

## ✅ PRÉ-REQUISITOS

- [ ] Supabase projeto criado
- [ ] `schema_nexus_v3.0.sql` executado com sucesso
- [ ] RLS policies configuradas (via CHECKLIST_SUPABASE.md)
- [ ] FlutterFlow projeto criado (ou Flutter nativo)
- [ ] Supabase Flutter SDK instalado (`supabase_flutter: ^1.10.0`)
- [ ] 2 usuários de teste criados:
  - `operador@filial001.com` (role: `operador_filial`)
  - `supervisor@nexus.com` (role: `supervisor`)

---

## FASE 1: SETUP INICIAL (Passos 1-5)

### ✏️ PASSO 1: Criar Projeto Flutter/FlutterFlow

**FlutterFlow:**
1. Ir para **flutterflow.io** → New Project
2. Nome: `nexus-reconciliation`
3. Escolher template: `Blank`
4. Criar projeto

**Flutter Nativo:**
```bash
flutter create nexus_reconciliation
cd nexus_reconciliation
flutter pub add supabase_flutter
flutter pub add go_router
flutter pub add provider
```

**Status esperado:** Projeto criado, pronto para adicionar páginas.

---

### ✏️ PASSO 2: Configurar Supabase no FlutterFlow/Flutter

**Em `main.dart` (Flutter nativo):**
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://YOUR_SUPABASE_URL.supabase.co',
    anonKey: 'YOUR_ANON_KEY',
  );
  runApp(const MyApp());
}
```

**Em FlutterFlow:**
1. Ir para **Settings → Integrations → Supabase**
2. Colar URL e Anon Key
3. Testar conexão → Verde ✅

**Status esperado:** Supabase conectado e testado.

---

### ✏️ PASSO 3: Configurar GoRouter para Navegação

**`lib/router.dart`:**
```dart
import 'package:go_router/go_router.dart';
import 'pages/login_page.dart';
import 'pages/operador_dashboard_page.dart';
import 'pages/operador_lancamento_page.dart';
import 'pages/supervisor_dashboard_page.dart';

final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginPage(),
    ),
    GoRoute(
      path: '/operador/dashboard',
      builder: (context, state) => OperadorDashboardPage(
        filialCnpj: state.pathParameters['filialCnpj'],
      ),
    ),
    GoRoute(
      path: '/operador/lancamento',
      builder: (context, state) => OperadorLancamentoPage(
        filialCnpj: state.extra as String,
      ),
    ),
    GoRoute(
      path: '/supervisor/dashboard',
      builder: (context, state) => SupervisorDashboardPage(),
    ),
  ],
);
```

**Em `main.dart`:**
```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      title: 'Nexus',
    );
  }
}
```

**Status esperado:** Rotas definidas, navegação testada.

---

### ✏️ PASSO 4: Criar Página de Login

**`lib/pages/login_page.dart`:**
```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Buscar role do usuário em user_filiais_cnpj
      final userRole = await Supabase.instance.client
          .from('user_filiais_cnpj')
          .select('perfil_usuario')
          .eq('user_id', response.user!.id)
          .single()
          .then((data) => data['perfil_usuario']);

      if (userRole == 'supervisor') {
        context.go('/supervisor/dashboard');
      } else {
        // Buscar primeira filial do operador
        final filialData = await Supabase.instance.client
            .from('user_filiais_cnpj')
            .select('filial_cnpj')
            .eq('user_id', response.user!.id)
            .limit(1)
            .single();

        context.go('/operador/dashboard/${filialData['filial_cnpj']}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1F2937),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'NEXUS',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: Color(0xFF374151),
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  filled: true,
                  fillColor: Color(0xFF374151),
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 24),
              _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3B82F6),
                        padding: EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 14,
                        ),
                      ),
                      child: Text(
                        'Entrar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Status esperado:** Login funcional, direciona para dashboard correto por role.

---

### ✏️ PASSO 5: Criar Provider para Estado Global

**`lib/providers/auth_provider.dart`:**
```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final supabase = Supabase.instance.client;
  User? _currentUser;
  String? _userRole;
  String? _filialCnpj;

  User? get currentUser => _currentUser;
  String? get userRole => _userRole;
  String? get filialCnpj => _filialCnpj;

  AuthProvider() {
    _initAuth();
  }

  void _initAuth() {
    _currentUser = supabase.auth.currentUser;
    if (_currentUser != null) {
      _loadUserRole();
    }
  }

  Future<void> _loadUserRole() async {
    try {
      final data = await supabase
          .from('user_filiais_cnpj')
          .select('perfil_usuario, filial_cnpj')
          .eq('user_id', _currentUser!.id)
          .limit(1)
          .single();

      _userRole = data['perfil_usuario'];
      _filialCnpj = data['filial_cnpj'];
      notifyListeners();
    } catch (e) {
      print('Erro ao carregar role: $e');
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    _currentUser = null;
    _userRole = null;
    _filialCnpj = null;
    notifyListeners();
  }
}
```

**Em `main.dart`:**
```dart
void main() async {
  await Supabase.initialize(...);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MyApp(),
    ),
  );
}
```

**Status esperado:** AuthProvider configurado e injetando estado em toda app.

---

## FASE 2: TELA 1 — OPERADOR DASHBOARD (Passos 6-10)

### ✏️ PASSO 6: Criar Página Dashboard — Estrutura Base

**`lib/pages/operador_dashboard_page.dart`:**
```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../components/flutter_components.dart';
import '../queries/supabase_queries.dart';
import '../providers/auth_provider.dart';

class OperadorDashboardPage extends StatefulWidget {
  final String filialCnpj;

  const OperadorDashboardPage({required this.filialCnpj});

  @override
  _OperadorDashboardPageState createState() => _OperadorDashboardPageState();
}

class _OperadorDashboardPageState extends State<OperadorDashboardPage> {
  late AuthProvider authProvider;
  int _nsuSemTituloCount = 0;
  int _tituloSemNsuCount = 0;
  int _conciliadosCount = 0;
  double _valorGapTotal = 0.0;

  @override
  void initState() {
    super.initState();
    authProvider = context.read<AuthProvider>();
    _loadMetricas();
  }

  Future<void> _loadMetricas() async {
    try {
      // Carregar contagem de NSU sem título
      final nsuResponse = await Supabase.instance.client
          .from('vw_nsu_sem_titulo')
          .select('COUNT', const FetchOptions(count: CountOption.exact))
          .eq('filial_cnpj', widget.filialCnpj);

      // Carregar contagem de título sem NSU
      final tituloResponse = await Supabase.instance.client
          .from('vw_titulo_sem_nsu')
          .select('COUNT', const FetchOptions(count: CountOption.exact))
          .eq('filial_cnpj', widget.filialCnpj);

      setState(() {
        _nsuSemTituloCount = nsuResponse.count ?? 0;
        _tituloSemNsuCount = tituloResponse.count ?? 0;
      });
    } catch (e) {
      print('Erro ao carregar métricas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NEXUS — Operador Dashboard'),
        backgroundColor: Color(0xFF1F2937),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            DashboardHeader(
              filialNome: widget.filialCnpj,
              filialOptions: ['001', '002', '003'], // TODO: carregar de DB
              onFilialChanged: (newFilial) {
                context.go('/operador/dashboard/$newFilial');
              },
              notificationCount: _nsuSemTituloCount + _tituloSemNsuCount,
              onNotificationTap: () {},
              onProfileTap: () {},
              onLogoutTap: () async {
                await authProvider.logout();
                if (!mounted) return;
                context.go('/login');
              },
              userRole: 'operador_filial',
            ),
            SizedBox(height: 16),
            // RESUMO DO DIA
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GapCard(
                    title: 'NSU SEM TÍTULO',
                    count: _nsuSemTituloCount,
                    status: 'critical',
                    description: 'Pendentes',
                  ),
                  GapCard(
                    title: 'TÍTULOS SEM NSU',
                    count: _tituloSemNsuCount,
                    status: 'warning',
                    description: 'Abertos',
                  ),
                  GapCard(
                    title: 'CONCILIADOS',
                    count: _conciliadosCount,
                    status: 'success',
                    description: 'Hoje',
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Valor em gap
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFEF4444)),
                ),
                child: Column(
                  children: [
                    Text(
                      '💰 VALOR EM GAP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'R\$ ${_valorGapTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // TODO: Passo 7 — Adicionar seções expandíveis
          ],
        ),
      ),
    );
  }
}
```

**Status esperado:** Dashboard com header e resumo do dia funcionando.

---

### ✏️ PASSO 7: Adicionar Seção "NSU SEM TÍTULO" com StreamBuilder

**No `_OperadorDashboardPageState`, adicionar após o Valor em Gap:**

```dart
SizedBox(height: 24),
StreamBuilder<List<Map<String, dynamic>>>(
  stream: SupabaseQueries.streamNsuSemTitulo(widget.filialCnpj),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text('Erro: ${snapshot.error}'),
      );
    }

    final nsuList = snapshot.data ?? [];

    return ExpansionTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('🔴 NSU SEM TÍTULO (${nsuList.length})'),
          Text(
            'Lançamentos ainda não vinculados',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: nsuList.isEmpty
              ? Text('Nenhum NSU pendente')
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: nsuList.length,
                  itemBuilder: (context, index) {
                    final nsu = nsuList[index];
                    return ListTile(
                      title: Text('NSU: ${nsu['nsu']}'),
                      subtitle: Text('Data: ${nsu['data_venda']} | Valor: R\$ ${nsu['valor_venda']}'),
                      trailing: IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          context.go('/operador/lancamento/${nsu['transacao_id']}');
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  },
),
```

**Status esperado:** Seção NSU funcionando com dados em tempo real do Supabase.

---

### ✏️ PASSO 8: Adicionar Seção "LANÇAMENTOS COM PROBLEMA"

**No mesmo `ExpansionTile` para erros:**

```dart
SizedBox(height: 12),
ExpansionTile(
  title: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text('🟡 LANÇAMENTOS COM PROBLEMA (?)'),
      Text('Erros de validação', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
    ],
  ),
  children: [
    Padding(
      padding: EdgeInsets.all(16),
      child: StreamBuilder(
        stream: Supabase.instance.client
            .from('conciliacao_vinculos')
            .stream(primaryKey: ['vinculo_id'])
            .eq('filial_cnpj', widget.filialCnpj)
            .eq('status', 'erro'),
        builder: (context, snapshot) {
          final erros = snapshot.data ?? [];
          return erros.isEmpty
              ? Text('Nenhum erro')
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: erros.length,
                  itemBuilder: (context, index) {
                    final erro = erros[index];
                    return ListTile(
                      title: Text('NSU: ${erro['transacao_getnet_id']}'),
                      subtitle: Text('Erro: ${erro['status_baixa']}'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          // TODO: Ação para corrigir
                        },
                        child: Text('Corrigir'),
                      ),
                    );
                  },
                );
        },
      ),
    ),
  ],
),
```

**Status esperado:** Seção de erros exibindo lançamentos com problema.

---

### ✏️ PASSO 9: Adicionar Seção "TÍTULOS SEM NSU" e "ÚLTIMAS RECONCILIAÇÕES"

Seguir padrão similar aos passos anteriores:

```dart
// TÍTULOS SEM NSU
ExpansionTile(
  title: Text('🟡 TÍTULOS SEM NSU (?)'),
  children: [
    // StreamBuilder para vw_titulo_sem_nsu
    // Botão [Vincular] em cada linha
  ],
),

// ÚLTIMAS RECONCILIAÇÕES
ExpansionTile(
  title: Text('✅ ÚLTIMAS RECONCILIAÇÕES'),
  children: [
    // Query simples (não real-time) em conciliacao_vinculos com status='confirmado'
    // Últimas 10 registros
  ],
),
```

**Status esperado:** Dashboard completo com 4 seções expandíveis.

---

### ✏️ PASSO 10: Testar Dashboard com Operador

**Teste manual:**
1. Login com `operador@filial001.com`
2. Verificar se métricas carregam ✅
3. Expandir cada seção e confirmar dados ✅
4. Verificar filtro por filial funciona ✅
5. Testar notificações em tempo real (adicionar NSU no Supabase manualmente) ✅

**Erros comuns:**
- ❌ "RLS policy denying access" → Verificar RLS em CHECKLIST_SUPABASE.md
- ❌ "Stream not updating" → Verificar subscriptions ativadas em Supabase
- ❌ "Filial não carregando" → User não associado em user_filiais_cnpj

**Status esperado:** Dashboard Operador 100% funcional.

---

## FASE 3: TELA 2 — OPERADOR LANÇAMENTO (Passos 11-15)

### ✏️ PASSO 11: Criar Página Lançamento — Step 1 (NSU Verification)

**`lib/pages/operador_lancamento_page.dart`:**
```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../queries/supabase_queries.dart';

class OperadorLancamentoPage extends StatefulWidget {
  final String? nsuId; // Vem de dashboard ou null para novo

  const OperadorLancamentoPage({this.nsuId});

  @override
  _OperadorLancamentoPageState createState() => _OperadorLancamentoPageState();
}

class _OperadorLancamentoPageState extends State<OperadorLancamentoPage> {
  int _currentStep = 0;
  final _nsuController = TextEditingController();
  final _nfController = TextEditingController();
  final _modalidadeController = TextEditingController();
  final _parcelasController = TextEditingController();

  Map<String, dynamic>? _selectedNsu;
  Map<String, dynamic>? _selectedTitulo;
  double _scoreConfianca = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lançamento NSU + NF'),
        backgroundColor: Color(0xFF1F2937),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        steps: [
          // STEP 1: Buscar NSU
          Step(
            title: Text('1. Buscar NSU'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nsuController,
                  decoration: InputDecoration(labelText: 'Número NSU'),
                  onChanged: (value) async {
                    // Buscar NSU em tempo real
                    if (value.length > 3) {
                      final results = await Supabase.instance.client
                          .from('transacoes_getnet')
                          .select()
                          .ilike('nsu', '%$value%')
                          .limit(10);

                      // Mostrar suggestions em dropdown
                      // (Implementação: dropdown customizado)
                    }
                  },
                ),
                SizedBox(height: 16),
                _selectedNsu != null
                    ? Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NSU Selecionado:'),
                            Text(_selectedNsu!['nsu']),
                            Text('Valor: R\$ ${_selectedNsu!['valor_venda']}'),
                            Text('Data: ${_selectedNsu!['data_venda']}'),
                          ],
                        ),
                      )
                    : Text('Nenhum NSU selecionado'),
              ],
            ),
            isActive: _currentStep >= 0,
          ),

          // STEP 2: Selecionar NF
          Step(
            title: Text('2. Selecionar NF'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nfController,
                  decoration: InputDecoration(labelText: 'Número NF'),
                ),
                SizedBox(height: 16),
                Text('Títulos disponíveis:'),
                // StreamBuilder para listar titulos_totvs
                StreamBuilder(
                  stream: Supabase.instance.client
                      .from('titulos_totvs')
                      .stream(primaryKey: ['titulo_id'])
                      .eq('status', 'aberto'),
                  builder: (context, snapshot) {
                    final titulos = snapshot.data ?? [];
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: titulos.length,
                      itemBuilder: (context, index) {
                        final titulo = titulos[index];
                        return RadioListTile<String>(
                          title: Text('NF: ${titulo['numero_nf']}'),
                          subtitle: Text('Valor: R\$ ${titulo['valor_bruto']}'),
                          value: titulo['titulo_id'],
                          groupValue: _selectedTitulo?['titulo_id'],
                          onChanged: (value) {
                            setState(() => _selectedTitulo = titulo);
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            isActive: _currentStep >= 1,
          ),

          // STEP 3: Confirmar com Score
          Step(
            title: Text('3. Confirmar'),
            content: _buildConfirmationStep(),
            isActive: _currentStep >= 2,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Modalidade:'),
        DropdownButton<String>(
          value: _modalidadeController.text.isEmpty ? 'credito' : _modalidadeController.text,
          items: [
            DropdownMenuItem(value: 'credito', child: Text('Crédito')),
            DropdownMenuItem(value: 'debito', child: Text('Débito')),
          ],
          onChanged: (value) {
            setState(() => _modalidadeController.text = value ?? 'credito');
          },
        ),
        SizedBox(height: 16),
        Text('Quantidade de Parcelas:'),
        TextField(
          controller: _parcelasController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: '1-12'),
        ),
        SizedBox(height: 24),
        // Score Card
        if (_scoreConfianca > 0)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _scoreConfianca >= 0.95
                  ? Color(0xFF10B981).withOpacity(0.1)
                  : Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'Score de Confiança: ${(_scoreConfianca * 100).toStringAsFixed(1)}%',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                LinearProgressIndicator(value: _scoreConfianca),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _onStepContinue() async {
    if (_currentStep == 0) {
      // Validar NSU selecionada
      if (_selectedNsu == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selecione um NSU')),
        );
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 1) {
      // Validar título selecionado e calcular score
      if (_selectedTitulo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selecione um título')),
        );
        return;
      }

      // Calcular score
      final score = await Supabase.instance.client.rpc(
        'calcular_score_matching',
        params: {
          'p_valor_getnet': _selectedNsu!['valor_venda'],
          'p_valor_totvs': _selectedTitulo!['valor_bruto'],
          'p_data_getnet': _selectedNsu!['data_venda'],
          'p_data_totvs': _selectedTitulo!['data_vencimento'],
        },
      );

      setState(() {
        _scoreConfianca = (score as num).toDouble();
        _currentStep++;
      });
    } else if (_currentStep == 2) {
      // Confirmar e criar vínculo
      _confirmMatch();
    }
  }

  Future<void> _confirmMatch() async {
    try {
      final result = await SupabaseQueries.criarVinculo(
        nsuId: _selectedNsu!['transacao_id'],
        tituloId: _selectedTitulo!['titulo_id'],
        filialCnpj: _selectedNsu!['filial_cnpj'],
        modalidade: _modalidadeController.text,
        parcelas: int.parse(_parcelasController.text),
      );

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Vínculo criado com sucesso!')),
        );
        context.go('/operador/dashboard');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erro: $e')),
      );
    }
  }
}
```

**Status esperado:** Wizard de 3 passos funcionando.

---

### ✏️ PASSO 12-15: Refinar Lançamento e Testes

- **PASSO 12:** Adicionar dropdown com suggestions na Step 1
- **PASSO 13:** Implementar busca em tempo real de NFs na Step 2
- **PASSO 14:** Adicionar validação de score (rejeitar se < 0.5)
- **PASSO 15:** Testar fluxo completo com dados reais

**Teste manual:**
1. Navegar para /operador/lancamento
2. Selecionar NSU → Deve listar sugestões ✅
3. Selecionar NF → Score deve calcular automaticamente ✅
4. Confirmar → Vínculo deve aparecer no dashboard ✅

**Status esperado:** Lançamento 100% funcional.

---

## FASE 4: TELA 3 — SUPERVISOR DASHBOARD (Passos 16-20)

### ✏️ PASSO 16: Criar Página Supervisor Dashboard

**`lib/pages/supervisor_dashboard_page.dart`:**

Segue padrão similar ao Dashboard Operador, mas com:
- 4 seções principais (matches, sugestões, gaps, erros)
- Seletor de período (hoje, semana, mês)
- Botões batch: [CONFIRMAR TODOS EM LOTE], [REPROCESSAR TODOS]
- View consolidada de TODAS as filiais (sem filtro RLS no frontend — RLS automático)

```dart
// Estrutura similar a OperadorDashboardPage
// Mas com StreamBuilder para vw_sugestoes_supervisor
// E botões de ação em lote
```

### ✏️ PASSO 17-20: Implementar Seções Supervisor

- **PASSO 17:** Seção "✅ MATCHES AUTOMÁTICOS" com botão batch confirm
- **PASSO 18:** Seção "🟡 SUGESTÕES PENDENTES" com score visualizado
- **PASSO 19:** Seção "🔴 GAPS SEM SOLUÇÃO" com ações
- **PASSO 20:** Seção "⚠️ ERROS DE BAIXA" com [REPROCESSAR TODOS]

---

## FASE 5: TESTES E VALIDAÇÃO (Passos 21-25)

### ✏️ PASSO 21: Testar RLS com 2 Usuários

**Operador 1 (Filial 001):**
```
Email: operador.001@nexus.com
Role: operador_filial
Filial: 001
```

**Operador 2 (Filial 002):**
```
Email: operador.002@nexus.com
Role: operador_filial
Filial: 002
```

**Teste:**
1. Operador 1 login → vê APENAS filial 001 ✅
2. Operador 2 login → vê APENAS filial 002 ✅
3. Supervisor login → vê TODAS as filiais ✅

---

### ✏️ PASSO 22: Testar Real-Time Updates

**Teste:**
1. Operador 1 abre dashboard
2. Supervisor insere novo match no Supabase (via SQL ou app)
3. Dashboard Operador 1 atualiza em < 2 segundos ✅

---

### ✏️ PASSO 23: Testar Score Calculation

**Casos de teste:**
```
Caso 1: Valores iguais, datas iguais
→ Score deve ser 1.0 (100%)

Caso 2: Valores 5% diferentes, 2 dias diferença
→ Score deve ser ~0.85-0.90

Caso 3: Valores 20% diferentes
→ Score deve ser < 0.75 (rejeitar)
```

---

### ✏️ PASSO 24: Testar Exportação para TOTVS

**Teste:**
1. Supervisor confirma 5 matches
2. Clica [EXPORTAR PARA TOTVS]
3. Status muda para "exportado" ✅
4. Data de exportação registrada ✅

---

### ✏️ PASSO 25: Teste de Carga e Performance

**Cenário:** Dashboard com 1.000 NSUs sem título

**Métricas esperadas:**
- Tempo de carregamento: < 2s ✅
- Memory usage: < 100MB ✅
- Real-time latency: < 500ms ✅

---

## 🎯 CHECKLIST FINAL

- [ ] Login funciona (ambos roles)
- [ ] Dashboard Operador exibe alertas corretos
- [ ] Lançamento 3-step completo
- [ ] Score calcula automaticamente
- [ ] Dashboard Supervisor consolidado
- [ ] RLS filtra dados por usuário
- [ ] Real-time updates funcionam
- [ ] Exportação TOTVS funciona
- [ ] Logout funciona
- [ ] Responsive (mobile/tablet/desktop)
- [ ] Sem erros no console

---

## 📞 ERROS COMUNS E SOLUÇÕES

| Erro | Causa | Solução |
|------|-------|---------|
| **RLS policy denying access** | User não tem permissão | Verificar user_filiais_cnpj e perfil_usuario |
| **"relation does not exist"** | View não criada | Executar schema_nexus_v3.0.sql novamente |
| **Stream not updating** | Realtime not enabled | Verificar em Supabase Dashboard → Realtime |
| **Score = 0.0** | Função calcular_score_matching erro | Testar função diretamente via SQL |
| **Filial não carrega** | user_filiais_cnpj vazio | Inserir dados de teste em user_filiais_cnpj |
| **"Auth token expired"** | Session expirou | Implementar refresh token automático |

---

## 📊 PRÓXIMOS PASSOS APÓS IMPLEMENTAÇÃO

1. **Importar dados reais** via `import_getnet.py`
2. **Testar em produção** com Supabase
3. **Configurar notifications** (push, email)
4. **Implementar audit logs** (quem confirmou, quando)
5. **Setup CI/CD** para deploy automático

---

**Status Geral:** 🚀 PRONTO PARA IMPLEMENTAÇÃO

Data: 2026-04-27  
Validado por: Análise estrutural + padrões FlutterFlow v3.0
