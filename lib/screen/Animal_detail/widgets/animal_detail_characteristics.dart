import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../language/Locale_provider.dart';
import 'animal_detail_utils.dart';

class AnimalDetailCharacteristics extends StatelessWidget {
  final Map<String, dynamic> animal;

  const AnimalDetailCharacteristics({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    final traits = <Map<String, String>>[];
    if (animal['temperament'] != null) traits.add({'icon': '🎭', 'label': t.tr('Tính cách'), 'value': t.tr(AnimalDetailUtils.translateValue('temperament', animal['temperament']))});
    if (animal['social_structure'] != null) traits.add({'icon': '👥', 'label': t.tr('Cấu trúc xã hội'), 'value': t.tr(AnimalDetailUtils.translateValue('social', animal['social_structure']))});
    if (animal['activity_pattern'] != null) traits.add({'icon': '🌓', 'label': t.tr('Chu kỳ hoạt động'), 'value': t.tr(AnimalDetailUtils.translateValue('activity', animal['activity_pattern']))});
    if (animal['diet_type'] != null) traits.add({'icon': '🍽️', 'label': t.tr('Chế độ ăn'), 'value': t.tr(AnimalDetailUtils.translateValue('diet', animal['diet_type']))});
    if (animal['danger_to_humans'] != null) traits.add({'icon': '⚠️', 'label': t.tr('Mức độ nguy hiểm'), 'value': t.tr(AnimalDetailUtils.translateValue('danger', animal['danger_to_humans']))});

    if (traits.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimalDetailUtils.buildSectionTitle(t.tr('Đặc điểm & Hành vi'), '🔬', colorScheme),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14), border: Border.all(color: colorScheme.outlineVariant)),
          child: Column(
            children: traits.asMap().entries.map((entry) => AnimalDetailUtils.buildTableRow(entry.value['icon']!, entry.value['label']!, entry.value['value']!, entry.key == traits.length - 1, colorScheme)).toList(),
          ),
        ),
      ],
    );
  }
}