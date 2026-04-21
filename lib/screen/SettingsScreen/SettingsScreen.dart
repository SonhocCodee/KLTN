import 'package:flutter/material.dart';
import 'package:kltn_app/screen/SettingsScreen/widgets/ettings_info_options.dart';

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

  String selectedLanguage = 'Tiếng Việt';
  String selectedUnit     = 'Hệ Mét (kg, m)';
  bool   dailyAnimalNotif = true;
  bool   streakNotif      = true;

  // ✅ fontSizeFactor đã chuyển sang ThemeProvider — không cần state local nữa

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Cài đặt',
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

          // ✅ Bỏ fontSizeFactor + baseFontSize + onFontSizeChanged
          // ThemeProvider lo hết bên trong widget rồi
          SettingsAppearanceOptions(
            selectedLanguage: selectedLanguage,
            onLanguageChanged: (val) => setState(() => selectedLanguage = val!),
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
          SettingsInfoOptions(
            primaryGreen: primaryGreen,
          ),

          const SizedBox(height: 30),
          Center(
            child: Text(
              'Phiên bản 1.0.0\nĐộng Vật Bách Khoa Toàn Thư',
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