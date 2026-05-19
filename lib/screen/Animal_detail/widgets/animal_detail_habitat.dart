import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../language/Locale_provider.dart';
import 'animal_detail_utils.dart';

class AnimalDetailHabitat extends StatelessWidget {
  final Map<String, dynamic> animal;

  const AnimalDetailHabitat({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    // Dịch giá trị môi trường sống trả về từ utils
    final habitat = t.tr(AnimalDetailUtils.translateValue('habitat', animal['primary_habitat'] ?? ''));
    final regions = (animal['geographic_regions'] as List? ?? []).join(', ');

    if (habitat.isEmpty) return const SizedBox.shrink();

    final rows = <Map<String, String>>[
      {'icon': '🌍', 'label': t.tr('Môi trường'), 'value': habitat},
      // Nếu các khu vực (regions) được thiết lập tĩnh, bạn cũng có thể bọc t.tr(regions)
      if (regions.isNotEmpty) {'icon': '📍', 'label': t.tr('Khu vực phân bổ'), 'value': regions},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimalDetailUtils.buildSectionTitle(t.tr('Môi trường sống'), '🌿', colorScheme),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14), border: Border.all(color: colorScheme.outlineVariant)),
          child: Column(
            children: rows.asMap().entries.map((e) => AnimalDetailUtils.buildTableRow(e.value['icon']!, e.value['label']!, e.value['value']!, e.key == rows.length - 1, colorScheme)).toList(),
          ),
        ),
      ],
    );
  }
}