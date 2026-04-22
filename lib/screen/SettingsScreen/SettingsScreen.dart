import 'package:flutter/material.dart';
import 'package:kltn_app/screen/SettingsScreen/widgets/ettings_info_options.dart';
import 'package:provider/provider.dart';

// ── THÊM 2 IMPORT NÀY ĐỂ XỬ LÝ ĐĂNG XUẤT ──
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kltn_app/screen/welcome/welcome_screen.dart'; // Thay bằng AuthScreen nếu bạn muốn nhảy thẳng vào form login

import '../language/Locale_provider.dart';
import 'widgets/settings_animated_header.dart';
import 'widgets/settings_appearance_options.dart';
import 'widgets/settings_content_options.dart';
import 'widgets/settings_notification_options.dart';

class AnimalSettingsScreen extends StatefulWidget {
  const AnimalSettingsScreen({super.key});

  @override
  State<AnimalSettingsScreen> createState() => _AnimalSettingsScreenState();
}

class _AnimalSettingsScreenState extends State<AnimalSettingsScreen>
    with SingleTickerProviderStateMixin {

  String selectedUnit     = 'metric'; // 'metric' | 'imperial'
  bool   dailyAnimalNotif = true;
  bool   streakNotif      = true;

  late AnimationController _animController;
  late Animation<double>   _scaleAnimation;

  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color accentOrange = const Color(0xFFEF6C00);

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
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── HÀM XỬ LÝ ĐĂNG XUẤT ──
  Future<void> _handleLogout(BuildContext context, LocaleProvider t) async {
    // Hiện hộp thoại xác nhận
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(t.tr('Đăng xuất'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(t.tr('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này không?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.tr('Hủy'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.tr('Đăng xuất')),
          ),
        ],
      ),
    );

    // Nếu người dùng chọn "Đăng xuất"
    if (confirm == true) {
      // 1. Đăng xuất khỏi Supabase
      await Supabase.instance.client.auth.signOut();

      // 2. Chuyển về WelcomeScreen và xoá toàn bộ stack lịch sử
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (route) => false, // Xoá hết các trang cũ
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
          SettingsContentOptions(
            selectedUnit: selectedUnit,
            onUnitChanged: (val) => setState(() => selectedUnit = val!),
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

          // ── NÚT ĐĂNG XUẤT ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                // Màu chữ: Sáng mờ cho Dark, Xám đậm cho Light
                foregroundColor: colorScheme.brightness == Brightness.dark
                    ? Colors.red
                    : Colors.red,
                // Màu viền: Bo viền nhạt để tạo khối
                side: BorderSide(
                  color: colorScheme.brightness == Brightness.dark
                      ? Colors.red
                      : Colors.red,
                ),
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
              t.tr('Phiên bản 1.0.0\nĐộng Vật Bách Khoa Toàn Thư'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}