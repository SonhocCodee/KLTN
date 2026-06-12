import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../language/Locale_provider.dart';
import '../../../screen/SettingsScreen/provider/unit_provider.dart'; // 👈 thêm

class AnimalDetailQuickStats extends StatelessWidget {
  final Map<String, dynamic> animal;

  const AnimalDetailQuickStats({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();
    final u = context.watch<UnitProvider>(); // 👈 thêm

    final weightAvg = animal['weight_avg_kg'];
    final heightAvg = animal['height_avg_m'];
    final lifespanAvg = animal['lifespan_avg_years'];
    final maxSpeed = animal['max_speed_kmh'];

    final stats = <Map<String, dynamic>>[];

    if (weightAvg != null && (weightAvg as num) > 0)
      stats.add({
        'emoji': '⚖️',
        'value': u.formatWeight(weightAvg), // kg ↔ lbs
        'label': t.tr('Cân nặng'),
      });

    if (heightAvg != null && (heightAvg as num) > 0)
      stats.add({
        'emoji': '📏',
        'value': u.formatHeight(heightAvg), // m ↔ ft
        'label': t.tr('Chiều cao'),
      });

    if (lifespanAvg != null && (lifespanAvg as num) > 0)
      stats.add({
        'emoji': '🕰️',
        'value': '$lifespanAvg ${t.tr('năm')}',
        'label': t.tr('Tuổi thọ'),
      });

    if (maxSpeed != null && (maxSpeed as num) > 0)
      stats.add({
        'emoji': '💨',
        'value': u.formatSpeed(maxSpeed), // km/h ↔ mph
        'label': t.tr('Tốc độ tối đa'),
      });

    if (stats.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: stats.asMap().entries.map((entry) {
          final isLast = entry.key == stats.length - 1;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    entry.value['emoji'],
                    entry.value['value'],
                    entry.value['label'],
                    colorScheme,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 1,
                    height: 40,
                    color: colorScheme.outlineVariant,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatTile(
    String emoji,
    String value,
    String label,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
