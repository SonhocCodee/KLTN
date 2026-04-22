import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../language/Locale_provider.dart';
import 'settings_components.dart';

class SettingsNotificationOptions extends StatelessWidget {
  final bool dailyAnimalNotif;
  final bool streakNotif;
  final ValueChanged<bool> onDailyChanged;
  final ValueChanged<bool> onStreakChanged;
  final Color primaryGreen;
  final Color accentOrange;

  const SettingsNotificationOptions({
    super.key,
    required this.dailyAnimalNotif,
    required this.streakNotif,
    required this.onDailyChanged,
    required this.onStreakChanged,
    required this.primaryGreen,
    required this.accentOrange,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleProvider>(); // Lấy provider

    return Column(
      children: [
        SettingsSectionHeader(
          title: t.tr('Thông báo & Tương tác'),
          icon: Icons.notifications_active_outlined,
          primaryGreen: primaryGreen,
        ),
        SettingsCard(
          children: [
            SettingsSwitchTile(
              title: t.tr('Động vật của ngày'),
              subtitle: t.tr('Khám phá một loài vật mới mỗi ngày'),
              icon: Icons.pets_rounded,
              value: dailyAnimalNotif,
              onChanged: onDailyChanged,
              primaryGreen: primaryGreen,
              accentOrange: accentOrange,
            ),
            const SettingsDivider(),
            SettingsSwitchTile(
              title: t.tr('Nhắc nhở chuỗi (Streak)'),
              subtitle: t.tr('Đừng quên làm nhiệm vụ thám hiểm!'),
              icon: Icons.local_fire_department_rounded,
              iconColor: Colors.redAccent,
              value: streakNotif,
              onChanged: onStreakChanged,
              primaryGreen: primaryGreen,
              accentOrange: accentOrange,
            ),
          ],
        ),
      ],
    );
  }
}