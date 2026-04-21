import 'package:flutter/material.dart';
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
    return Column(
      children: [
        SettingsSectionHeader(
          title: 'Thông báo & Tương tác',
          icon: Icons.notifications_active_outlined,
          primaryGreen: primaryGreen,
        ),
        SettingsCard(
          children: [
            SettingsSwitchTile(
              title: 'Động vật của ngày',
              subtitle: 'Khám phá một loài vật mới mỗi ngày',
              icon: Icons.pets_rounded,
              value: dailyAnimalNotif,
              onChanged: onDailyChanged,
              primaryGreen: primaryGreen,
              accentOrange: accentOrange,
            ),
            const SettingsDivider(),
            SettingsSwitchTile(
              title: 'Nhắc nhở chuỗi (Streak)',
              subtitle: 'Đừng quên làm nhiệm vụ thám hiểm!',
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