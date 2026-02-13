import 'package:http/http.dart' as http;
import 'dart:convert';

class AnimalHomeService {
  static const String SUPABASE_URL = 'https://dnvlqnixommhjqwpflmw.supabase.co';
  static const String SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRudmxxbml4b21taGpxd3BmbG13Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAzMzE1MDEsImV4cCI6MjA4NTkwNzUwMX0.sz5oI5lhecJ0DCJNByI3CIHFICHh2PBt5FHnrMfmDaE';

  /// Lấy tổng số lượng động vật theo loại
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
      print('📦 Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Fetched ${data.length} animals');

        // Debug: In ra 5 animals đầu tiên
        if (data.isNotEmpty) {
          print('📋 Sample data:');
          for (var i = 0; i < (data.length > 5 ? 5 : data.length); i++) {
            print('   ${i + 1}. ${data[i]}');
          }
        }

        Map<String, int> counts = {
          'dog': 0,
          'cat': 0,
          'bird': 0,
          'fish': 0,
          'reptile': 0,
          'mammal': 0,
        };

        for (var animal in data) {
          String type = animal['animal_type'] ?? '';
          if (counts.containsKey(type)) {
            counts[type] = counts[type]! + 1;
          }
        }

        print('📊 Final counts: $counts');
        return counts;
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('❌ Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception in getAnimalCounts: $e');
    }

    return {
      'dog': 0,
      'cat': 0,
      'bird': 0,
      'fish': 0,
      'reptile': 0,
      'mammal': 0,
    };
  }
}