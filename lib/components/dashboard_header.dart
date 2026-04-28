import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  final String filialNome;
  final List<String> filialOptions;
  final Function(String) onFilialChanged;
  final int notificationCount;
  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;
  final VoidCallback onLogoutTap;
  final String userRole;

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
      color: const Color(0xFF1F2937),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
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
                        icon: const Icon(Icons.notifications,
                            color: Colors.white),
                        onPressed: onNotificationTap,
                      ),
                      if (notificationCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                                minWidth: 18, minHeight: 18),
                            child: Text(
                              notificationCount.toString(),
                              style: const TextStyle(
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
                    icon: const Icon(Icons.person, color: Colors.white),
                    onPressed: onProfileTap,
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: onLogoutTap,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: filialNome,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF374151),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  underline: Container(
                      height: 1, color: const Color(0xFF4B5563)),
                  onChanged: (String? value) {
                    if (value != null) onFilialChanged(value);
                  },
                  items: filialOptions
                      .map<DropdownMenuItem<String>>((value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text('Filial: $value'),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                userRole == 'supervisor'
                    ? '📍 Supervisor'
                    : '📍 Operador',
                style: const TextStyle(
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
