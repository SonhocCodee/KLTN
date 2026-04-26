import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dentify_history_screen.dart';
import '../service/Identify_service.dart';


class IdentifyHeader extends StatelessWidget {
  final IdentifyService service;
  const IdentifyHeader({super.key, required this.service});

  static const _accentOrange = Color(0xFFEF6C00);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Camera Thú Vị',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.pets_rounded, color: _accentOrange, size: 28),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Khám phá thế giới động vật qua ống kính',
                  style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          // ── Nút lịch sử ──────────────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: service,
                  child: const IdentifyHistoryScreen(),
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _accentOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accentOrange.withOpacity(0.3), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.history_rounded, size: 20, color: _accentOrange),
                      // Badge số lượng lịch sử
                      if (service.historyItems.isNotEmpty)
                        Positioned(
                          top: -4,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                            decoration: const BoxDecoration(color: _accentOrange, shape: BoxShape.circle),
                            child: Text(
                              service.historyItems.length > 99 ? '99+' : '${service.historyItems.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Lịch sử',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _accentOrange),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}