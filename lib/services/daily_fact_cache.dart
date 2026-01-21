import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../screen/models/animal_data.dart';

class DailyFactCache {
  static const String _cacheKey = 'daily_fact_cache';
  static const String _dateKey = 'daily_fact_date';

  static Future<void> saveCache(AnimalFact fact) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];

    await prefs.setString(_cacheKey, json.encode(fact.toCache()));
    await prefs.setString(_dateKey, today);
  }

  static Future<AnimalFact?> getCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedDate = prefs.getString(_dateKey);
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (cachedDate != today) {
      return null;
    }

    final cachedData = prefs.getString(_cacheKey);
    if (cachedData == null) return null;

    try {
      final data = json.decode(cachedData);
      return AnimalFact.fromCache(data);
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_dateKey);
  }
}