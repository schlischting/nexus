import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/supabase_service.dart';
import '../models/transacao.dart';
import '../models/titulo.dart';

class LancamentoNsu extends StatefulWidget {
  final String? nsuId;

  const LancamentoNsu({this.nsuId});

  @override
  _LancamentoNsuState createState() => _LancamentoNsuState();
}

class _LancamentoNsuState extends State<LancamentoNsu> {
  int _currentStep = 0;
  late SupabaseService _supabaseService;

  final _nsuController = TextEditingController();
  final _nfController = TextEditingController();
  final _modalidadeController = TextEditingController(text: 'credito');
  final _parcelasController = TextEditingController(text: '1');

  Transacao? _selectedNsu;
  Titulo? _selectedTitulo;
  double _scoreConfianca = 0.0;
  bool _isCalculating = false;

  List<Transacao> _nsuSuggestions = [];
  List<Titulo> _tituloSuggestions = [];

  @override
  void initState() {
    super.initState();
    _supabaseService = SupabaseService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lançamento NSU + NF'),
        backgroundColor: const Color(0xFF1F2937),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          } else {
            context.pop();
          }
        },
        steps: [
          // STEP 1: Buscar NSU
          Step(
            title: const Text('1. Buscar NSU'),
            isActive: _currentStep >= 0,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nsuController,
                  decoration: InputDecoration(
                    labelText: 'Número NSU',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) async {
                    if (value.length > 2) {
                      final filialCnpj =
                          _supabaseService.currentUser?.email ?? '';
                      final suggestions =
                          await _supabaseService.buscarNsu(value, filialCnpj);
                      setState(() => _nsuSuggestions = suggestions);
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (_nsuSuggestions.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _nsuSuggestions.length,
                      itemBuilder: (context, index) {
                        final nsu = _nsuSuggestions[index];
                        return ListTile(
                          title: Text(nsu.nsu),
                          subtitle: Text(
                              'R\$ ${nsu.valorBruto.toStringAsFixed(2)} - ${nsu.dataVenda.day}/${nsu.dataVenda.month}'),
                          onTap: () {
                            setState(() {
                              _selectedNsu = nsu;
                              _nsuController.text = nsu.nsu;
                              _nsuSuggestions = [];
                            });
                          },
                        );
                      },
                    ),
                  ),
                if (_selectedNsu != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NSU Selecionado:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(_selectedNsu!.nsu),
                          Text(
                              'Valor: R\$ ${_selectedNsu!.valorBruto.toStringAsFixed(2)}'),
                          Text(
                              'Data: ${_selectedNsu!.dataVenda.day}/${_selectedNsu!.dataVenda.month}/${_selectedNsu!.dataVenda.year}'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // STEP 2: Selecionar NF
          Step(
            title: const Text('2. Selecionar NF'),
            isActive: _currentStep >= 1,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nfController,
                  decoration: InputDecoration(
                    labelText: 'Número NF',
                    prefixIcon: const Icon(Icons.receipt),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) async {
                    if (value.length > 2 && _selectedNsu != null) {
                      final suggestions = await _supabaseService
                          .buscarTitulosPorNf(value, _selectedNsu!.filialCnpj);
                      setState(() => _tituloSuggestions = suggestions);
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (_tituloSuggestions.isNotEmpty)
                  const Text(
                    'Títulos disponíveis:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                if (_tituloSuggestions.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _tituloSuggestions.length,
                    itemBuilder: (context, index) {
                      final titulo = _tituloSuggestions[index];
                      final isSelected =
                          _selectedTitulo?.tituloId == titulo.tituloId;
                      return RadioListTile<String>(
                        title: Text('NF: ${titulo.numeroNf}'),
                        subtitle: Text(
                            'R\$ ${titulo.valorBruto.toStringAsFixed(2)} - Venc: ${titulo.dataVencimento.day}/${titulo.dataVencimento.month}'),
                        value: titulo.tituloId,
                        groupValue:
                            isSelected ? titulo.tituloId : 'none',
                        onChanged: (value) {
                          setState(() => _selectedTitulo = titulo);
                        },
                      );
                    },
                  ),
                const SizedBox(height: 16),
                const Text('Modalidade:'),
                DropdownButton<String>(
                  value: _modalidadeController.text,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'credito', child: Text('Crédito')),
                    DropdownMenuItem(value: 'debito', child: Text('Débito')),
                  ],
                  onChanged: (value) {
                    setState(() =>
                        _modalidadeController.text = value ?? 'credito');
                  },
                ),
                const SizedBox(height: 16),
                const Text('Quantidade de Parcelas:'),
                TextField(
                  controller: _parcelasController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '1-12',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // STEP 3: Confirmar
          Step(
            title: const Text('3. Confirmar'),
            isActive: _currentStep >= 2,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_scoreConfianca > 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _scoreConfianca >= 0.95
                          ? const Color(0xFF10B981).withOpacity(0.1)
                          : const Color(0xFFF59E0B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _scoreConfianca >= 0.95
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Score de Confiança: ${(_scoreConfianca * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _scoreConfianca,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFE5E7EB),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _scoreConfianca >= 0.95
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  _scoreConfianca >= 0.95
                      ? '✅ Match automático aprovado'
                      : _scoreConfianca >= 0.75
                          ? '🟡 Sugestão para validação'
                          : '❌ Score insuficiente',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _scoreConfianca >= 0.95
                        ? const Color(0xFF10B981)
                        : _scoreConfianca >= 0.75
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onStepContinue() async {
    if (_currentStep == 0) {
      if (_selectedNsu == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione um NSU')),
        );
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 1) {
      if (_selectedTitulo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione um título')),
        );
        return;
      }

      setState(() => _isCalculating = true);

      final score = await _supabaseService.client.rpc(
        'calcular_score_matching',
        params: {
          'p_valor_getnet': _selectedNsu!.valorBruto,
          'p_valor_totvs': _selectedTitulo!.valorBruto,
          'p_data_getnet': _selectedNsu!.dataVenda.toIso8601String(),
          'p_data_totvs': _selectedTitulo!.dataVencimento.toIso8601String(),
        },
      );

      setState(() {
        _scoreConfianca = (score as num).toDouble();
        _currentStep++;
        _isCalculating = false;
      });
    } else if (_currentStep == 2) {
      await _confirmMatch();
    }
  }

  Future<void> _confirmMatch() async {
    try {
      final result = await _supabaseService.criarVinculo(
        nsuId: _selectedNsu!.transacaoId,
        tituloId: _selectedTitulo!.tituloId,
        filialCnpj: _selectedNsu!.filialCnpj,
        modalidade: _modalidadeController.text,
        parcelas: int.parse(_parcelasController.text),
      );

      if (result != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Vínculo criado com sucesso!')),
        );
        context.go('/operador/dashboard/${_selectedNsu!.filialCnpj}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erro: $e')),
      );
    }
  }
}
