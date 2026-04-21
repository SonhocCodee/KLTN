import 'package:flutter/material.dart';
import 'animal_detail_utils.dart';

class AnimalDetailDescription extends StatelessWidget {
  final Map<String, dynamic> animal;

  const AnimalDetailDescription({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final description = animal['description_short'] ?? '';
    final funFact = animal['fun_fact_vietnamese'] ?? '';
    final finalDesc = description.isNotEmpty ? description : AnimalDetailUtils.generateDescription(animal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimalDetailUtils.buildSectionTitle('Giới thiệu', '📖', colorScheme),
        const SizedBox(height: 14),
        if (finalDesc.isNotEmpty) ...[
          Text(finalDesc, style: TextStyle(fontSize: 15, height: 1.75, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
        ],
        if (funFact.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.secondary.withOpacity(0.3), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Có thể bạn chưa biết', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.secondary, letterSpacing: 0.3)),
                      const SizedBox(height: 5),
                      Text(funFact, style: TextStyle(fontSize: 14, color: colorScheme.onSecondaryContainer, height: 1.6)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}