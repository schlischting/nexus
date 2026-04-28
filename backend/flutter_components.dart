// Componentes Reutilizáveis para FlutterFlow - Nexus v3.0
// Data: 2026-04-27
// Uso: Copiar/colar no FlutterFlow ou em projeto Flutter nativo

import 'package:flutter/material.dart';

// ============================================================================
// 1. GapCard — Card com status colorido (🔴🟡✅)
// ============================================================================

class GapCard extends StatelessWidget {
  final String title;
  final int count;
  final String status; // 'critical' | 'warning' | 'success' | 'info'
  final String description;
  final VoidCallback? onTap;
  final bool isExpanded;

  const GapCard({
    required this.title,
    required this.count,
    required this.status,
    required this.description,
    this.onTap,
    this.isExpanded = false,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'critical':
        return Color(0xFFEF4444); // 🔴 red-600
      case 'warning':
        return Color(0xFFF59E0B); // 🟡 amber-500
      case 'success':
        return Color(0xFF10B981); // ✅ green-600
      case 'info':
        return Color(0xFF3B82F6); // ℹ️ blue-600
      default:
        return Color(0xFF6B7280); // gray-600
    }
  }

  String _getStatusIcon() {
    switch (status) {
      case 'critical':
        return '🔴';
      case 'warning':
        return '🟡';
      case 'success':
        return '✅';
      case 'info':
        return 'ℹ️';
      default:
        return '⚫';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: _getStatusColor(), width: 4),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getStatusIcon()} $title',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (onTap != null)
                Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: GestureDetector(
                    onTap: onTap,
                    child: Text(
                      isExpanded ? '[Recolher]' : '[Expandir]',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w600,
                      ),
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

// ============================================================================
// 2. MatchSuggestionCard — Card com score + botões de ação
// ============================================================================

class MatchSuggestionCard extends StatelessWidget {
  final String nsu;
  final String numeroNf;
  final String valor;
  final double scoreConfianca; // 0.0 - 1.0
  final bool isAutomatic;
  final VoidCallback onConfirmar;
  final VoidCallback onRejeitar;

  const MatchSuggestionCard({
    required this.nsu,
    required this.numeroNf,
    required this.valor,
    required this.scoreConfianca,
    required this.isAutomatic,
    required this.onConfirmar,
    required this.onRejeitar,
  });

  Color _getScoreColor() {
    if (scoreConfianca >= 0.95) {
      return Color(0xFF10B981); // 🟢 green — auto-confirm
    } else if (scoreConfianca >= 0.75) {
      return Color(0xFFF59E0B); // 🟡 amber — review
    } else {
      return Color(0xFFEF4444); // 🔴 red — reject
    }
  }

  String _getScoreLabel() {
    if (scoreConfianca >= 0.95) {
      return '🟢 Excelente match automático';
    } else if (scoreConfianca >= 0.75) {
      return '🟡 Sugestão (validar)';
    } else {
      return '🔴 Score baixo (rejeitar)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NSU: $nsu',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'NF: $numeroNf',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getScoreColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getScoreColor().withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getScoreLabel(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getScoreColor(),
                        ),
                      ),
                      Text(
                        '${(scoreConfianca * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getScoreColor(),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: scoreConfianca,
                      minHeight: 6,
                      backgroundColor: Color(0xFFE5E7EB),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_getScoreColor()),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: onRejeitar,
                  icon: Icon(Icons.close, size: 16),
                  label: Text('Rejeitar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onConfirmar,
                  icon: Icon(Icons.check, size: 16),
                  label: Text('Confirmar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getScoreColor(),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 3. DashboardHeader — Header com seletor de filial e filtros
// ============================================================================

class DashboardHeader extends StatelessWidget {
  final String filialNome;
  final List<String> filialOptions; // ['001', '002', '003']
  final Function(String) onFilialChanged;
  final int notificationCount;
  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;
  final VoidCallback onLogoutTap;
  final String userRole; // 'operador_filial' | 'supervisor' | 'admin'

  const DashboardHeader({
    required this.filialNome,
    required this.filialOptions,
    required this.onFilialChanged,
    required this.notificationCount,
    required this.onNotificationTap,
    required this.onProfileTap,
    required this.onLogoutTap,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF1F2937),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NEXUS',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(Icons.notifications, color: Colors.white),
                        onPressed: onNotificationTap,
                      ),
                      if (notificationCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                            child: Text(
                              notificationCount.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.person, color: Colors.white),
                    onPressed: onProfileTap,
                  ),
                  IconButton(
                    icon: Icon(Icons.logout, color: Colors.white),
                    onPressed: onLogoutTap,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: filialNome,
                  isExpanded: true,
                  dropdownColor: Color(0xFF374151),
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  underline: Container(height: 1, color: Color(0xFF4B5563)),
                  onChanged: (String? value) {
                    if (value != null) onFilialChanged(value);
                  },
                  items: filialOptions.map<DropdownMenuItem<String>>((value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text('Filial: $value'),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(width: 16),
              Text(
                '📍 ${userRole == 'supervisor' ? 'Supervisor' : 'Operador'}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. Utility Extension — Formatadores
// ============================================================================

extension StringFormatters on String {
  String formatCurrency() {
    // Converte "1500" em "R$ 1.500,00"
    try {
      double value = double.parse(this);
      return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',').replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}';
    } catch (e) {
      return this;
    }
  }

  String formatDate() {
    // Converte "2026-04-27" em "27/04/2026"
    try {
      DateTime date = DateTime.parse(this);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return this;
    }
  }
}
