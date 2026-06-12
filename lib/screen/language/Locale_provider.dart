import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const _keyIsEnglish = 'locale_is_english';

  bool _isEnglish = false;
  Map<String, dynamic> _en = {};

  bool get isEnglish => _isEnglish;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnglish = prefs.getBool(_keyIsEnglish) ?? false;
    notifyListeners();
  }

  Future<void> loadTranslations() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/translations/language.json',
      );
      _en = json.decode(raw);
    } catch (e) {
      print("Lỗi load ngôn ngữ: $e");
    }
  }

  Future<void> toggleLanguage() async {
    _isEnglish = !_isEnglish;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsEnglish, _isEnglish);
    notifyListeners();
  }

  // NATURAL LANGUAGE KEY: Key chính là tiếng Việt
  String tr(String key) {
    if (!_isEnglish) return key;
    return _en[key]?.toString() ?? key;
  }

  // Chuỗi có tham số động
  String trArgs(String key, {required Map<String, String> args}) {
    String text = tr(key);
    args.forEach((k, v) => text = text.replaceAll('{$k}', v));
    return text;
  }
}
