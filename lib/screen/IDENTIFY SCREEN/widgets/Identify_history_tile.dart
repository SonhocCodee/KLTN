import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../language/Locale_provider.dart'; // Đảm bảo import Locale_provider
import '../../Animal_detail/Animal detail screen.dart';
import '../../home/animal_category_model.dart';
import '../service/Identify_service.dart';

class IdentifyHistoryTile extends StatelessWidget {
  final SearchHistoryItem item;
  final VoidCallback onDelete;

  const IdentifyHistoryTile({
    super.key,
    required this.item,
    required this.onDelete,
  });

  static const _accentOrange = Color(0xFFEF6C00);

  // Màu & icon theo AI source
  _AiStyle _aiStyle(String? source, ColorScheme cs) {
    switch (source) {
      case 'gemini':
        return _AiStyle(color: const Color(0xFF4285F4), label: 'Gemini', icon: Icons.auto_awesome);
      case 'groq':
        return _AiStyle(color: const Color(0xFF7C3AED), label: 'Groq', icon: Icons.bolt);
      case 'local_fallback':
        return _AiStyle(color: cs.primary, label: 'Local*', icon: Icons.memory);
      default:
        return _AiStyle(color: cs.primary, label: 'Local', icon: Icons.memory);
    }
  }

  String _formatDate(DateTime dt, LocaleProvider t) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return t.tr('Vừa xong');
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${t.tr('phút trước')}';
    if (diff.inHours < 24) return '${diff.inHours} ${t.tr('giờ trước')}';
    if (diff.inDays == 1) return t.tr('Hôm qua');
    if (diff.inDays < 7) return '${diff.inDays} ${t.tr('ngày trước')}';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _openDetail(BuildContext context, LocaleProvider t) {
    if (item.animalId == null) return;
    final category = AnimalCategory.getById('cat') ??
        AnimalCategory(
          id: 'cat', nameVi: t.tr('Mèo'), nameEn: 'Cat',
          icon: Icons.pets,
          gradient: [const Color(0xFFEC4899), const Color(0xFFDB2777)],
          imageAssetPath: 'assets/animals/cat.jpg',
          totalExpected: 73, animalType: 'cat',
        );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnimalDetailScreen(
          animalId: item.animalId!,
          category: category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();
    final ai = _aiStyle(item.aiSource, colorScheme);
    final canNavigate = item.animalId != null;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 28),
            const SizedBox(height: 4),
            Text(t.tr('Xoá'), style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: canNavigate ? () => _openDetail(context, t) : null,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: canNavigate ? colorScheme.primary.withOpacity(0.25) : colorScheme.outlineVariant,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Ảnh ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 72, height: 72,
                    child: item.animalImageUrl != null
                        ? Image.network(
                      item.animalImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(colorScheme),
                    )
                        : _placeholder(colorScheme),
                  ),
                ),
              ),

              // ── Nội dung ─────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên tiếng Việt
                      Text(
                        item.nameVi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Tên tiếng Anh
                      Text(
                        item.nameEn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Row: badge AI + confidence + thời gian
                      Row(
                        children: [
                          // AI badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: ai.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: ai.color.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(ai.icon, size: 10, color: ai.color),
                                const SizedBox(width: 4),
                                Text(ai.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ai.color)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Confidence
                          if (item.confidence != null && item.confidence != '?') ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: _accentOrange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${item.confidence}%',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _accentOrange),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          // Thời gian
                          Expanded(
                            child: Text(
                              _formatDate(item.createdAt, t),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                      // Cảnh báo không có trong DB
                      if (!canNavigate) ...[
                        const SizedBox(height: 6),
                        Text(
                          t.tr('Chưa có trong từ điển'),
                          style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Mũi tên ──────────────────────────────────────────
              if (canNavigate)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant, size: 22),
                ),
            ],
          ),
        ),      // đóng Container
      ),      // đóng GestureDetector
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainer,
      child: Center(child: Icon(Icons.pets_rounded, color: cs.outlineVariant, size: 28)),
    );
  }
}

class _AiStyle {
  final Color color;
  final String label;
  final IconData icon;
  const _AiStyle({required this.color, required this.label, required this.icon});
}