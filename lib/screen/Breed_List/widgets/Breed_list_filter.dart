import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../language/Locale_provider.dart';
import '../../home/animal_category_model.dart';

// Model chứa trạng thái bộ lọc
enum SortField {
  nameAZ,
  nameZA,
  weightAsc,
  weightDesc,
  lifespanAsc,
  lifespanDesc,
}

class AnimalFilterState {
  final SortField sortField;
  final String? relativeSize;
  final String? dietType;
  final String? conservationStatus;
  final bool showOnlyFavorites;

  const AnimalFilterState({
    this.sortField = SortField.nameAZ,
    this.relativeSize,
    this.dietType,
    this.conservationStatus,
    this.showOnlyFavorites = false,
  });

  AnimalFilterState copyWith({
    SortField? sortField,
    Object? relativeSize = _sentinel,
    Object? dietType = _sentinel,
    Object? conservationStatus = _sentinel,
    bool? showOnlyFavorites,
  }) {
    return AnimalFilterState(
      sortField: sortField ?? this.sortField,
      relativeSize: relativeSize == _sentinel
          ? this.relativeSize
          : relativeSize as String?,
      dietType: dietType == _sentinel ? this.dietType : dietType as String?,
      conservationStatus: conservationStatus == _sentinel
          ? this.conservationStatus
          : conservationStatus as String?,
      showOnlyFavorites: showOnlyFavorites ?? this.showOnlyFavorites,
    );
  }

  static const _sentinel = Object();

  bool get hasActiveFilters =>
      relativeSize != null ||
      dietType != null ||
      conservationStatus != null ||
      showOnlyFavorites;

  int get activeFilterCount =>
      [
        relativeSize,
        dietType,
        conservationStatus,
      ].where((e) => e != null).length +
      (showOnlyFavorites ? 1 : 0);

  // Áp dụng sort + filter lên danh sách
  // [favoriteIds] cần truyền vào khi showOnlyFavorites = true
  List<Map<String, dynamic>> apply(
    List<Map<String, dynamic>> animals, {
    Set<String> favoriteIds = const {},
  }) {
    var list = [...animals];

    // Filter yêu thích
    if (showOnlyFavorites) {
      list = list
          .where((a) => favoriteIds.contains(a['id'].toString()))
          .toList();
    }

    // Filter theo relative_size
    if (relativeSize != null) {
      list = list.where((a) => a['relative_size'] == relativeSize).toList();
    }
    // Filter theo diet_type
    if (dietType != null) {
      list = list.where((a) {
        final v = (a['diet_type'] ?? '').toString().toLowerCase();
        return v == dietType!.toLowerCase();
      }).toList();
    }
    // Filter theo conservation_status
    if (conservationStatus != null) {
      list = list.where((a) {
        final v = (a['conservation_status'] ?? '').toString().toLowerCase();
        return v.contains(conservationStatus!.toLowerCase());
      }).toList();
    }

    // Sort
    list.sort((a, b) {
      switch (sortField) {
        case SortField.nameAZ:
          return _str(
            a['name_vietnamese'],
          ).compareTo(_str(b['name_vietnamese']));
        case SortField.nameZA:
          return _str(
            b['name_vietnamese'],
          ).compareTo(_str(a['name_vietnamese']));
        case SortField.weightAsc:
          return _num(a['weight_avg_kg']).compareTo(_num(b['weight_avg_kg']));
        case SortField.weightDesc:
          return _num(b['weight_avg_kg']).compareTo(_num(a['weight_avg_kg']));
        case SortField.lifespanAsc:
          return _num(
            a['lifespan_avg_years'],
          ).compareTo(_num(b['lifespan_avg_years']));
        case SortField.lifespanDesc:
          return _num(
            b['lifespan_avg_years'],
          ).compareTo(_num(a['lifespan_avg_years']));
      }
    });

    return list;
  }

  String _str(dynamic v) => (v ?? '').toString().toLowerCase();
  double _num(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
}

// Widget thanh lọc inline
class BreedListFilterBar extends StatelessWidget {
  final AnimalFilterState filterState;
  final ValueChanged<AnimalFilterState> onChanged;
  final AnimalCategory category;
  final Set<String> favoriteIds;

  const BreedListFilterBar({
    super.key,
    required this.filterState,
    required this.onChanged,
    required this.category,
    this.favoriteIds = const {},
  });

  Color get _accent => category.gradient[0];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Sort chip
          _SortChip(
            filterState: filterState,
            accent: _accent,
            colorScheme: colorScheme,
            onChanged: onChanged,
          ),
          const SizedBox(width: 8),

          // Chip yêu thích
          if (favoriteIds.isNotEmpty) ...[
            _FavoriteFilterChip(
              isActive: filterState.showOnlyFavorites,
              accent: _accent,
              colorScheme: colorScheme,
              onTap: () => onChanged(
                filterState.copyWith(
                  showOnlyFavorites: !filterState.showOnlyFavorites,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Conservation chip
          _FilterChip2(
            label: 'Bảo tồn',
            icon: Icons.eco,
            selectedValue: filterState.conservationStatus,
            accent: _accent,
            colorScheme: colorScheme,
            options: const [
              ('Least Concern', '🟢 Ít lo ngại'),
              ('Vulnerable', '🔴 Cực kỳ nguy cấp'),
              ('Extinct in the Wild', '⚫ Tuyệt chủng ngoài TN'),
            ],
            onSelected: (v) =>
                onChanged(filterState.copyWith(conservationStatus: v)),
          ),

          // Reset nếu có filter đang active
          if (filterState.hasActiveFilters) ...[
            const SizedBox(width: 8),
            _ResetChip(
              accent: _accent,
              colorScheme: colorScheme,
              count: filterState.activeFilterCount,
              onReset: () => onChanged(
                AnimalFilterState(sortField: filterState.sortField),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Chip lọc yêu thích
class _FavoriteFilterChip extends StatelessWidget {
  final bool isActive;
  final Color accent;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _FavoriteFilterChip({
    required this.isActive,
    required this.accent,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleProvider>();
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive
              ? accent.withOpacity(0.15)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? accent.withOpacity(0.5)
                : colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.favorite : Icons.favorite_border,
              size: 13,
              color: isActive ? accent : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              t.tr('Yêu thích'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? accent : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              isActive ? Icons.close : Icons.arrow_drop_down,
              size: 15,
              color: isActive ? accent : colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// Sort chip
class _SortChip extends StatelessWidget {
  final AnimalFilterState filterState;
  final Color accent;
  final ColorScheme colorScheme;
  final ValueChanged<AnimalFilterState> onChanged;

  const _SortChip({
    required this.filterState,
    required this.accent,
    required this.colorScheme,
    required this.onChanged,
  });

  static const _options = [
    (SortField.nameAZ, 'A → Z', Icons.sort_by_alpha),
    (SortField.nameZA, 'Z → A', Icons.sort_by_alpha),
    (SortField.weightAsc, 'Nhẹ → Nặng', Icons.monitor_weight_outlined),
    (SortField.weightDesc, 'Nặng → Nhẹ', Icons.monitor_weight),
    (SortField.lifespanAsc, 'Thọ ít → nhiều', Icons.hourglass_bottom),
    (SortField.lifespanDesc, 'Thọ nhiều → ít', Icons.hourglass_top),
  ];

  @override
  Widget build(BuildContext context) {
    final current = _options.firstWhere((o) => o.$1 == filterState.sortField);
    final t = context.watch<LocaleProvider>();

    return GestureDetector(
      onTap: () => _showSortMenu(context, t),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(current.$3, size: 14, color: accent),
            const SizedBox(width: 5),
            Text(
              t.tr(current.$2),
              style: TextStyle(
                fontSize: 12,
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: accent),
          ],
        ),
      ),
    );
  }

  void _showSortMenu(BuildContext context, LocaleProvider t) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t.tr('Sắp xếp theo'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ..._options.map((opt) {
              final selected = filterState.sortField == opt.$1;
              return ListTile(
                dense: true,
                leading: Icon(
                  opt.$3,
                  color: selected ? accent : colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                title: Text(
                  t.tr(opt.$2),
                  style: TextStyle(
                    color: selected ? accent : colorScheme.onSurface,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: selected
                    ? Icon(Icons.check, color: accent, size: 18)
                    : null,
                onTap: () {
                  onChanged(filterState.copyWith(sortField: opt.$1));
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

// Generic filter chip với dropdown options
class _FilterChip2 extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? selectedValue;
  final Color accent;
  final ColorScheme colorScheme;
  final List<(String, String)> options;
  final ValueChanged<String?> onSelected;

  const _FilterChip2({
    required this.label,
    required this.icon,
    required this.selectedValue,
    required this.accent,
    required this.colorScheme,
    required this.options,
    required this.onSelected,
  });

  bool get _isActive => selectedValue != null;

  String get _displayLabel {
    if (!_isActive) return label;
    return options
        .firstWhere(
          (o) => o.$1 == selectedValue,
          orElse: () => (selectedValue!, selectedValue!),
        )
        .$2;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleProvider>();
    return GestureDetector(
      onTap: () => _showOptions(context, t),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _isActive
              ? accent.withOpacity(0.15)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isActive
                ? accent.withOpacity(0.5)
                : colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: _isActive ? accent : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              t.tr(_displayLabel),
              style: TextStyle(
                fontSize: 12,
                color: _isActive ? accent : colorScheme.onSurfaceVariant,
                fontWeight: _isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              _isActive ? Icons.close : Icons.arrow_drop_down,
              size: 15,
              color: _isActive ? accent : colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, LocaleProvider t) {
    if (_isActive) {
      onSelected(null);
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(icon, size: 18, color: accent),
                const SizedBox(width: 8),
                Text(
                  t.tr(label),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...options.map(
              (opt) => ListTile(
                dense: true,
                title: Text(
                  t.tr(opt.$2),
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                ),
                trailing: selectedValue == opt.$1
                    ? Icon(Icons.check, color: accent, size: 18)
                    : null,
                onTap: () {
                  onSelected(opt.$1);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reset chip
class _ResetChip extends StatelessWidget {
  final Color accent;
  final ColorScheme colorScheme;
  final int count;
  final VoidCallback onReset;

  const _ResetChip({
    required this.accent,
    required this.colorScheme,
    required this.count,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleProvider>();
    return GestureDetector(
      onTap: onReset,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.error.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_alt_off, size: 13, color: colorScheme.error),
            const SizedBox(width: 4),
            Text(
              '${t.tr('Xoá')} ($count)',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
