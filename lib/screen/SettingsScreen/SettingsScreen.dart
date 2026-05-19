import 'package:flutter/material.dart';
import 'package:kltn_app/screen/SettingsScreen/provider/Notification_service.dart';
import 'package:kltn_app/screen/SettingsScreen/widgets/ettings_info_options.dart';
import 'package:provider/provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kltn_app/screen/welcome/welcome_screen.dart';

import '../language/Locale_provider.dart';
import '../update/update_screen.dart';
import 'widgets/settings_animated_header.dart';
import 'widgets/settings_appearance_options.dart';
import 'widgets/settings_content_options.dart';
import 'widgets/settings_notification_options.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

class AnimalSettingsScreen extends StatefulWidget {
  const AnimalSettingsScreen({super.key});

  @override
  State<AnimalSettingsScreen> createState() => _AnimalSettingsScreenState();
}

class _AnimalSettingsScreenState extends State<AnimalSettingsScreen>
    with SingleTickerProviderStateMixin {

  // ❌ Bỏ selectedUnit — giờ UnitProvider quản lý
  bool dailyAnimalNotif = true;
  bool streakNotif      = true;

  String _appVersionText = 'Đang tải...';

  late AnimationController _animController;
  late Animation<double>   _scaleAnimation;

  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color accentOrange = const Color(0xFFEF6C00);

  final _notifService = NotificationService();

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _loadNotifState();
    _fetchAppVersion();
  }

  Future<void> _fetchAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final baseVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      final updater = ShorebirdUpdater();
      final currentPatch = await updater.readCurrentPatch();
      final status = await updater.checkForUpdate();

      if (mounted) {
        setState(() {
          if (status == UpdateStatus.outdated) {
            _appVersionText = '$baseVersion (Có bản cập nhật mới! cạp nhật đi ! )';
          } else if (currentPatch != null) {
            _appVersionText = '$baseVersion (Patch ${currentPatch.number})';
          } else {
            _appVersionText = baseVersion;
          }
        });
      }

      if (status == UpdateStatus.outdated) {
        await updater.update();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.read<LocaleProvider>().tr(
                  'Đã tải xong bản cập nhật! Vui lòng mở lại app để áp dụng.')),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _appVersionText = '1.0.0');
    }
  }

  Future<void> _loadNotifState() async {
    final daily  = await _notifService.isDailyEnabled();
    final streak = await _notifService.isStreakEnabled();
    if (mounted) {
      setState(() {
        dailyAnimalNotif = daily;
        streakNotif      = streak;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout(BuildContext context, LocaleProvider t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(t.tr('Đăng xuất'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(t.tr(
            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này không?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.tr('Hủy'),
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.tr('Đăng xuất')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t           = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          t.tr('Cài đặt'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryGreen,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryGreen),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          SettingsAnimatedHeader(
            scaleAnimation: _scaleAnimation,
            accentOrange: accentOrange,
          ),
          const SizedBox(height: 20),

          SettingsAppearanceOptions(
            primaryGreen: primaryGreen,
            accentOrange: accentOrange,
          ),

          const SizedBox(height: 24),

          // ✅ Bỏ selectedUnit + onUnitChanged — widget tự đọc UnitProvider
          SettingsContentOptions(
            primaryGreen: primaryGreen,
            accentOrange: accentOrange,
          ),

          const SizedBox(height: 24),
          SettingsNotificationOptions(
            dailyAnimalNotif: dailyAnimalNotif,
            streakNotif: streakNotif,
            onDailyChanged: (val) => setState(() => dailyAnimalNotif = val),
            onStreakChanged: (val) => setState(() => streakNotif = val),
            primaryGreen: primaryGreen,
            accentOrange: accentOrange,
          ),

          const SizedBox(height: 24),
          SettingsInfoOptions(primaryGreen: primaryGreen),

          const SizedBox(height: 32),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.system_update_alt_rounded),
              label: Text(
                t.tr('Kiểm tra cập nhật'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UpdateScreen()),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                t.tr('Đăng xuất'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _handleLogout(context, t),
            ),
          ),

          const SizedBox(height: 32),

          Center(
            child: Text(
              '${t.tr('Phiên bản')} $_appVersionText\n${t.tr('Động Vật Bách Khoa Toàn Thư')}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}