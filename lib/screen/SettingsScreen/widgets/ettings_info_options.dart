import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../language/Locale_provider.dart';
import '../help_center_screen.dart';
import 'settings_components.dart';

class SettingsInfoOptions extends StatelessWidget {
  final Color primaryGreen;

  const SettingsInfoOptions({super.key, required this.primaryGreen});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    return Column(
      children: [
        SettingsSectionHeader(
          title: t.tr('Thông tin & Trợ giúp'),
          icon: Icons.info_outline_rounded,
          primaryGreen: primaryGreen,
        ),
        SettingsCard(
          children: [
            ListTile(
              leading: Icon(Icons.help_outline_rounded, color: primaryGreen),
              title: Text(
                t.tr('Câu hỏi thường gặp (FAQ)'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HelpCenterScreen(initialIndex: 0),
                  ),
                );
              },
            ),
            const SettingsDivider(),

            ListTile(
              leading: Icon(Icons.bug_report_rounded, color: primaryGreen),
              title: Text(
                t.tr('Góp ý & Báo lỗi'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HelpCenterScreen(initialIndex: 1),
                  ),
                );
              },
            ),
            const SettingsDivider(),

            ListTile(
              leading: Icon(Icons.security_rounded, color: primaryGreen),
              title: Text(
                t.tr('Chính sách bảo mật'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PrivacyPolicyScreen(primaryGreen: primaryGreen),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  final Color primaryGreen;

  const PrivacyPolicyScreen({super.key, required this.primaryGreen});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryGreen),
        title: Text(
          t.tr('Chính sách bảo mật'),
          style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          _PolicyBlock(
            title: t.tr('Dữ liệu tài khoản'),
            body: t.tr(
              'Ứng dụng dùng thông tin đăng nhập để lưu yêu thích, lịch sử học tập, góp ý và các cài đặt cá nhân của bạn.',
            ),
          ),
          _PolicyBlock(
            title: t.tr('Ảnh và nội dung gửi lên'),
            body: t.tr(
              'Ảnh nhận diện, báo cáo lỗi và góp ý chỉ được dùng để xử lý tính năng tương ứng trong ứng dụng.',
            ),
          ),
          _PolicyBlock(
            title: t.tr('Thông báo'),
            body: t.tr(
              'Token thông báo được lưu để gửi nhắc học, cập nhật ứng dụng và thông tin liên quan đến trải nghiệm sử dụng.',
            ),
          ),
          _PolicyBlock(
            title: t.tr('Quyền kiểm soát'),
            body: t.tr(
              'Bạn có thể đăng xuất, tắt thông báo hoặc liên hệ qua mục Góp ý & Báo lỗi nếu muốn yêu cầu hỗ trợ về dữ liệu.',
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyBlock extends StatelessWidget {
  final String title;
  final String body;

  const _PolicyBlock({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
