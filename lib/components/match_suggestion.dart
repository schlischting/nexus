import 'package:flutter/material.dart';

class MatchSuggestionCard extends StatelessWidget {
  final String nsu;
  final String numeroNf;
  final String valor;
  final double scoreConfianca;
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
      return const Color(0xFF10B981);
    } else if (scoreConfianca >= 0.75) {
      return const Color(0xFFF59E0B);
    } else {
      return const Color(0xFFEF4444);
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'NF: $numeroNf',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: scoreConfianca,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_getScoreColor()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: onRejeitar,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Rejeitar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onConfirmar,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Confirmar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getScoreColor(),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
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
