import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Cache persist cho sound + map data của từng loài.
// Singleton - dùng chung toàn app.
class AnimalApiCacheService {
  AnimalApiCacheService._();
  static final AnimalApiCacheService instance = AnimalApiCacheService._();

  // Memory layer (tránh đọc disk nhiều lần trong session)
  final Map<String, List<Map<String, dynamic>>> _soundCache = {};
  final Map<String, List<Map<String, double>>> _mapCache = {};
  final Map<String, int> _mapCountCache = {};

  static const _soundPrefix = 'sound_';
  static const _mapPrefix = 'map_';
  static const _mapCountPrefix = 'mapcount_';

  // Sound

  Future<List<Map<String, dynamic>>?> getSounds(String animalId) async {
    // 1. Memory
    if (_soundCache.containsKey(animalId)) return _soundCache[animalId];

    // 2. Disk
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_soundPrefix$animalId');
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw) as List;
      final data = decoded.cast<Map<String, dynamic>>();
      _soundCache[animalId] = data; // warm memory
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSounds(
    String animalId,
    List<Map<String, dynamic>> sounds,
  ) async {
    _soundCache[animalId] = sounds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_soundPrefix$animalId', jsonEncode(sounds));
  }

  // Map

  Future<({List<Map<String, double>> points, int count})?> getMap(
    String animalId,
  ) async {
    // 1. Memory
    if (_mapCache.containsKey(animalId)) {
      return (
        points: _mapCache[animalId]!,
        count: _mapCountCache[animalId] ?? 0,
      );
    }

    // 2. Disk
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_mapPrefix$animalId');
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw) as List;
      final points = decoded
          .map(
            (e) => Map<String, double>.from(
              (e as Map).map(
                (k, v) => MapEntry(k as String, (v as num).toDouble()),
              ),
            ),
          )
          .toList();
      final count = prefs.getInt('$_mapCountPrefix$animalId') ?? 0;

      _mapCache[animalId] = points;
      _mapCountCache[animalId] = count;
      return (points: points, count: count);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveMap(
    String animalId,
    List<Map<String, double>> points,
    int count,
  ) async {
    _mapCache[animalId] = points;
    _mapCountCache[animalId] = count;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_mapPrefix$animalId', jsonEncode(points));
    await prefs.setInt('$_mapCountPrefix$animalId', count);
  }

  // CLEAR (nếu cần)

  Future<void> clearAll() async {
    _soundCache.clear();
    _mapCache.clear();
    _mapCountCache.clear();
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where(
          (k) =>
              k.startsWith(_soundPrefix) ||
              k.startsWith(_mapPrefix) ||
              k.startsWith(_mapCountPrefix),
        )
        .toList();
    for (final k in keys) await prefs.remove(k);
  }
}
