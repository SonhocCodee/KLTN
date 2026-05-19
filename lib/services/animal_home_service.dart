import 'package:http/http.dart' as http;
import 'dart:convert';

class AnimalHomeService {
  static const String _url = 'https://dnvlqnixommhjqwpflmw.supabase.co';
  static const String _key =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRudmxxbml4b21taGpxd3BmbG13Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAzMzE1MDEsImV4cCI6MjA4NTkwNzUwMX0.sz5oI5lhecJ0DCJNByI3CIHFICHh2PBt5FHnrMfmDaE';

  static const Map<String, String> _headers = {
    'apikey': _key,
    'Authorization': 'Bearer $_key',
    'Content-Type': 'application/json',
  };

  // ── Helper ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _get(String endpoint) async {
    try {
      final res = await http
          .get(Uri.parse('$_url/rest/v1/$endpoint'), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(res.body));
      }
      debugPrint('❌ HTTP ${res.statusCode}: ${res.body}');
    } catch (e) {
      debugPrint('❌ Exception: $e');
    }
    return [];
  }

  // ── Counts (cho home screen) ──────────────────────────────────────────────

  /// Trả về {'mammal': 5, 'bird': 3, ...}
  Future<Map<String, int>> getAnimalCounts() async {
    final data = await _get('animals?select=animal_type');
    final counts = <String, int>{};
    for (final a in data) {
      final type = (a['animal_type'] ?? '') as String;
      if (type.isNotEmpty) counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  // ── List theo type ────────────────────────────────────────────────────────

  /// Lấy danh sách động vật theo animal_type, có phân trang
  Future<List<Map<String, dynamic>>> getAnimalsByType(
      String animalType, {
        int limit = 50,
        int offset = 0,
      }) async {
    return _get(
      'animals'
          '?animal_type=eq.$animalType'
          '&select=id,name_vietnamese,name_english,scientific_name,'
          'image_url,conservation_status,is_endangered,primary_habitat'
          '&order=name_vietnamese.asc'
          '&limit=$limit&offset=$offset',
    );
  }

  // ── Detail ────────────────────────────────────────────────────────────────

  /// Lấy toàn bộ field của 1 con theo id
  Future<Map<String, dynamic>?> getAnimalById(String animalId) async {
    final data = await _get('animals?id=eq.$animalId&select=*');
    return data.isNotEmpty ? data.first : null;
  }

  // ── Search ────────────────────────────────────────────────────────────────

  /// Tìm theo tên Việt hoặc tên Anh, không phân biệt hoa thường
  Future<List<Map<String, dynamic>>> searchAnimals(
      String query, {
        int limit = 30,
      }) async {
    if (query.trim().isEmpty) return [];
    final q = Uri.encodeComponent(query.trim());
    return _get(
      'animals'
          '?or=(name_vietnamese.ilike.*$q*,name_english.ilike.*$q*,scientific_name.ilike.*$q*)'
          '&select=id,name_vietnamese,name_english,scientific_name,'
          'image_url,conservation_status,is_endangered,animal_type,primary_habitat'
          '&limit=$limit',
    );
  }

  // ── Filter ────────────────────────────────────────────────────────────────

  /// Filter nhiều điều kiện cùng lúc (cho trang filter/explore)
  Future<List<Map<String, dynamic>>> filterAnimals({
    String? animalType,
    String? habitat,
    String? conservationStatus,
    bool? isEndangered,
    String? dietType,
    int limit = 50,
    int offset = 0,
  }) async {
    final filters = <String>[];
    if (animalType != null) filters.add('animal_type=eq.$animalType');
    if (habitat != null) filters.add('primary_habitat=eq.$habitat');
    if (conservationStatus != null) {
      filters.add('conservation_status=eq.$conservationStatus');
    }
    if (isEndangered != null) {
      filters.add('is_endangered=eq.$isEndangered');
    }
    if (dietType != null) filters.add('diet_type=eq.$dietType');

    final query = filters.isEmpty ? '' : '&${filters.join('&')}';
    return _get(
      'animals'
          '?select=id,name_vietnamese,name_english,scientific_name,'
          'image_url,conservation_status,is_endangered,animal_type,primary_habitat'
          '$query'
          '&order=name_vietnamese.asc'
          '&limit=$limit&offset=$offset',
    );
  }

  // ── Statistics ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getStatistics() async {
    final counts = await getAnimalCounts();
    int total = 0;
    counts.forEach((_, c) => total += c);
    return {
      'total_animals': total,
      'total_types': counts.length,
      'counts_by_type': counts,
    };
  }

  // ── Endangered list ───────────────────────────────────────────────────────

  /// Danh sách các loài đang nguy cấp (cho widget highlight)
  Future<List<Map<String, dynamic>>> getEndangeredAnimals({
    int limit = 10,
  }) async {
    return _get(
      'animals'
          '?is_endangered=eq.true'
          '&select=id,name_vietnamese,name_english,image_url,conservation_status,animal_type'
          '&order=conservation_status.asc'
          '&limit=$limit',
    );
  }

  // ── Random ────────────────────────────────────────────────────────────────

  /// Lấy ngẫu nhiên n con (dùng cho "Khám phá ngẫu nhiên")
  Future<List<Map<String, dynamic>>> getRandomAnimals({int limit = 5}) async {
    // Supabase REST không có random() trực tiếp, dùng order=random workaround
    return _get(
      'animals'
          '?select=id,name_vietnamese,name_english,scientific_name,'
          'image_url,conservation_status,is_endangered,animal_type'
          '&limit=$limit',
    );
  }
}

// ignore: avoid_print
void debugPrint(String msg) => print(msg);