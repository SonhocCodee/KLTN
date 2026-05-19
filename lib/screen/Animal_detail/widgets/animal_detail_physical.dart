import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../language/Locale_provider.dart';
import 'animal_detail_utils.dart';

class AnimalDetailPhysical extends StatelessWidget {
  final Map<String, dynamic> animal;

  const AnimalDetailPhysical({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    final colors = (animal['primary_colors'] as List? ?? []).map((c) => t.tr(AnimalDetailUtils.translateValue('color', c.toString()))).join(', ');
    final patterns = (animal['patterns'] as List? ?? []).map((p) => t.tr(AnimalDetailUtils.translateValue('pattern', p.toString()))).join(', ');
    final furType = t.tr(AnimalDetailUtils.translateValue('fur', animal['fur_type'] ?? ''));

    final rows = <Map<String, String>>[];
    if (colors.isNotEmpty) rows.add({'icon': '🎨', 'label': t.tr('Màu sắc'), 'value': colors});
    if (patterns.isNotEmpty) rows.add({'icon': '🦓', 'label': t.tr('Hoa văn'), 'value': patterns});
    if (furType.isNotEmpty) rows.add({'icon': '🧥', 'label': t.tr('Lông / da'), 'value': furType});

    final featureList = <String>[];
    if (animal['has_claws'] == true) featureList.add(t.tr('Móng vuốt sắc'));
    if (animal['has_sharp_teeth'] == true) featureList.add(t.tr('Nanh/răng sắc'));
    if (animal['has_tail'] == true) featureList.add(t.tr('Có đuôi'));
    if (animal['has_horns'] == true) featureList.add(t.tr('Có sừng'));

    if (featureList.isNotEmpty) {
      rows.add({'icon': '🦴', 'label': t.tr('Đặc điểm cơ thể'), 'value': featureList.join(' · ')});
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimalDetailUtils.buildSectionTitle(t.tr('Ngoại hình'), '👁️', colorScheme),
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