// File: cache/daily_fact_cache.dart (ĐÃ CẬP NHẬT)
//
// THAY ĐỔI: Thêm Supabase shared cache cho facts
// Logic tương tự ảnh: người đầu tiên generate → lưu Supabase → mọi người sau đọc lại

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../screen/models/animal_data.dart';

class DailyFactCache {
  static final _supabase = Supabase.instance.client;
  static const String _table = 'daily_animal_facts';

  // Local cache keys (fallback khi offline)
  static const String _localCacheKey = 'daily_fact_cache_v2';
  static const String _localDateKey = 'daily_fact_date_v2';

  // ══════════════════════════════════════════════
  // ĐỌC: Check Supabase trước, fallback local
  // ══════════════════════════════════════════════
  static Future<AnimalFact?> getCache() async {
    final today = _todayString();

    // 1. Thử đọc từ Supabase shared cache
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('fact_date', today)
          .maybeSingle();

      if (response != null) {
        print('✅ [FactCache] Lấy facts từ Supabase');
        return AnimalFact.fromCache(Map<String, dynamic>.from(response));
      }
    } catch (e) {
      print('⚠️ [FactCache] Supabase không khả dụng, dùng local cache: $e');
    }

    // 2. Fallback: local SharedPreferences
    return _getLocalCache();
  }

  // ══════════════════════════════════════════════
  // LƯU: Lưu cả Supabase (shared) và local (offline)
  // ══════════════════════════════════════════════
  static Future<void> saveCache(AnimalFact fact) async {
    final today = _todayString();

    // Lưu Supabase (shared cho mọi user)
    try {
      await _supabase.from(_table).upsert(
        {
          'fact_date': today,
          ...fact.toCache(),
        },
        onConflict: 'fact_date',
      );
      print('✅ [FactCache] Đã lưu lên Supabase');
    } catch (e) {
      print('⚠️ [FactCache] Không lưu được Supabase: $e');
    }

    // Lưu local (backup khi offline)
    await _saveLocalCache(fact);
  }

  // ══════════════════════════════════════════════
  // LOCAL CACHE (backup)
  // ══════════════════════════════════════════════
  static Future<AnimalFact?> _getLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedDate = prefs.getString(_localDateKey);
    final today = _todayString();

    if (cachedDate != today) return null;

    final cachedData = prefs.getString(_localCacheKey);
    if (cachedData == null) return null;

    try {
      return AnimalFact.fromCache(json.decode(cachedData));
    } catch (e) {
      return null;
    }
  }

  static Future<void> _saveLocalCache(AnimalFact fact) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localCacheKey, json.encode(fact.toCache()));
    await prefs.setString(_localDateKey, _todayString());
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localCacheKey);
    await prefs.remove(_localDateKey);
  }

  static String _todayString() {
    return DateTime.now().toIso8601String().split('T')[0];
  }
}

/*
══════════════════════════════════════════════
SUPABASE SQL — Thêm vào script đã có:
══════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS daily_animal_facts (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  fact_date DATE NOT NULL UNIQUE,
  -- Thêm các fields từ AnimalFact.toCache() của bạn
  animal_name TEXT,
  vietnamese_name TEXT,
  scientific_name TEXT,
  habitat TEXT,
  speed TEXT,
  unique_fact1 TEXT,
  unique_fact2 TEXT,
  unique_fact3 TEXT,
  diet TEXT,
  conservation_status TEXT,
  fun_fact TEXT,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE daily_animal_facts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read facts" ON daily_animal_facts
  FOR SELECT USING (true);

CREATE POLICY "App insert facts" ON daily_animal_facts
  FOR INSERT WITH CHECK (true);

CREATE POLICY "App upsert facts" ON daily_animal_facts
  FOR UPDATE USING (true);
*/