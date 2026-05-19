import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../language/Locale_provider.dart';
import '../../home/animal_category_model.dart';

class BreedListSearchBar extends StatelessWidget {
  final AnimalCategory category;
  final String searchQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const BreedListSearchBar({
    super.key,
    required this.category,
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          onChanged: onChanged,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: '${t.tr('Tìm kiếm')} ${t.tr(category.nameVi).toLowerCase()}...',
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: category.gradient[0],
            ),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
              onPressed: onClear,
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }
}