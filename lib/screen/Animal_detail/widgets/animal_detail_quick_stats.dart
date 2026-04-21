import 'package:flutter/material.dart';

class AnimalDetailQuickStats extends StatelessWidget {
  final Map<String, dynamic> animal;

  const AnimalDetailQuickStats({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final weightAvg = animal['weight_avg_kg'] ?? 0;
    final heightAvg = animal['height_avg_m'] ?? 0;
    final lifespanAvg = animal['lifespan_avg_years'] ?? 0;
    final maxSpeed = animal['max_speed_kmh'] ?? 0;

    final stats = <Map<String, dynamic>>[];
    if (weightAvg > 0) stats.add({'emoji': '⚖️', 'value': '${weightAvg.toStringAsFixed(0)} kg', 'label': 'Cân nặng'});
    if (heightAvg > 0) stats.add({'emoji': '📏', 'value': '${heightAvg.toStringAsFixed(1)} m', 'label': 'Chiều cao'});
    if (lifespanAvg > 0) stats.add({'emoji': '🕰️', 'value': '$lifespanAvg năm', 'label': 'Tuổi thọ'});
    if (maxSpeed > 0) stats.add({'emoji': '💨', 'value': '$maxSpeed km/h', 'label': 'Tốc độ tối đa'});

    if (stats.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: stats.asMap().entries.map((entry) {
          final isLast = entry.key == stats.length - 1;
          return Expanded(
            child: Row(
              children: [
                Expanded(child: _buildStatTile(entry.value['emoji'], entry.value['value'], entry.value['label'], colorScheme)),
                if (!isLast) Container(width: 1, height: 40, color: colorScheme.outlineVariant, margin: const EdgeInsets.symmetric(horizontal: 4)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatTile(String emoji, String value, String label, ColorScheme colorScheme) {
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
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colorScheme.onSurface), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}