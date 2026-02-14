import 'package:http/http.dart' as http;
import 'dart:convert';

class AnimalHomeService {
  static const String SUPABASE_URL = 'https://dnvlqnixommhjqwpflmw.supabase.co';
  static const String SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRudmxxbml4b21taGpxd3BmbG13Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAzMzE1MDEsImV4cCI6MjA4NTkwNzUwMX0.sz5oI5lhecJ0DCJNByI3CIHFICHh2PBt5FHnrMfmDaE';

  /// Lấy tổng số lượng động vật theo loại
  ///
  /// Trả về Map<String, int> với key là animal_type và value là số lượng
  /// Ví dụ: {'dog': 75, 'cat': 30, 'tiger': 6, 'lion': 5, ...}
  Future<Map<String, int>> getAnimalCounts() async {
    try {
      print('🔍 Fetching animal counts...');
      print('🌐 URL: $SUPABASE_URL/rest/v1/animals?select=animal_type');

      final response = await http.get(
        Uri.parse('$SUPABASE_URL/rest/v1/animals?select=animal_type'),
        headers: {
          'apikey': SUPABASE_KEY,
          'Authorization': 'Bearer $SUPABASE_KEY',
        },
      );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Fetched ${data.length} animals from database');

        // Đếm số lượng theo animal_type
        Map<String, int> counts = {};

        for (var animal in data) {
          String type = animal['animal_type'] ?? '';
          if (type.isNotEmpty) {
            counts[type] = (counts[type] ?? 0) + 1;
          }
        }

        // Debug: In ra kết quả đếm
        print('📊 Animal counts by type:');
        counts.forEach((type, count) {
          print('   • $type: $count');
        });

        return counts;
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('❌ Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception in getAnimalCounts: $e');
    }

    // Trả về map rỗng nếu có lỗi
    return {};
  }

  /// Lấy danh sách động vật theo loại (cho màn hình chi tiết)
  ///
  /// Ví dụ: getAnimalsByType('dog') → List tất cả chó
  Future<List<Map<String, dynamic>>> getAnimalsByType(String animalType) async {
    try {
      print('🔍 Fetching animals of type: $animalType');

      final response = await http.get(
        Uri.parse('$SUPABASE_URL/rest/v1/animals?animal_type=eq.$animalType&select=*'),
        headers: {
          'apikey': SUPABASE_KEY,
          'Authorization': 'Bearer $SUPABASE_KEY',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Found ${data.length} $animalType(s)');
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in getAnimalsByType: $e');
    }

    return [];
  }

  /// Lấy thông tin chi tiết 1 động vật theo ID
  Future<Map<String, dynamic>?> getAnimalById(String animalId) async {
    try {
      print('🔍 Fetching animal with id: $animalId');

      final response = await http.get(
        Uri.parse('$SUPABASE_URL/rest/v1/animals?id=eq.$animalId&select=*'),
        headers: {
          'apikey': SUPABASE_KEY,
          'Authorization': 'Bearer $SUPABASE_KEY',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          print('✅ Found animal: ${data[0]['name_english']}');
          return data[0];
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in getAnimalById: $e');
    }

    return null;
  }

  /// Tìm kiếm động vật theo tên (Vietnamese hoặc English)
  Future<List<Map<String, dynamic>>> searchAnimals(String query) async {
    try {
      print('🔍 Searching animals with query: $query');

      // Tìm kiếm theo cả name_vietnamese và name_english
      final response = await http.get(
        Uri.parse(
            '$SUPABASE_URL/rest/v1/animals?or=(name_vietnamese.ilike.*$query*,name_english.ilike.*$query*)&select=*'
        ),
        headers: {
          'apikey': SUPABASE_KEY,
          'Authorization': 'Bearer $SUPABASE_KEY',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Found ${data.length} results for "$query"');
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in searchAnimals: $e');
    }

    return [];
  }

  /// Lấy thống kê tổng quan
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final counts = await getAnimalCounts();

      int totalAnimals = 0;
      counts.forEach((_, count) => totalAnimals += count);

      return {
        'total_animals': totalAnimals,
        'total_types': counts.length,
        'counts_by_type': counts,
      };
    } catch (e) {
      print('❌ Exception in getStatistics: $e');
      return {
        'total_animals': 0,
        'total_types': 0,
        'counts_by_type': {},
      };
    }
  }
}