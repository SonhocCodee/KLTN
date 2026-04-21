import 'package:flutter/material.dart';
import 'settings_components.dart';

class SettingsInfoOptions extends StatelessWidget {
  final Color primaryGreen;

  const SettingsInfoOptions({
    super.key,
    required this.primaryGreen,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        SettingsSectionHeader(
          title: 'Thông tin',
          icon: Icons.info_outline_rounded,
          primaryGreen: primaryGreen,
        ),
        SettingsCard(
          children: [
            ListTile(
              leading: Icon(Icons.bug_report_rounded, color: primaryGreen),
              title: Text(
                'Góp ý & Báo lỗi',
                style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
              ),
              trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
              onTap: () {},
            ),
            const SettingsDivider(),
            ListTile(
              leading: Icon(Icons.security_rounded, color: primaryGreen),
              title: Text(
                'Chính sách bảo mật',
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