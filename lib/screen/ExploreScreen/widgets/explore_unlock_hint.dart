import 'package:flutter/material.dart';
import '../explore_service.dart';

class ExploreUnlockHint extends StatelessWidget {
  final ExploreService service;

  const ExploreUnlockHint({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Wrap(
            spacing: 5,
            children: List.generate(10, (i) {
              return Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: i < service.readCount
                      ? colorScheme.primary
                      : colorScheme.outlineVariant, // Chấm xám khi chưa đọc
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                children: [
                  const TextSpan(text: 'Đọc thêm '),
                  TextSpan(
                    text: '${service.remainingFacts} facts nữa ',
                    style: TextStyle(
                      color: colorScheme.primary, fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: 'để mở khoá Đố vui!'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}