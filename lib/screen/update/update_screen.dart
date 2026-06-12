import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

// MODEL: Thông tin 1 bản cập nhật
class ChangelogEntry {
  final String version;
  final String date;
  final String title;
  final List<ChangelogItem> items;

  const ChangelogEntry({
    required this.version,
    required this.date,
    required this.title,
    required this.items,
  });
}

class ChangelogItem {
  final ChangelogType type;
  final String text;

  const ChangelogItem({required this.type, required this.text});
}

enum ChangelogType { newFeature, fix, improve, remove }

// DỮ LIỆU CHANGELOG - cập nhật tại đây mỗi khi release patch

const List<ChangelogEntry> kChangelog = [
  ChangelogEntry(
    version: '1.0.0+4',
    date: '25/05/2026',
    title: 'Bản cập nhật mới nhất',
    items: [
      ChangelogItem(type: ChangelogType.fix, text: 'Cập nhật sửa lỗi đã biết'),
    ],
  ),
  ChangelogEntry(
    version: '1.0.0+3.1',
    date: '05/05/2026',
    title: 'Bản cập nhật mới nhất',
    items: [ChangelogItem(type: ChangelogType.fix, text: 'Sửa lỗi trắng icon')],
  ),
  ChangelogEntry(
    version: '1.0.0+3',
    date: '05/05/2026',
    title: 'Bản cập nhật mới nhất',
    items: [
      ChangelogItem(
        type: ChangelogType.newFeature,
        text: 'Update chức năng thông báo',
      ),

      ChangelogItem(
        type: ChangelogType.newFeature,
        text: 'Cập nhật Tính năng yêu thích',
      ),
      ChangelogItem(
        type: ChangelogType.improve,
        text: 'Cải thiện tốc độ tải danh sách loài',
      ),
      ChangelogItem(type: ChangelogType.fix, text: 'Sửa lỗi tồn đọng'),
    ],
  ),
  ChangelogEntry(
    version: '1.0.0+2',
    date: '05/05/2026',
    title: 'Bản cập nhật mới nhất',
    items: [
      ChangelogItem(
        type: ChangelogType.newFeature,
        text:
            'Thêm trang profile, thông tin các góp ý, báo cáo của bạn sẽ hiển thị ở đó',
      ),

      ChangelogItem(
        type: ChangelogType.newFeature,
        text: 'Thêm bộ lọc A-Z trên trang chủ',
      ),
      ChangelogItem(
        type: ChangelogType.newFeature,
        text: 'Xem chi tiết loài ngay từ kết quả tìm kiếm',
      ),
      ChangelogItem(
        type: ChangelogType.improve,
        text: 'Cải thiện tốc độ tải danh sách loài',
      ),
      ChangelogItem(
        type: ChangelogType.improve,
        text: 'Giao diện trang hồ sơ mượt mà hơn',
      ),
      ChangelogItem(
        type: ChangelogType.fix,
        text: 'Sửa lỗi không tải được báo cáo quiz',
      ),
    ],
  ),
  ChangelogEntry(
    version: '1.0.0+1',
    date: '01/04/2026',
    title: 'Phiên bản đầu tiên',
    items: [
      ChangelogItem(
        type: ChangelogType.newFeature,
        text: 'Ra mắt ứng dụng Động Vật Bách Khoa Toàn Thư',
      ),
      ChangelogItem(
        type: ChangelogType.newFeature,
        text: 'Duyệt danh sách các loài động vật',
      ),
      ChangelogItem(
        type: ChangelogType.newFeature,
        text: 'Hệ thống Quiz nhận biết loài',
      ),
      ChangelogItem(
        type: ChangelogType.newFeature,
        text: 'Trang hồ sơ và thống kê cá nhân',
      ),
    ],
  ),
];

// Update screen
class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  final _updater = ShorebirdUpdater();

  // trạng thái: idle | checking | upToDate | available | downloading | done | error
  String _status = 'idle';
  String _errorMsg = '';

  Future<void> _checkAndUpdate() async {
    setState(() {
      _status = 'checking';
      _errorMsg = '';
    });

    try {
      final updateStatus = await _updater.checkForUpdate().timeout(
        const Duration(seconds: 10),
        onTimeout: () => UpdateStatus.upToDate,
      );

      if (!mounted) return;
      if (updateStatus == UpdateStatus.outdated) {
        setState(() => _status = 'available');
      } else {
        // upToDate, unavailable, hoặc timeout -> đều là "mới nhất"
        setState(() => _status = 'upToDate');
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _status = 'upToDate';
        }); // lỗi mạng -> coi như mới nhất
    }
  }

  Future<void> _downloadUpdate() async {
    setState(() => _status = 'downloading');
    try {
      await _updater.update();
      if (mounted) setState(() => _status = 'done');
    } catch (e) {
      if (mounted)
        setState(() {
          _status = 'error';
          _errorMsg = 'Tải thất bại. Vui lòng thử lại sau.';
        });
    }
  }

  void _reset() => setState(() {
    _status = 'idle';
    _errorMsg = '';
  });

  // Build
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Cập nhật ứng dụng',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // Banner trạng thái update
          _UpdateStatusBanner(
            status: _status,
            errorMsg: _errorMsg,
            onCheck: _checkAndUpdate,
            onDownload: _downloadUpdate,
            onReset: _reset,
          ),

          const SizedBox(height: 28),

          // Tiêu đề changelog
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Lịch sử cập nhật',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 16),

          // Danh sách changelog
          ...kChangelog.asMap().entries.map(
            (entry) => _ChangelogCard(
              entry: entry.value,
              index: entry.key,
              isLatest: entry.key == 0,
            ),
          ),
        ],
      ),
    );
  }
}

// WIDGET: Banner trạng thái cập nhật
class _UpdateStatusBanner extends StatelessWidget {
  final String status;
  final String errorMsg;
  final VoidCallback onCheck;
  final VoidCallback onDownload;
  final VoidCallback onReset;

  const _UpdateStatusBanner({
    required this.status,
    required this.errorMsg,
    required this.onCheck,
    required this.onDownload,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: _buildContent(context, colorScheme),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme colorScheme) {
    switch (status) {
      // Chưa kiểm tra
      case 'idle':
        return _BannerCard(
          key: const ValueKey('idle'),
          icon: Icons.system_update_alt_rounded,
          iconColor: colorScheme.primary,
          bgColor: colorScheme.primaryContainer.withOpacity(0.4),
          title: 'Kiểm tra cập nhật',
          subtitle: 'Nhấn nút bên dưới để kiểm tra phiên bản mới nhất',
          child: _ActionButton(
            label: 'Kiểm tra ngay',
            icon: Icons.search_rounded,
            color: colorScheme.primary,
            onTap: onCheck,
          ),
        );

      // Đang kiểm tra
      case 'checking':
        return _BannerCard(
          key: const ValueKey('checking'),
          icon: Icons.manage_search_rounded,
          iconColor: colorScheme.secondary,
          bgColor: colorScheme.secondaryContainer.withOpacity(0.4),
          title: 'Đang kiểm tra...',
          subtitle: 'Vui lòng chờ trong giây lát',
          child: const LinearProgressIndicator(),
        );

      // Đã cập nhật
      case 'upToDate':
        return _BannerCard(
          key: const ValueKey('upToDate'),
          icon: Icons.check_circle_rounded,
          iconColor: Colors.green,
          bgColor: Colors.green.withOpacity(0.1),
          title: 'Bạn đang dùng bản mới nhất!',
          subtitle: 'Không có bản cập nhật nào mới',
          child: _ActionButton(
            label: 'Kiểm tra lại',
            icon: Icons.refresh_rounded,
            color: Colors.green,
            onTap: onReset,
          ),
        );

      // Có bản mới
      case 'available':
        return _BannerCard(
          key: const ValueKey('available'),
          icon: Icons.new_releases_rounded,
          iconColor: Colors.orange,
          bgColor: Colors.orange.withOpacity(0.1),
          title: 'Có bản cập nhật mới! 🎉',
          subtitle: 'Tải về để trải nghiệm tính năng mới nhất',
          child: _ActionButton(
            label: 'Tải về ngay',
            icon: Icons.download_rounded,
            color: Colors.orange,
            onTap: onDownload,
          ),
        );

      // Đang tải
      case 'downloading':
        return _BannerCard(
          key: const ValueKey('downloading'),
          icon: Icons.downloading_rounded,
          iconColor: Colors.blue,
          bgColor: Colors.blue.withOpacity(0.1),
          title: 'Đang tải bản cập nhật...',
          subtitle: 'Vui lòng không tắt ứng dụng',
          child: const LinearProgressIndicator(color: Colors.blue),
        );

      // Tải xong -> nút khởi động lại
      case 'done':
        return _BannerCard(
          key: const ValueKey('done'),
          icon: Icons.task_alt_rounded,
          iconColor: Colors.green,
          bgColor: Colors.green.withOpacity(0.1),
          title: 'Tải hoàn tất! ✅',
          subtitle: 'Khởi động lại ứng dụng để áp dụng bản mới',
          child: _ActionButton(
            label: 'Khởi động lại ngay',
            icon: Icons.restart_alt_rounded,
            color: Colors.green,
            onTap: () => exit(0),
          ),
        );

      // Lỗi
      case 'error':
        return _BannerCard(
          key: const ValueKey('error'),
          icon: Icons.error_outline_rounded,
          iconColor: Colors.red,
          bgColor: Colors.red.withOpacity(0.08),
          title: 'Có lỗi xảy ra',
          subtitle: errorMsg.isNotEmpty ? errorMsg : 'Vui lòng thử lại sau',
          child: _ActionButton(
            label: 'Thử lại',
            icon: Icons.refresh_rounded,
            color: Colors.red,
            onTap: onReset,
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

// Container chung cho banner
class _BannerCard extends StatelessWidget {
  final Widget child;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;

  const _BannerCard({
    super.key,
    required this.child,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05);
  }
}

// Nút hành động
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// WIDGET: Card 1 phiên bản trong changelog
class _ChangelogCard extends StatelessWidget {
  final ChangelogEntry entry;
  final int index;
  final bool isLatest;

  const _ChangelogCard({
    required this.entry,
    required this.index,
    required this.isLatest,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            border: isLatest
                ? Border.all(
                    color: colorScheme.primary.withOpacity(0.4),
                    width: 1.5,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header phiên bản
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: isLatest
                      ? colorScheme.primary.withOpacity(0.08)
                      : colorScheme.surfaceContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isLatest ? Icons.star_rounded : Icons.history_rounded,
                      color: isLatest
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isLatest
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            entry.date,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badge phiên bản
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isLatest
                            ? colorScheme.primary
                            : colorScheme.outline.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        entry.version,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isLatest
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Danh sách thay đổi
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: entry.items
                      .map((item) => _ChangelogItemRow(item: item))
                      .toList(),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: (80 * index).ms, duration: 400.ms)
        .slideY(begin: 0.05);
  }
}

// 1 dòng thay đổi
class _ChangelogItemRow extends StatelessWidget {
  final ChangelogItem item;

  const _ChangelogItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color dotColor;
    IconData dotIcon;
    String tag;

    switch (item.type) {
      case ChangelogType.newFeature:
        dotColor = Colors.green;
        dotIcon = Icons.add_circle_rounded;
        tag = 'Mới';
        break;
      case ChangelogType.fix:
        dotColor = Colors.red;
        dotIcon = Icons.bug_report_rounded;
        tag = 'Sửa lỗi';
        break;
      case ChangelogType.improve:
        dotColor = Colors.blue;
        dotIcon = Icons.trending_up_rounded;
        tag = 'Cải thiện';
        break;
      case ChangelogType.remove:
        dotColor = Colors.grey;
        dotIcon = Icons.remove_circle_rounded;
        tag = 'Xóa';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(dotIcon, color: dotColor, size: 16),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: dotColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: dotColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.text,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
