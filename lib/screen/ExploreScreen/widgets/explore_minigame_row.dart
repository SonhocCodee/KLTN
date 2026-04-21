import 'package:flutter/material.dart';
import '../explore_service.dart';

class ExploreMinigameRow extends StatelessWidget {
  final ExploreService service;
  final VoidCallback onQuizTap;

  const ExploreMinigameRow({super.key, required this.service, required this.onQuizTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(child: _buildQuizCard(context, service, onQuizTap)),
          const SizedBox(width: 12),
          Expanded(child: _buildGuessCard(context)),
          const SizedBox(width: 12),
          Expanded(child: _buildSoonCard(context)),
        ],
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context, ExploreService service, VoidCallback onQuizTap) {
    final colorScheme = Theme.of(context).colorScheme;
    final locked = !service.isQuizUnlocked;

    return GestureDetector(
      onTap: locked ? null : onQuizTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: locked ? colorScheme.surface : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: locked
                        ? colorScheme.surfaceContainerHighest
                        : colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('🧠', style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(height: 10),
                Text(
                  'Đố vui',
                  style: TextStyle(
                    color: locked ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                    fontSize: 14, fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quiz từ facts hôm nay',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11, height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (locked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        border: Border.all(color: colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text('🔒', style: TextStyle(fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Đọc đủ\n10 facts',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600, height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGuessCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đoán ảnh — sắp ra mắt!')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.surfaceContainerHighest, colorScheme.surfaceContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('🔍', style: TextStyle(fontSize: 20))),
            ),
            const SizedBox(height: 10),
            Text(
              'Đoán ảnh',
              style: TextStyle(color: colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Nhận diện qua hình',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoonCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: 0.5,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('🎯', style: TextStyle(fontSize: 20))),
                ),
                Positioned(
                  top: -4, right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Sắp ra',
                      style: TextStyle(fontSize: 8, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Phân loại',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Loại nào đúng?',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}