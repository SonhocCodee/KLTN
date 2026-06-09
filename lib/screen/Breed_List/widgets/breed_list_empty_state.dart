import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../language/Locale_provider.dart';

class BreedListEmptyState extends StatelessWidget {
  final String searchQuery;
  final bool isOfflineError;
  final Future<void> Function()? onRetry;

  const BreedListEmptyState({
    super.key,
    required this.searchQuery,
    this.isOfflineError = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    final icon = isOfflineError
        ? Icons.wifi_off_rounded
        : Icons.search_off_rounded;

    final title = isOfflineError
        ? t.tr('Không có kết nối mạng')
        : searchQuery.isEmpty
        ? t.tr('Chưa có dữ liệu')
        : t.tr('Không tìm thấy kết quả');

    final subtitle = isOfflineError
        ? t.tr('Không thể tải danh sách loài. Vui lòng kiểm tra mạng hoặc thử lại sau.')
        : searchQuery.isEmpty
        ? t.tr('Danh sách này chưa có dữ liệu trong hệ thống.')
        : t.tr('Thử đổi từ khoá tìm kiếm hoặc bỏ bớt bộ lọc.');

    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 80,
                color: isOfflineError
                    ? Colors.orange
                    : colorScheme.outlineVariant,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (isOfflineError && onRetry != null) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => onRetry!.call(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(t.tr('Thử lại')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}