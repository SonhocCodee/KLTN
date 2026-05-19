import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 'metric'   → kg, m, km/h
/// 'imperial' → lbs, ft, mph
class UnitProvider extends ChangeNotifier {
  static const _key = 'selected_unit';

  String _unit = 'metric';
  String get unit => _unit;
  bool get isImperial => _unit == 'imperial';

  UnitProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _unit = prefs.getString(_key) ?? 'metric';
    notifyListeners();
  }

  Future<void> setUnit(String unit) async {
    if (_unit == unit) return;
    _unit = unit;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, unit);
  }

  // ── Convert helpers ────────────────────────────────────────────────────

  /// kg → lbs nếu imperial
  String formatWeight(num kg) {
    if (isImperial) {
      final lbs = (kg * 2.20462).toStringAsFixed(0);
      return '$lbs lbs';
    }
    return '${kg.toStringAsFixed(0)} kg';
  }

  /// m → ft nếu imperial
  String formatHeight(num m) {
    if (isImperial) {
      final ft = (m * 3.28084).toStringAsFixed(1);
      return '$ft ft';
    }
    return '${m.toStringAsFixed(1)} m';
  }

  /// m → ft nếu imperial (dùng cho length_avg_m)
  String formatLength(num m) => formatHeight(m);

  /// km/h → mph nếu imperial
  String formatSpeed(num kmh) {
    if (isImperial) {
      final mph = (kmh * 0.621371).toStringAsFixed(0);
      return '$mph mph';
    }
    return '$kmh km/h';
  }
}