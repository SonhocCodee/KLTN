import 'package:flutter/material.dart';
import 'animal_detail_utils.dart';

class AnimalDetailTaxonomy extends StatelessWidget {
  final Map<String, dynamic> animal;

  const AnimalDetailTaxonomy({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = <Map<String, String>>[];
    if (animal['kingdom'] != null) items.add({'icon': '🌐', 'label': 'Giới', 'value': animal['kingdom']});
    if (animal['phylum'] != null) items.add({'icon': '🔗', 'label': 'Ngành', 'value': animal['phylum']});
    if (animal['class'] != null) items.add({'icon': '📦', 'label': 'Lớp', 'value': animal['class']});
    if (animal['order_name'] != null) items.add({'icon': '📂', 'label': 'Bộ', 'value': animal['order_name']});
    if (animal['family'] != null) items.add({'icon': '🏷️', 'label': 'Họ', 'value': animal['family']});
    if (animal['genus'] != null) items.add({'icon': '🔍', 'label': 'Chi', 'value': animal['genus']});

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimalDetailUtils.buildSectionTitle('Phân loại khoa học', '🔭', colorScheme),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14), border: Border.all(color: colorScheme.outlineVariant)),
          child: Column(
            children: items.asMap().entries.map((entry) => _buildTaxonomyRow(entry.value['icon']!, entry.value['label']!, entry.value['value']!, entry.key, entry.key == items.length - 1, colorScheme)).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text('Nguồn: Hệ thống phân loại sinh vật học hiện đại', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant.withOpacity(0.7), fontStyle: FontStyle.italic)),
        ),
      ],
    );
  }

  Widget _buildTaxonomyRow(String icon, String rank, String name, int depth, bool isLast, ColorScheme colorScheme) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16.0 + depth * 4.0, right: 16, top: 12, bottom: 12),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 10),
              Text(rank, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
              const Spacer(),
              Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontStyle: depth >= 5 ? FontStyle.italic : FontStyle.normal, color: colorScheme.onSurface)),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, indent: 16.0 + (depth + 1) * 4.0, color: colorScheme.outlineVariant),
      ],
    );
  }
}