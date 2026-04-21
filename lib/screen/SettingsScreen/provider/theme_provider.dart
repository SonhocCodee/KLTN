import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _keyDarkMode   = 'isDarkMode';
  static const _keyFontStep   = 'fontSizeStep';

  bool _isDarkMode   = false;
  int  _fontSizeStep = 1; // 0=Nhỏ, 1=Bình thường, 2=Lớn

  bool   get isDarkMode      => _isDarkMode;
  int    get currentFontStep => _fontSizeStep;

  // Scale factor tương ứng với 3 mốc
  double get fontSizeFactor {
    const steps = [0.85, 1.0, 1.2];
    return steps[_fontSizeStep];
  }

  ThemeProvider() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs   = await SharedPreferences.getInstance();
    _isDarkMode   = prefs.getBool(_keyDarkMode) ?? false;
    _fontSizeStep = prefs.getInt(_keyFontStep)  ?? 1;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, _isDarkMode);
    notifyListeners();
  }

  Future<void> setFontSizeByStep(int step) async {
    _fontSizeStep = step.clamp(0, 2);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFontStep, _fontSizeStep);
    notifyListeners();
  }

  ThemeData get themeData => _isDarkMode ? _darkTheme : _lightTheme;

  static final _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: const Color(0xFF2E7D32),
  );

  static final _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: const Color(0xFF2E7D32),
  );
}