import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../language/Locale_provider.dart';
import '../help_center_screen.dart';
import 'settings_components.dart';

// Đừng quên import file HelpCenterScreen mà mình viết ở dưới nhé!
// import 'help_center_screen.dart';

class SettingsInfoOptions extends StatelessWidget {
  final Color primaryGreen;

  const SettingsInfoOptions({
    super.key,
    required this.primaryGreen,
  });

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
            // ── Mục 1: FAQ ──
            ListTile(
              leading: Icon(Icons.help_outline_rounded, color: primaryGreen),
              title: Text(
                t.tr('Câu hỏi thường gặp (FAQ)'),
                style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
              ),
              trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
              onTap: () {
                // Chuyển sang Help Center, mở Tab 0 (FAQ)
                /* Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpCenterScreen(initialIndex: 0)),
                ); */
              },
            ),
            const SettingsDivider(),

            // ── Mục 2: Liên hệ / Báo lỗi ──
            ListTile(
              leading: Icon(Icons.bug_report_rounded, color: primaryGreen),
              title: Text(
                t.tr('Góp ý & Báo lỗi'),
                style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
              ),
              trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
              onTap: () {

                 Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpCenterScreen(initialIndex: 1)),
                );
              },
            ),
            const SettingsDivider(),

            // ── Mục 3: Chính sách ──
            ListTile(
              leading: Icon(Icons.security_rounded, color: primaryGreen),
              title: Text(
                t.tr('Chính sách bảo mật'),
                style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
              ),
              trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}