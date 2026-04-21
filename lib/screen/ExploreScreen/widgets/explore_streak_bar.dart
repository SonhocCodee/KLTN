import 'package:flutter/material.dart';
import '../explore_service.dart';

class ExploreStreakBar extends StatelessWidget {
  final ExploreService service;

  const ExploreStreakBar({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF4757)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('🔥', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${service.streakDays} ngày liên tiếp',
                  style: TextStyle(
                    color: colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  service.streakDays > 0
                      ? 'Đừng để mất chuỗi nhé!'
                      : 'Bắt đầu chuỗi ngày hôm nay!',
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1), // Chuyển sang opacity để tương thích Dark Mode
              border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+${service.streakDays}',
              style: const TextStyle(
                color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}