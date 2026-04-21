// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  final String _prefKey = "isDarkMode";

  bool get isDarkMode => _isDarkMode;

  // Constructor: Gọi hàm load theme ngay khi khởi tạo provider
  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // Ép màu nền chuẩn như đã chốt hoặc giữ mặc định của ông
  ThemeData get themeData => _isDarkMode
      ? ThemeData.dark(useMaterial3: true).copyWith(
    colorScheme: const ColorScheme.dark(
      surface: Colors.black, // Ép nền đen tuyền
      surfaceContainerHighest: Color(0xFF1C1C1E), // Ép xám nổi
      onSurface: Colors.white,
      onSurfaceVariant: Colors.grey,
      primary: Color(0xFF4CAF50), // Màu xanh của AniQuest
    ),
    scaffoldBackgroundColor: Colors.black,
  )
      : ThemeData.light(useMaterial3: true);

  // Hàm chuyển theme và lưu vào bộ nhớ
  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();

    // Lưu trạng thái vào bộ nhớ máy
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, _isDarkMode);
  }

  // Hàm đọc trạng thái từ bộ nhớ khi mở app
  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Nếu chưa từng lưu (lần đầu mở app) thì mặc định là false (Light mode)
    _isDarkMode = prefs.getBool(_prefKey) ?? false;
    notifyListeners(); // Báo cho UI cập nhật lại theo theme đã lưu
  }
}