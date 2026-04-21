import 'package:flutter/material.dart';
import '../../home/animal_category_model.dart';

class AnimalDetailTitle extends StatelessWidget {
  final Map<String, dynamic> animal;
  final AnimalCategory category;

  const AnimalDetailTitle({super.key, required this.animal, required this.category});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final nameVi = animal['name_vietnamese'] ?? 'Chưa có tên';
    final nameEn = animal['name_english'] ?? '';
    final scientificName = animal['scientific_name'] ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: category.gradient[0].withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              category.nameVi.toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: category.gradient[0], letterSpacing: 1.2),
            ),
          ),
          const SizedBox(height: 12),
          Text(nameVi, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: colorScheme.onSurface, height: 1.1, letterSpacing: -0.5)),
          if (nameEn.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(nameEn, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: category.gradient[0], letterSpacing: 0.1)),
          ],
          if (scientificName.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(scientificName, style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant.withOpacity(0.7), letterSpacing: 0.2)),
          ],
        ],
      ),
    );
  }
}