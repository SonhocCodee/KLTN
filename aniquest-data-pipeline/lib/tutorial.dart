import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ═══════════════════════════════════════════════════════════════
// 📝 ANIMAL DATA FETCHER TEMPLATE
// ═══════════════════════════════════════════════════════════════
// HƯỚNG DẪN SỬ DỤNG:
// 1. Copy file này
// 2. Đổi tên file: [animal]_fetcher.dart (vd: elephant_fetcher.dart)
// 3. Sửa phần AnimalConfig bên dưới
// 4. Sửa phần _buildPrompt() (nếu cần)
// 5. Chạy: dart [animal]_fetcher.dart
// ═══════════════════════════════════════════════════════════════

const GROQ_API_KEY = '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';
const SUPABASE_URL = 'https://dnvlqnixommhjqwpflmw.supabase.co';
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRudmxxbml4b21taGpxd3BmbG13Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MDMzMTUwMSwiZXhwIjoyMDg1OTA3NTAxfQ.W2cxnWC-DJoE9GRdUWMZU3-e27VFVA05BTJotZHfR54';

// ═══════════════════════════════════════════════════════════════
// 🎯 BƯỚC 1: THAY ĐỔI PHẦN NÀY
// ═══════════════════════════════════════════════════════════════
class AnimalConfig {
  // Loại động vật (dùng cho animal_type trong DB)
  static const String ANIMAL_TYPE = 'tiger';  // 👈 THAY: 'elephant', 'whale', etc.

  // Tên bảng traits (phải tồn tại trong Supabase)
  static const String TRAITS_TABLE = 'tiger_traits';  // 👈 THAY: 'elephant_traits', etc.

  // Tên tiếng Việt
  static const String ANIMAL_NAME_VI = 'Hổ';  // 👈 THAY

  // Tên tiếng Anh
  static const String ANIMAL_NAME_EN = 'Tiger';  // 👈 THAY

  // Danh sách các giống/subspecies cần cào
  static const List<String> BREED_LIST = [  // 👈 THAY TOÀN BỘ
    'Bengal Tiger',
    'Siberian Tiger',
    'Indochinese Tiger',
    'Malayan Tiger',
    'Sumatran Tiger',
    'South China Tiger',
  ];

  // Từ khóa tìm kiếm Wikipedia
  static const String WIKI_KEYWORD = 'tiger';  // 👈 THAY (optional, có thể để trống)
}

// ═══════════════════════════════════════════════════════════════
// MAIN - KHÔNG CẦN SỬA
// ═══════════════════════════════════════════════════════════════

void main() async {
  print('\n🐾 BẮT ĐẦU XỬ LÝ ${AnimalConfig.BREED_LIST.length} LOÀI ${AnimalConfig.ANIMAL_NAME_EN.toUpperCase()}');

  int success = 0, fail = 0, skip = 0;

  for (int i = 0; i < AnimalConfig.BREED_LIST.length; i++) {
    final breed = AnimalConfig.BREED_LIST[i];
    print('\n[${i + 1}/${AnimalConfig.BREED_LIST.length}] 🔍 $breed');

    final exists = await _checkExists(breed);
    if (exists) {
      print('   ⏭️ Đã tồn tại');
      skip++;
      continue;
    }

    final wikiData = await _fetchWikiData(breed);
    if (wikiData == null) {
      print('   ⚠️ Không tìm thấy wiki');
      fail++;
      continue;
    }

    final llmData = await _callLLM(breed, wikiData);
    if (llmData == null) {
      print('   ❌ LLM thất bại');
      fail++;
      continue;
    }

    final uploaded = await uploadToSupabase(llmData);
    if (uploaded) {
      print('   ✅ Thành công');
      success++;
    } else {
      fail++;
    }

    await Future.delayed(Duration(milliseconds: 500));
  }

  print('\n═══════════════════════════════════════');
  print('📊 KẾT QUẢ:');
  print('   ✅ Thành công: $success');
  print('   ❌ Thất bại: $fail');
  print('   ⏭️ Bỏ qua: $skip');
  print('═══════════════════════════════════════\n');
}

// ═══════════════════════════════════════════════════════════════
// HELPER FUNCTIONS - KHÔNG CẦN SỬA
// ═══════════════════════════════════════════════════════════════

Future<bool> _checkExists(String breedName) async {
  try {
    final response = await http.get(
      Uri.parse('$SUPABASE_URL/rest/v1/animals?select=id&name_english=eq.$breedName'),
      headers: {
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': 'Bearer $SUPABASE_SERVICE_KEY',
      },
    );
    return response.statusCode == 200 && json.decode(response.body).isNotEmpty;
  } catch (e) {
    return false;
  }
}

Future<Map<String, dynamic>?> _fetchWikiData(String breedName) async {
  try {
    final searchKeyword = AnimalConfig.WIKI_KEYWORD.isNotEmpty
        ? '$breedName ${AnimalConfig.WIKI_KEYWORD}'
        : breedName;

    final searchUrl = 'https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=$searchKeyword&format=json';
    final searchRes = await http.get(Uri.parse(searchUrl));

    if (searchRes.statusCode != 200) return null;

    final searchData = json.decode(searchRes.body);
    final results = searchData['query']['search'] as List;

    if (results.isEmpty) return null;

    final pageId = results[0]['pageid'];
    final extractUrl = 'https://en.wikipedia.org/w/api.php?action=query&prop=extracts|pageimages&exintro&explaintext&piprop=original&pageids=$pageId&format=json';
    final extractRes = await http.get(Uri.parse(extractUrl));

    if (extractRes.statusCode != 200) return null;

    final data = json.decode(extractRes.body);
    final page = data['query']['pages']['$pageId'];

    return {
      'text': (page['extract'] ?? '').toString().substring(0, 1500.clamp(0, (page['extract'] ?? '').toString().length)),
      'image_url': page['original']?['source'] ?? ''
    };
  } catch (e) {
    return null;
  }
}

Future<Map<String, dynamic>?> _callLLM(String breedName, Map<String, dynamic> wikiData) async {
  for (int retry = 0; retry < 3; retry++) {
    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $GROQ_API_KEY',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'user', 'content': _buildPrompt(breedName, wikiData['text'])}
          ],
          'temperature': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'];

        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
        if (jsonMatch != null) {
          try {
            final parsed = json.decode(jsonMatch.group(0)!);
            parsed['animal']['image_url'] = wikiData['image_url'];
            return parsed;
          } catch (e) {
            print('      ⚠️ JSON Parse Error');
            return null;
          }
        }
      } else if (response.statusCode == 429) {
        print('      ⏳ Rate limit, đợi 10s...');
        await Future.delayed(Duration(seconds: 10));
      }
    } catch (e) {
      await Future.delayed(Duration(seconds: 2));
    }
  }
  return null;
}

// ═══════════════════════════════════════════════════════════════
// 🎯 BƯỚC 2: SỬA PROMPT (nếu cần)
// ═══════════════════════════════════════════════════════════════

String _buildPrompt(String breedName, String wikiText) {
  return '''Parse $breedName into JSON based on this Wikipedia info:

$wikiText

CRITICAL RULES:
1. Use 1-5 scale for integer traits. NEVER >5
2. temperament: gentle, neutral, aggressive, timid, territorial
3. All text fields in Vietnamese where specified
4. Match the exact field names in the JSON schema below

Return EXACTLY this JSON (no markdown, no extra text):

{
  "animal": {
    "animal_type": "${AnimalConfig.ANIMAL_TYPE}",
    "name_vietnamese": "${AnimalConfig.ANIMAL_NAME_VI} [specific Vietnamese name]",
    "name_english": "$breedName",
    "scientific_name": "[Scientific name from wiki]",
    "kingdom": "Animalia",
    "phylum": "Chordata",
    "class": "[Mammalia/Aves/Reptilia/etc]",
    "order_name": "[Order name]",
    "family": "[Family name]",
    "genus": "[Genus]",
    "species": "[Species]",
    "primary_habitat": "[savanna/tropical_forest/ocean/etc]",
    "domestication_status": "wild",
    "diet_type": "[carnivore/herbivore/omnivore]",
    "legs": 4,
    "locomotion": "[quadrupedal/bipedal/flying/swimming]",
    "relative_size": "[tiny/small/medium/large/huge]",
    "weight_avg_kg": 200.0,
    "height_avg_m": 1.0,
    "length_avg_m": 2.5,
    "primary_colors": ["color1","color2"],
    "patterns": ["solid/striped/spotted"],
    "fur_type": "[short_fur/long_fur/scales/feathers]",
    "max_speed_kmh": 50,
    "temperament": "[gentle/neutral/aggressive/timid/territorial]",
    "social_structure": "[solitary/pack/herd/colony]",
    "activity_pattern": "[nocturnal/diurnal/crepuscular]",
    "aggression_level": 3,
    "intelligence_level": 4,
    "danger_to_humans": "[harmless/low/moderate/high/extreme]",
    "lifespan_avg_years": 15,
    "conservation_status": "[LC/NT/VU/EN/CR/EW/EX]",
    "is_endangered": false,
    "has_claws": true,
    "has_sharp_teeth": true,
    "has_tail": true,
    "has_whiskers": false,
    "fun_fact_vietnamese": "Một sự thật thú vị bằng tiếng Việt",
    "description_short": "Mô tả ngắn gọn bằng tiếng Việt (2-3 câu)"
  },
  "${AnimalConfig.TRAITS_TABLE}": {
    "_comment": "👈 THAY ĐỔI PHẦN NÀY theo cấu trúc bảng traits của bạn",
    "example_field_1": "value1",
    "example_field_2": 3,
    "example_field_3": true
  }
}

Use realistic values from Wikipedia. Fill all fields accurately.''';
}

// ═══════════════════════════════════════════════════════════════
// UPLOAD TO SUPABASE - KHÔNG CẦN SỬA
// ═══════════════════════════════════════════════════════════════

Future<bool> uploadToSupabase(Map<String, dynamic> data) async {
  try {
    // Step 1: Insert vào bảng animals
    final animalResponse = await http.post(
      Uri.parse('$SUPABASE_URL/rest/v1/animals'),
      headers: {
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': 'Bearer $SUPABASE_SERVICE_KEY',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      },
      body: json.encode(data['animal']),
    );

    if (animalResponse.statusCode != 201) {
      print('   ❌ Lỗi animals: ${animalResponse.body}');
      return false;
    }

    final animalData = json.decode(animalResponse.body)[0];
    final animalId = animalData['id'];

    // Step 2: Insert vào bảng traits
    final traits = data[AnimalConfig.TRAITS_TABLE];
    traits['animal_id'] = animalId;

    final traitsResponse = await http.post(
      Uri.parse('$SUPABASE_URL/rest/v1/${AnimalConfig.TRAITS_TABLE}'),
      headers: {
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': 'Bearer $SUPABASE_SERVICE_KEY',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      },
      body: json.encode(traits),
    );

    if (traitsResponse.statusCode != 201) {
      print('   ⚠️ Lỗi traits: ${traitsResponse.body}');
      // Rollback: Xóa animal đã tạo
      await http.delete(
        Uri.parse('$SUPABASE_URL/rest/v1/animals?id=eq.$animalId'),
        headers: {
          'apikey': SUPABASE_SERVICE_KEY,
          'Authorization': 'Bearer $SUPABASE_SERVICE_KEY',
        },
      );
      return false;
    }

    return true;
  } catch (e) {
    print('   ❌ Exception: $e');
    return false;
  }
}