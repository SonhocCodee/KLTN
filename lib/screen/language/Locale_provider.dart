import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LocaleProvider extends ChangeNotifier {
  bool _isEnglish = false;
  Map<String, dynamic> _en = {};

  bool get isEnglish => _isEnglish;

  Future<void> loadTranslations() async {
    try {
      final raw = await rootBundle.loadString('assets/translations/language.json');
      _en = json.decode(raw);
    } catch (e) {
      print("Lỗi load ngôn ngữ: $e");
    }
  }

  void toggleLanguage() {
    _isEnglish = !_isEnglish;
    notifyListeners();
  }

  /// NATURAL LANGUAGE KEY: Key chính là tiếng Việt
  String tr(String key) {
    if (!_isEnglish) return key;
    return _en[key]?.toString() ?? key;
  }

  /// Chuỗi có tham số động
  String trArgs(String key, {required Map<String, String> args}) {
    String text = tr(key);
    args.forEach((k, v) => text = text.replaceAll('{$k}', v));
    return text;
  }
}