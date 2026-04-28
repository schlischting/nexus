import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../models/transacao.dart';
import '../models/titulo.dart';
import '../models/vinculo.dart';
import '../components/gap_card.dart';
import '../components/dashboard_header.dart';

class OperadorDashboard extends StatefulWidget {
  final String filialCnpj;

  const OperadorDashboard({required this.filialCnpj});

  @override
  _OperadorDashboardState createState() => _OperadorDashboardState();
}

class _OperadorDashboardState extends State<OperadorDashboard> {
  late SupabaseService _supabaseService;
  bool _expandNsu = true;
  bool _expandErros = false;
  bool _expandTitulos = false;
  bool _expandConciliados = false;

  @override
  void initState() {
    super.initState();
    _supabaseService = SupabaseService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: DashboardHeader(
          filialNome: widget.filialCnpj,
          filialOptions: ['001', '002', '003'],
          onFilialChanged: (newFilial) {
            context.go('/operador/dashboard/$newFilial');
          },
          notificationCount: 5,
          onNotificationTap: () {},
          onProfileTap: () {},
          onLogoutTap: () async {
            await _supabaseService.logout();
            if (!mounted) return;
            context.go('/login');
          },
          userRole: 'operador_filial',
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // RESUMO DO DIA
            Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<Map<String, int>>(
                stream: Stream.periodic(
                  const Duration(seconds: 10),
                  (_) => _supabaseService.fetchMetricsOperador(widget.filialCnpj),
                ).asyncExpand((future) => Stream.fromFuture(future)),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final metrics = snapshot.data ?? {};
                  final nsuCount = metrics['nsu_sem_titulo'] ?? 0;
                  final tituloCount = metrics['titulo_sem_nsu'] ?? 0;
                  final conciliadosCount = metrics['confirmados'] ?? 0;

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: GapCard(
                              title: 'NSU SEM TÍTULO',
                              count: nsuCount,
                              status: 'critical',
                              description: 'Pendentes',
                              onTap: () =>
                                  setState(() => _expandNsu = !_expandNsu),
                              isExpanded: _expandNsu,
                            ),
                          ),
                          Expanded(
                            child: GapCard(
                              title: 'TÍTULOS SEM NSU',
                              count: tituloCount,
                              status: 'warning',
                              description: 'Abertos',
                              onTap: () =>
                                  setState(() => _expandTitulos = !_expandTitulos),
                              isExpanded: _expandTitulos,
                            ),
                          ),
                          Expanded(
                            child: GapCard(
                              title: 'CONCILIADOS',
                              count: conciliadosCount,
                              status: 'success',
                              description: 'Hoje',
                              onTap: () => setState(
                                  () => _expandConciliados = !_expandConciliados),
                              isExpanded: _expandConciliados,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            // SEÇÃO: NSU SEM TÍTULO
            if (_expandNsu)
              Padding(
                padding: const EdgeInsets.all(16),
                child: StreamBuilder<List<Transacao>>(
                  stream:
                      _supabaseService.streamNsuSemTitulo(widget.filialCnpj),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final nsuList = snapshot.data ?? [];

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🔴 NSU SEM TÍTULO',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            nsuList.isEmpty
                                ? const Text('Nenhum NSU pendente')
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: nsuList.length,
                                    itemBuilder: (context, index) {
                                      final nsu = nsuList[index];
                                      return ListTile(
                                        title: Text(nsu.nsu),
                                        subtitle: Text(
                                            'Valor: R\$ ${nsu.valorBruto.toStringAsFixed(2)} | Data: ${nsu.dataVenda.day}/${nsu.dataVenda.month}'),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () {
                                            context.go(
                                                '/operador/lancamento/${nsu.transacaoId}');
                                          },
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            // SEÇÃO: TÍTULOS SEM NSU
            if (_expandTitulos)
              Padding(
                padding: const EdgeInsets.all(16),
                child: StreamBuilder<List<Titulo>>(
                  stream:
                      _supabaseService.streamTituloSemNsu(widget.filialCnpj),
                  builder: (context, snapshot) {
                    final tituloList = snapshot.data ?? [];

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🟡 TÍTULOS SEM NSU',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            tituloList.isEmpty
                                ? const Text('Nenhum título sem NSU')
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: tituloList.length,
                                    itemBuilder: (context, index) {
                                      final titulo = tituloList[index];
                                      return ListTile(
                                        title: Text('NF: ${titulo.numeroNf}'),
                                        subtitle: Text(
                                            'Valor: R\$ ${titulo.valorBruto.toStringAsFixed(2)} | Vencimento: ${titulo.dataVencimento.day}/${titulo.dataVencimento.month}'),
                                        trailing: ElevatedButton(
                                          onPressed: () {
                                            context.go(
                                                '/operador/lancamento?nf=${titulo.numeroNf}');
                                          },
                                          child: const Text('Vincular'),
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/operador/lancamento');
        },
        backgroundColor: const Color(0xFF3B82F6),
        child: const Icon(Icons.add),
      ),
    );
  }
}
