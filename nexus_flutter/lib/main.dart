import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/supabase_service.dart';
import 'screens/operador_dashboard.dart';
import 'screens/lancamento_nsu.dart';
import 'screens/supervisor_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carregar variáveis de ambiente
  await dotenv.load(fileName: '.env');

  // Inicializar Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? SupabaseConfig.url,
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? SupabaseConfig.anonKey,
  );

  // Inicializar SupabaseService
  SupabaseService().client = Supabase.instance.client;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'NEXUS — Conciliação GETNET + TOTVS',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.light,
        ),
        typography: Typography.material2021(
          englishLike: const EnglishLike(fallback: 'Roboto'),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F2937),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF3B82F6),
          foregroundColor: Colors.white,
        ),
      ),
      home: const LoginPage(),
    );
  }
}

// ============================================================================
// Router Configuration
// ============================================================================

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/operador/dashboard/:filialCnpj',
      builder: (context, state) => OperadorDashboard(
        filialCnpj: state.pathParameters['filialCnpj'] ?? '001',
      ),
    ),
    GoRoute(
      path: '/operador/lancamento',
      builder: (context, state) => const LancamentoNsu(),
    ),
    GoRoute(
      path: '/operador/lancamento/:nsuId',
      builder: (context, state) => LancamentoNsu(
        nsuId: state.pathParameters['nsuId'],
      ),
    ),
    GoRoute(
      path: '/supervisor/dashboard',
      builder: (context, state) => const SupervisorDashboard(),
    ),
  ],
);

// ============================================================================
// Login Page
// ============================================================================

class LoginPage extends StatefulWidget {
  const LoginPage();

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabaseService = SupabaseService();
      final success = await supabaseService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success) {
        // Buscar role do usuário
        final userRole = await supabaseService.client
            .from('user_filiais_cnpj')
            .select('perfil_usuario, filial_cnpj')
            .eq('user_id', supabaseService.currentUser!.id)
            .limit(1)
            .single()
            .then((data) => data);

        if (!mounted) return;

        if (userRole['perfil_usuario'] == 'supervisor') {
          context.go('/supervisor/dashboard');
        } else {
          final filialCnpj = userRole['filial_cnpj'] ?? '001';
          context.go('/operador/dashboard/$filialCnpj');
        }
      } else {
        setState(() => _errorMessage = 'Falha ao fazer login');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erro: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2937),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'NEXUS',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Conciliação de Cartões',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 48),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEF4444)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    filled: true,
                    fillColor: const Color(0xFF374151),
                    labelStyle: const TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    filled: true,
                    fillColor: const Color(0xFF374151),
                    labelStyle: const TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Entrar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 24),
                const Text(
                  'Usuários de teste:\noperador@filial001.com / 123456\nsupervisor@nexus.com / 123456',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
