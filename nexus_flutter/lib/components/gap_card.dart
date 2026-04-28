import 'package:flutter/material.dart';

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
        return const Color(0xFFEF4444);
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'success':
        return const Color(0xFF10B981);
      case 'info':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF6B7280);
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: _getStatusColor(), width: 4),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                          '$_getStatusIcon() $title',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
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
              if (onTap != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
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
