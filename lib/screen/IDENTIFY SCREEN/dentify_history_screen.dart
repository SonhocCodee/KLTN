import 'package:flutter/material.dart';
import 'package:kltn_app/screen/IDENTIFY%20SCREEN/service/Identify_service.dart';
import 'package:kltn_app/screen/IDENTIFY%20SCREEN/widgets/Identify_history_tile.dart';
import 'package:provider/provider.dart';

import '../language/Locale_provider.dart';

class IdentifyHistoryScreen extends StatefulWidget {
  const IdentifyHistoryScreen({super.key});

  @override
  State<IdentifyHistoryScreen> createState() => _IdentifyHistoryScreenState();
}

class _IdentifyHistoryScreenState extends State<IdentifyHistoryScreen> {
  static const _accentOrange = Color(0xFFEF6C00);

  @override
  void initState() {
    super.initState();
    // Tải lịch sử ngay khi màn hình được mở
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IdentifyService>().loadHistory();
    });
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    IdentifyService service,
    LocaleProvider t,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(
              t.tr('Xoá tất cả?'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: Text(t.tr('Toàn bộ lịch sử tìm kiếm sẽ bị xoá vĩnh viễn.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.tr('Huỷ')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.tr('Xoá hết')),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await service.clearAllHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<IdentifyService>();
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: colorScheme.onSurface,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              t.tr('Lịch Sử'),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: colorScheme.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.history_rounded,
                              color: _accentOrange,
                              size: 26,
                            ),
                          ],
                        ),
                        Text(
                          t.tr('Các lần nhận diện trước đây'),
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Nút xoá tất cả
                  if (service.historyItems.isNotEmpty)
                    IconButton(
                      onPressed: () => _confirmClearAll(context, service, t),
                      icon: const Icon(Icons.delete_sweep_rounded),
                      color: Colors.redAccent,
                      tooltip: t.tr('Xoá tất cả'),
                    ),
                ],
              ),
            ),

            // Số lượng
            if (!service.isLoadingHistory && service.historyItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _accentOrange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${service.historyItems.length} ${t.tr('lần tìm kiếm')}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _accentOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Body
            Expanded(
              child: service.isLoadingHistory
                  ? _buildLoading(colorScheme, t)
                  : service.historyItems.isEmpty
                  ? _buildEmpty(colorScheme, t)
                  : _buildList(service, colorScheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(ColorScheme colorScheme, LocaleProvider t) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: _accentOrange, strokeWidth: 3),
          const SizedBox(height: 16),
          Text(
            t.tr('Đang tải lịch sử...'),
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(ColorScheme colorScheme, LocaleProvider t) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _accentOrange.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.manage_search_rounded,
              size: 52,
              color: _accentOrange.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            t.tr('Chưa có lịch sử'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.tr('Hãy chụp hoặc chọn ảnh\nđể bắt đầu nhận diện!'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(IdentifyService service, ColorScheme colorScheme) {
    return RefreshIndicator(
      color: _accentOrange,
      onRefresh: () => service.loadHistory(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        physics: const BouncingScrollPhysics(),
        itemCount: service.historyItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = service.historyItems[index];
          return IdentifyHistoryTile(
            item: item,
            onDelete: () => service.deleteHistoryItem(item.id),
          );
        },
      ),
    );
  }
}
