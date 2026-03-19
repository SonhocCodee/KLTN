// File: services/daily_fact_cache.dart
//
// Cache 2 tầng cho Daily Fact:
//  Tầng 1 — Supabase (shared, tất cả users đều dùng chung)
//  Tầng 2 — SharedPreferences (local fallback khi offline)
//
// Bảng Supabase cần tạo:
// ─────────────────────────────────────────────────────────────
// CREATE TABLE IF NOT EXISTS daily_animal_facts (
//   id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
//   fact_date      DATE NOT NULL UNIQUE,
//   name_vi        TEXT,
//   name_en        TEXT,
//   scientific_name TEXT,
//   description    TEXT,
//   facts          TEXT[],      -- mảng JSON string các facts
//   image_url      TEXT,
//   category       TEXT,
//   created_at     TIMESTAMPTZ DEFAULT NOW()
// );
// ALTER TABLE daily_animal_facts ENABLE ROW LEVEL SECURITY;
// CREATE POLICY "Public read"   ON daily_animal_facts FOR SELECT USING (true);
// CREATE POLICY "App insert"    ON daily_animal_facts FOR INSERT WITH CHECK (true);
// CREATE POLICY "App update"    ON daily_animal_facts FOR UPDATE USING (true);
// ─────────────────────────────────────────────────────────────

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../screen/models/animal_data.dart';

class DailyFactCache {
  static final _supabase = Supabase.instance.client;
  static const String _table = 'daily_animal_facts';

  // Local cache keys
  static const String _localKey = 'daily_fact_v3';
  static const String _localDateKey = 'daily_fact_date_v3';

  // ──────────────────────────────────────────
  // ĐỌC CACHE
  // Thứ tự: Supabase → Local SharedPreferences
  // ──────────────────────────────────────────
  static Future<AnimalFact?> getCache() async {
    final today = _todayString();

    // 1. Supabase shared cache
    try {
      final row = await _supabase
          .from(_table)
          .select()
          .eq('fact_date', today)
          .maybeSingle();

      if (row != null) {
        print('✅ [FactCache] Đọc từ Supabase (ngày $today)');
        return _rowToFact(row);
      }
    } catch (e) {
      print('⚠️ [FactCache] Supabase offline: $e');
    }

    // 2. Local fallback
    return _getLocal();
  }

  // ──────────────────────────────────────────
  // LƯU CACHE
  // Lưu cả Supabase và Local
  // ──────────────────────────────────────────
  static Future<void> saveCache(AnimalFact fact) async {
    final today = _todayString();

    // Supabase
    try {
      await _supabase.from(_table).upsert(
        {
          'fact_date': today,
          ..._factToRow(fact),
        },
        onConflict: 'fact_date',
      );
      print('✅ [FactCache] Đã lưu Supabase');
    } catch (e) {
      print('⚠️ [FactCache] Không lưu được Supabase: $e');
    }

    // Local backup
    await _saveLocal(fact);
  }

  // ──────────────────────────────────────────
  // XÓA CACHE (dùng khi force refresh)
  // ──────────────────────────────────────────
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localKey);
    await prefs.remove(_localDateKey);
    print('🗑️ [FactCache] Đã xóa local cache');
    // Không xóa Supabase để không ảnh hưởng user khác
  }

  // ──────────────────────────────────────────
  // PRIVATE HELPERS
  // ──────────────────────────────────────────

  static AnimalFact _rowToFact(Map<String, dynamic> row) {
    // facts được lưu dưới dạng List<String> (PostgreSQL TEXT[])
    List<String> facts = [];
    final rawFacts = row['facts'];
    if (rawFacts is List) {
      facts = rawFacts.map((e) => e.toString()).toList();
    } else if (rawFacts is String) {
      // fallback nếu lưu dưới dạng JSON string
      try {
        final decoded = json.decode(rawFacts);
        if (decoded is List) {
          facts = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return AnimalFact(
      name: row['name_vi'] as String? ?? '',
      englishName: row['name_en'] as String? ?? '',
      scientificName: row['scientific_name'] as String? ?? '',
      description: row['description'] as String? ?? '',
      facts: facts,
      imageUrl: row['image_url'] as String? ?? '',
      category: row['category'] as String? ?? '',
    );
  }

  static Map<String, dynamic> _factToRow(AnimalFact fact) {
    return {
      'name_vi': fact.name,
      'name_en': fact.englishName,
      'scientific_name': fact.scientificName,
      'description': fact.description,
      'facts': fact.facts,        // Supabase tự handle List<String> → TEXT[]
      'image_url': fact.imageUrl,
      'category': fact.category,
    };
  }

  // LOCAL ───────────────────────────────────
  static Future<AnimalFact?> _getLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDate = prefs.getString(_localDateKey);
      if (savedDate != _todayString()) return null;

      final data = prefs.getString(_localKey);
      if (data == null) return null;

      final map = json.decode(data) as Map<String, dynamic>;
      return AnimalFact(
        name: map['name_vi'] as String? ?? '',
        englishName: map['name_en'] as String? ?? '',
        scientificName: map['scientific_name'] as String? ?? '',
        description: map['description'] as String? ?? '',
        facts: (map['facts'] as List?)?.map((e) => e.toString()).toList() ?? [],
        imageUrl: map['image_url'] as String? ?? '',
        category: map['category'] as String? ?? '',
      );
    } catch (e) {
      print('⚠️ [FactCache] Lỗi đọc local: $e');
      return null;
    }
  }

  static Future<void> _saveLocal(AnimalFact fact) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localKey, json.encode(_factToRow(fact)));
      await prefs.setString(_localDateKey, _todayString());
    } catch (e) {
      print('⚠️ [FactCache] Lỗi lưu local: $e');
    }
  }

  static String _todayString() =>
      DateTime.now().toIso8601String().split('T')[0];
}