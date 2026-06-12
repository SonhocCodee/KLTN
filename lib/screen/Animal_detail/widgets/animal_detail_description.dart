import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../language/Locale_provider.dart';
import 'animal_detail_utils.dart';

class AnimalDetailDescription extends StatelessWidget {
  final Map<String, dynamic> animal;

  const AnimalDetailDescription({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    // Description
    // Ưu tiên: [EN] description_english -> dự phòng description_short (tiếng Việt)
    // [VI] description_short
    final String description;
    if (t.isEnglish) {
      final en = (animal['description_english'] as String? ?? '').trim();
      description = en.isNotEmpty
          ? en
          : (animal['description_short'] as String? ?? '').trim();
    } else {
      description = (animal['description_short'] as String? ?? '').trim();
    }

    final String finalDesc = description.isNotEmpty
        ? description
        : AnimalDetailUtils.generateDescription(animal, t);

    // Fun fact
    // Ưu tiên: [EN] fun_fact_english -> dự phòng fun_fact_vietnamese
    // [VI] fun_fact_vietnamese
    final String funFact;
    if (t.isEnglish) {
      final en = (animal['fun_fact_english'] as String? ?? '').trim();
      funFact = en.isNotEmpty
          ? en
          : (animal['fun_fact_vietnamese'] as String? ?? '').trim();
    } else {
      funFact = (animal['fun_fact_vietnamese'] as String? ?? '').trim();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimalDetailUtils.buildSectionTitle(
          t.tr('Giới thiệu'),
          '📖',
          colorScheme,
        ),
        const SizedBox(height: 14),

        // Description
        if (finalDesc.isNotEmpty) ...[
          Text(
            finalDesc,
            style: TextStyle(
              fontSize: 15,
              height: 1.75,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Fun fact box
        if (funFact.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.secondary.withOpacity(0.3),
                width: 1,
              ),
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
                      Text(
                        t.tr('Có thể bạn chưa biết'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.secondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        funFact,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSecondaryContainer,
                          height: 1.6,
                        ),
                      ),
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
