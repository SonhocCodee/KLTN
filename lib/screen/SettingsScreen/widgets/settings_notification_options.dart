import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../language/Locale_provider.dart';
import '../provider/Notification_service.dart';
import 'settings_components.dart';

class SettingsNotificationOptions extends StatefulWidget {
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
  State<SettingsNotificationOptions> createState() => _SettingsNotificationOptionsState();
}

class _SettingsNotificationOptionsState extends State<SettingsNotificationOptions> {
  final _notifService = NotificationService();
  bool _testLoading = false;

  // Hàm xử lý khi bấm nút Test
  Future<void> _onTestPressed() async {
    setState(() => _testLoading = true);

    // Xin quyền thông báo (Dành cho Android 13+)
    final granted = await _notifService.requestPermission();

    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<LocaleProvider>().tr('Bạn cần cấp quyền thông báo')),
            backgroundColor: Colors.orange,
          ),
        );
      }
      setState(() => _testLoading = false);
      return;
    }

    // Bắn thông báo test
    await _notifService.showTestNotification();

    // Hiện thông báo popup nhỏ báo thành công
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<LocaleProvider>().tr('Đã gửi thông báo thử nghiệm! 🎉')),
          backgroundColor: widget.primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    setState(() => _testLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleProvider>();

    return Column(
      children: [
        SettingsSectionHeader(
          title: t.tr('Thông báo & Tương tác'),
          icon: Icons.notifications_active_outlined,
          primaryGreen: widget.primaryGreen,
        ),
        SettingsCard(
          children: [
            SettingsSwitchTile(
              title: t.tr('Động vật của ngày'),
              subtitle: t.tr('Khám phá một loài vật mới mỗi ngày'),
              icon: Icons.pets_rounded,
              value: widget.dailyAnimalNotif,
              onChanged: widget.onDailyChanged,
              primaryGreen: widget.primaryGreen,
              accentOrange: widget.accentOrange,
            ),
            const SettingsDivider(),
            SettingsSwitchTile(
              title: t.tr('Nhắc nhở chuỗi (Streak)'),
              subtitle: t.tr('Đừng quên làm nhiệm vụ thám hiểm!'),
              icon: Icons.local_fire_department_rounded,
              iconColor: Colors.redAccent,
              value: widget.streakNotif,
              onChanged: widget.onStreakChanged,
              primaryGreen: widget.primaryGreen,
              accentOrange: widget.accentOrange,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── NÚT TEST THÔNG BÁO Ở ĐÂY ──
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.accentOrange,
              side: BorderSide(color: widget.accentOrange),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _testLoading
                ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.accentOrange,
              ),
            )
                : const Icon(Icons.notifications_active_rounded),
            label: Text(
              t.tr('Thử thông báo ngay'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            onPressed: _testLoading ? null : _onTestPressed,
          ),
        ),
      ],
    );
  }
}