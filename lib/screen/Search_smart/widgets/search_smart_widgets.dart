import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../language/Locale_provider.dart';

import '../models/search_smart_models.dart';


// ── Nút Option trong Quiz ──
class SmartOptionRow extends StatelessWidget {
  final QuestionConfig question;
  final OptionConfig option;
  final bool isLast;
  final int index;
  final VoidCallback onTap;

  const SmartOptionRow({
    super.key,
    required this.question,
    required this.option,
    required this.isLast,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text(option.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    t.tr(option.label),
                    style: TextStyle(
                      fontSize: 17,
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Icon(CupertinoIcons.chevron_forward, color: colorScheme.outlineVariant, size: 16),
              ],
            ),
          ),
          if (!isLast)
            Divider(height: 1, indent: 58, color: colorScheme.outlineVariant),
        ],
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1);
  }
}

// ── Card chọn loài động vật ──
class SmartTypeCard extends StatelessWidget {
  final AnimalTypeConfig config;
  final int index;
  final VoidCallback onTap;

  const SmartTypeCard({super.key, required this.config, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(config.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              t.tr(config.nameVi),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              config.nameEn,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (60 * index).ms, duration: 350.ms).scale(begin: const Offset(0.92, 0.92), delay: (60 * index).ms);
  }
}

// ── Card Kết quả ──
class SmartResultCard extends StatelessWidget {
  final Map<String, dynamic> animal;
  final int index;
  final AnimalTypeConfig? selectedConfig;
  final VoidCallback onTap;

  const SmartResultCard({
    super.key,
    required this.animal,
    required this.index,
    required this.selectedConfig,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: animal['image_url'] != null
                    ? Image.network(
                  animal['image_url'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => _emojiPlaceholder(colorScheme),
                )
                    : _emojiPlaceholder(colorScheme),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      animal['name_vietnamese'] ?? animal['name_english'] ?? '—',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (animal['scientific_name'] != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        animal['scientific_name'],
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (50 * index).ms, duration: 350.ms).scale(begin: const Offset(0.88, 0.88), delay: (50 * index).ms);
  }

  Widget _emojiPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainer,
      child: Center(
        child: Text(selectedConfig?.emoji ?? '🐾', style: const TextStyle(fontSize: 48)),
      ),
    );
  }
}

// ── Thanh Navigation Bar iOS Style ──
class SmartNavBar extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget trailing;

  const SmartNavBar({super.key, required this.leading, required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          leading,
          Expanded(child: Center(child: title)),
          trailing,
        ],
      ),
    );
  }
}

// ── Loading Indicator ──
class SmartLoadingView extends StatelessWidget {
  const SmartLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CupertinoActivityIndicator(radius: 16),
          const SizedBox(height: 16),
          Text(
            t.tr('Đang tìm kiếm...'),
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// ── Màn hình không có kết quả ──
class SmartNoResultsView extends StatelessWidget {
  final VoidCallback onRetry;
  const SmartNoResultsView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            t.tr('Không tìm thấy'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.tr('Thử tìm lại với ít tiêu chí hơn'),
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                t.tr('Tìm lại từ đầu'),
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}