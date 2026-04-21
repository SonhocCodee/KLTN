import 'package:flutter/material.dart';
import 'animal_detail_utils.dart';

class AnimalDetailPhysical extends StatelessWidget {
  final Map<String, dynamic> animal;

  const AnimalDetailPhysical({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = (animal['primary_colors'] as List? ?? []).map((c) => AnimalDetailUtils.translateValue('color', c.toString())).join(', ');
    final patterns = (animal['patterns'] as List? ?? []).map((p) => AnimalDetailUtils.translateValue('pattern', p.toString())).join(', ');
    final furType = AnimalDetailUtils.translateValue('fur', animal['fur_type'] ?? '');

    final rows = <Map<String, String>>[];
    if (colors.isNotEmpty) rows.add({'icon': '🎨', 'label': 'Màu sắc', 'value': colors});
    if (patterns.isNotEmpty) rows.add({'icon': '🦓', 'label': 'Hoa văn', 'value': patterns});
    if (furType.isNotEmpty) rows.add({'icon': '🧥', 'label': 'Lông / da', 'value': furType});

    final featureList = <String>[];
    if (animal['has_claws'] == true) featureList.add('Móng vuốt sắc');
    if (animal['has_sharp_teeth'] == true) featureList.add('Nanh/răng sắc');
    if (animal['has_tail'] == true) featureList.add('Có đuôi');
    if (animal['has_horns'] == true) featureList.add('Có sừng');
    if (featureList.isNotEmpty) rows.add({'icon': '🦴', 'label': 'Đặc điểm cơ thể', 'value': featureList.join(' · ')});

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimalDetailUtils.buildSectionTitle('Ngoại hình', '👁️', colorScheme),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14), border: Border.all(color: colorScheme.outlineVariant)),
          child: Column(
            children: rows.asMap().entries.map((entry) => AnimalDetailUtils.buildTableRow(entry.value['icon']!, entry.value['label']!, entry.value['value']!, entry.key == rows.length - 1, colorScheme)).toList(),
          ),
        ),
      ],
    );
  }
}