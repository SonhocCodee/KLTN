import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../language/Locale_provider.dart';
import '../explore_service.dart';

class ExploreStats extends StatelessWidget {
  final ExploreService service;

  const ExploreStats({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _statCard(
            context,
            '${service.totalFactsRead}',
            t.tr('Facts đã đọc'),
            colorScheme.primary,
          ),
          const SizedBox(width: 10),
          _statCard(
            context,
            '${service.quizCorrectPct}%',
            t.tr('Quiz đúng'),
            const Color(0xFF22C55E),
          ),
          const SizedBox(width: 10),
          _statCard(
            context,
            '${service.totalSpecies}',
            t.tr('Loài khám phá'),
            const Color(0xFFF97316),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      BuildContext context, String value, String label, Color color) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}