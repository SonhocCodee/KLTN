import 'package:flutter/material.dart';

class FactSwipeTopBar extends StatelessWidget {
  final int currentIndex;
  final int totalCount;
  final VoidCallback onClose;

  const FactSwipeTopBar({
    super.key,
    required this.currentIndex,
    required this.totalCount,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, color: colorScheme.onSurface),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Khám phá loài vật',
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Thẻ số ${currentIndex + 1} trên $totalCount',
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.inverseSurface, // Màu tương phản (đen ở light, trắng ở dark)
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${((currentIndex + 1) / totalCount * 100).toInt()}%',
              style: TextStyle(color: colorScheme.onInverseSurface, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}