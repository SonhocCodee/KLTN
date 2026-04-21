import 'package:flutter/material.dart';

class QuizTopBar extends StatelessWidget {
  final int currentIndex;
  final int total;
  final int correctCount;
  final bool hasAnswered;

  const QuizTopBar({
    super.key,
    required this.currentIndex,
    required this.total,
    required this.correctCount,
    required this.hasAnswered,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final successColor = isDark ? Colors.green.shade400 : Colors.green.shade700;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Icon(Icons.close_rounded, color: colorScheme.onSurface, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đố vui',
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Câu ${currentIndex + 1} / $total',
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          // Score indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: successColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: successColor.withOpacity(0.3)),
            ),
            child: Text(
              '$correctCount / ${currentIndex + (hasAnswered ? 1 : 0)}',
              style: TextStyle(
                color: successColor, fontSize: 13, fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}