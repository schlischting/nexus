import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/supabase_service.dart';
import '../models/vinculo.dart';
import '../components/match_suggestion.dart';
import '../components/dashboard_header.dart';

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard();

  @override
  _SupervisorDashboardState createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard>
    with SingleTickerProviderStateMixin {
  late SupabaseService _supabaseService;
  late TabController _tabController;
  List<Vinculo> _selectedMatches = [];

  @override
  void initState() {
    super.initState();
    _supabaseService = SupabaseService();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: DashboardHeader(
          filialNome: 'Todas',
          filialOptions: ['Todas'],
          onFilialChanged: (_) {},
          notificationCount: 10,
          onNotificationTap: () {},
          onProfileTap: () {},
          onLogoutTap: () async {
            await _supabaseService.logout();
            if (!mounted) return;
            context.go('/login');
          },
          userRole: 'supervisor',
        ),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '✅ Confirmados'),
              Tab(text: '🟡 Sugestões'),
              Tab(text: '🔴 Gaps'),
              Tab(text: '⚠️ Erros'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildConfirmadosTab(),
                _buildSugestoesTab(),
                _buildGapsTab(),
                _buildErrosTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmadosTab() {
    return StreamBuilder<List<Vinculo>>(
      stream: _supabaseService.streamSugestoesSupervisor(),
      builder: (context, snapshot) {
        final vinculos = snapshot.data ?? [];
        final confirmados = vinculos.where((v) => v.statusVinculo == 'confirmado').toList();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (confirmados.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    onPressed: () => _exportarParaTOTVS(confirmados),
                    icon: const Icon(Icons.download),
                    label: const Text(
                      'EXPORTAR ${confirmados.length} PARA TOTVS',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              Expanded(
                child: confirmados.isEmpty
                    ? const Center(child: Text('Nenhum match confirmado'))
                    : ListView.builder(
                        itemCount: confirmados.length,
                        itemBuilder: (context, index) {
                          final vinculo = confirmados[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                  'NSU: ${vinculo.transacaoGetnetId} → NF: ${vinculo.tituloTotvsId}'),
                              subtitle: Text(
                                  'Score: ${(vinculo.scoreConfianca * 100).toStringAsFixed(1)}% | Filial: ${vinculo.filialCnpj}'),
                              trailing: const Icon(Icons.check_circle,
                                  color: Color(0xFF10B981)),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSugestoesTab() {
    return StreamBuilder<List<Vinculo>>(
      stream: _supabaseService.streamSugestoesSupervisor(),
      builder: (context, snapshot) {
        final vinculos = snapshot.data ?? [];
        final sugestoes =
            vinculos.where((v) => v.statusVinculo == 'sugerido').toList();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: sugestoes.isEmpty
              ? const Center(child: Text('Nenhuma sugestão pendente'))
              : ListView.builder(
                  itemCount: sugestoes.length,
                  itemBuilder: (context, index) {
                    final vinculo = sugestoes[index];
                    return MatchSuggestionCard(
                      nsu: vinculo.transacaoGetnetId,
                      numeroNf: vinculo.tituloTotvsId ?? 'N/A',
                      valor: 'R\$ 0,00',
                      scoreConfianca: vinculo.scoreConfianca,
                      isAutomatic: false,
                      onConfirmar: () async {
                        await _supabaseService
                            .confirmarMatch(vinculo.vinculoId);
                        setState(() {});
                      },
                      onRejeitar: () async {
                        await _supabaseService
                            .rejeitarVinculo(vinculo.vinculoId);
                        setState(() {});
                      },
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildGapsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔴 Gaps sem Solução',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('NSUs sem título vinculado e sem sugestão (score < 0.75)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<Vinculo>>(
              stream: _supabaseService.streamSugestoesSupervisor(),
              builder: (context, snapshot) {
                final vinculos = snapshot.data ?? [];

                return ListView(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Filial 001: 5 gaps'),
                            const Text('Filial 002: 3 gaps'),
                            const Text('Filial 003: 8 gaps'),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {},
                              child: const Text('VER DETALHES'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrosTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ Erros de Baixa PASOE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('Tentativas de baixa que falharam no TOTVS'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                Card(
                  child: ListTile(
                    title: const Text('NSU: 000001234'),
                    subtitle: const Text(
                        'Erro: E001_TITULO_NAO_ENCONTRADO | Filial: 001'),
                    trailing: ElevatedButton(
                      onPressed: () {},
                      child: const Text('REPROCESSAR'),
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('NSU: 000001235'),
                    subtitle: const Text(
                        'Erro: E002_SALDO_INSUFICIENTE | Filial: 002'),
                    trailing: ElevatedButton(
                      onPressed: () {},
                      child: const Text('REPROCESSAR'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportarParaTOTVS(List<Vinculo> matches) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Exportando ${matches.length} matches para TOTVS...')),
      );

      // Simular envio
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('✅ ${matches.length} matches exportados com sucesso!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erro: $e')),
      );
    }
  }
}
