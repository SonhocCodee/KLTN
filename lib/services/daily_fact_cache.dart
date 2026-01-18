import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'animal_api_service.dart';

class DailyFactCache {
  static const String _cacheKey = 'daily_fact_cache';
  static const String _dateKey = 'daily_fact_date';

  // Lưu cache
  static Future<void> saveCache(AnimalFact fact) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];

    final data = {
      'name': fact.name,
      'scientificName': fact.scientificName,
      'description': fact.description,
      'facts': fact.facts,
      'imageUrl': fact.imageUrl,
      'category': fact.category,
    };

    await prefs.setString(_cacheKey, json.encode(data));
    await prefs.setString(_dateKey, today);
  }

  // Lấy cache nếu còn trong ngày
  static Future<AnimalFact?> getCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedDate = prefs.getString(_dateKey);
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Kiểm tra xem cache có còn trong ngày không
    if (cachedDate != today) {
      return null; // Cache hết hạn
    }

    final cachedData = prefs.getString(_cacheKey);
    if (cachedData == null) return null;

    try {
      final data = json.decode(cachedData);
      return AnimalFact(
        name: data['name'],
        scientificName: data['scientificName'],
        description: data['description'],
        facts: List<String>.from(data['facts']),
        imageUrl: data['imageUrl'],
        category: data['category'],
      );
    } catch (e) {
      return null;
    }
  }

  // Xóa cache (dùng khi test)
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_dateKey);
  }
}
