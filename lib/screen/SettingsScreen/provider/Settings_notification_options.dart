// lib/screen/SettingsScreen/widgets/settings_notification_options.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../language/Locale_provider.dart';
import '../widgets/settings_components.dart';
import 'Notification_service.dart';


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
  State<SettingsNotificationOptions> createState() =>
      _SettingsNotificationOptionsState();
}

class _SettingsNotificationOptionsState
    extends State<SettingsNotificationOptions> {
  final _notifService = NotificationService();

  bool _allEnabled   = true;
  bool _testLoading  = false;

  @override
  void initState() {
    super.initState();
    _loadAllToggle();
  }

  Future<void> _loadAllToggle() async {
    final val = await _notifService.isAllEnabled();
    if (mounted) setState(() => _allEnabled = val);
  }

  // ── Bật / tắt TẤT CẢ thông báo ──
  Future<void> _onAllChanged(bool val) async {
    setState(() => _allEnabled = val);
    await _notifService.setAllNotifications(val);

    // Đồng bộ ngược trạng thái daily & streak lên cha nếu tắt toàn bộ
    if (!val) {
      widget.onDailyChanged(false);
      widget.onStreakChanged(false);
    } else {
      // Bật lại theo giá trị đã lưu
      final daily  = await _notifService.isDailyEnabled();
      final streak = await _notifService.isStreakEnabled();
      widget.onDailyChanged(daily);
      widget.onStreakChanged(streak);
    }
  }

  // ── Bật / tắt thông báo động vật của ngày ──
  Future<void> _onDailyChanged(bool val) async {
    widget.onDailyChanged(val);
    await _notifService.setDailyAnimalNotif(val);
  }

  // ── Bật / tắt nhắc streak ──
  Future<void> _onStreakChanged(bool val) async {
    widget.onStreakChanged(val);
    await _notifService.setStreakNotif(val);
  }

  // ── Bắn thông báo test ngay lập tức ──
  Future<void> _onTestPressed() async {
    setState(() => _testLoading = true);

    // Xin quyền nếu chưa có (Android 13+)
    final granted = await _notifService.requestPermission();

    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<LocaleProvider>().tr(
                  'Bạn cần cấp quyền thông báo để sử dụng tính năng này'),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      setState(() => _testLoading = false);
      return;
    }

    await _notifService.showTestNotification();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LocaleProvider>().tr('Đã gửi thông báo thử nghiệm! 🎉'),
          ),
          backgroundColor: widget.primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    setState(() => _testLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t           = context.watch<LocaleProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    // Khi tắt toàn bộ, hai toggle con bị xám
    final bool childEnabled = _allEnabled;

    return Column(
      children: [
        // ── Header ──
        SettingsSectionHeader(
          title: t.tr('Thông báo & Tương tác'),
          icon: Icons.notifications_active_outlined,
          primaryGreen: widget.primaryGreen,
        ),

        // ── Card chính ──
        SettingsCard(
          children: [
            // 1. Tắt/bật TẤT CẢ thông báo
            SettingsSwitchTile(
              title: t.tr('Tất cả thông báo'),
              subtitle: _allEnabled
                  ? t.tr('Đang bật — bạn sẽ nhận thông báo')
                  : t.tr('Đang tắt — tất cả thông báo bị chặn'),
              icon: _allEnabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              iconColor: _allEnabled ? widget.primaryGreen : Colors.grey,
              value: _allEnabled,
              onChanged: _onAllChanged,
              primaryGreen: widget.primaryGreen,
              accentOrange: widget.accentOrange,
            ),

            const SettingsDivider(),

            // 2. Động vật của ngày (3 lần/ngày, chỉ khi chưa mở app)
            Opacity(
              opacity: childEnabled ? 1.0 : 0.4,
              child: IgnorePointer(
                ignoring: !childEnabled,
                child: SettingsSwitchTile(
                  title: t.tr('Động vật của ngày'),
                  subtitle: t.tr('Nhắc 3 lần/ngày nếu bạn chưa vào app'),
                  icon: Icons.pets_rounded,
                  value: widget.dailyAnimalNotif,
                  onChanged: _onDailyChanged,
                  primaryGreen: widget.primaryGreen,
                  accentOrange: widget.accentOrange,
                ),
              ),
            ),

            const SettingsDivider(),

            // 3. Nhắc streak (3 lần/ngày)
            Opacity(
              opacity: childEnabled ? 1.0 : 0.4,
              child: IgnorePointer(
                ignoring: !childEnabled,
                child: SettingsSwitchTile(
                  title: t.tr('Nhắc nhở chuỗi (Streak)'),
                  subtitle: t.tr('Nhắc 3 lần/ngày để giữ chuỗi liên tiếp'),
                  icon: Icons.local_fire_department_rounded,
                  iconColor: Colors.redAccent,
                  value: widget.streakNotif,
                  onChanged: _onStreakChanged,
                  primaryGreen: widget.primaryGreen,
                  accentOrange: widget.accentOrange,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Nút TEST thông báo ──
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

        const SizedBox(height: 8),

        // ── Ghi chú nhỏ ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 13, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  t.tr(
                      'Thông báo sẽ không hiện nếu bạn đã mở app trong ngày hôm đó'),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}