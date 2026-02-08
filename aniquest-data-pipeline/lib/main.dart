import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ═══════════════════════════════════════════════════════
// CẤU HÌNH
// ═══════════════════════════════════════════════════════

const GROQ_API_KEY = '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';
const SUPABASE_URL = 'https://dnvlqnixommhjqwpflmw.supabase.co';
const SUPABASE_KEY = 'sb_publishable_ekHCVhUZ3t5vkJKyV9qxyw_j17TzJB6';

// 📋 DANH SÁCH 75 GIỐNG MÈO NHÀ
// 📋 DANH SÁCH CÁC GIỐNG MÈO BỊ LỖI CẦN CHẠY LẠI
const ALL_CAT_BREEDS = [
  'American Wirehair',
  'Arabian Mau',
  'Bambino',
  'Brazilian Shorthair',
  'British Longhair',
  'Burmilla',
  'Chausie',
  'Cheetoh',
  'Colorpoint Shorthair',
  'Cornish Rex',
  'Dragon Li',
  'European Burmese',
  'Exotic Shorthair',
  'Khao Manee',
  'LaPerm',
  'Norwegian Forest Cat',
  'Ocicat',
  'Oriental Longhair',
  'Peterbald',
  'Sokoke',
  'Toyger',
  'Turkish Angora',
  'York Chocolate',
  'Lykoi'
];

// ═══════════════════════════════════════════════════════
// MAIN FUNCTION
// ═══════════════════════════════════════════════════════

void main() async {
  print('\n╔════════════════════════════════════════════╗');
  print('║    🐱 ANIQUEST - SMART CAT IMPORTER        ║');
  print('╚════════════════════════════════════════════╝\n');

  int success = 0;
  int skipped = 0;
  int failed = 0;

  List<String> failedList = [];

  for (var i = 0; i < ALL_CAT_BREEDS.length; i++) {
    final breedName = ALL_CAT_BREEDS[i];

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('[${i + 1}/${ALL_CAT_BREEDS.length}] 🐈 Checking: $breedName');

    // 1. KIỂM TRA ĐÃ CÓ TRONG DB CHƯA
    bool exists = await checkIfExist(breedName);
    if (exists) {
      print('   ⚠️ Đã có trong Database -> BỎ QUA');
      skipped++;
      continue;
    }

    try {
      // 2. Wikipedia (SMART FETCH)
      print('   📚 Đang tìm trên Wikipedia...');
      // Tìm kiếm thông minh: Thử tên gốc trước, nếu không được thì thử thêm "cat"
      var wikiData = await fetchWikipediaSmart(breedName);

      if (wikiData == null) {
        // Thử lại lần 2 với từ khóa "cat"
        wikiData = await fetchWikipediaSmart('$breedName cat');
      }

      if (wikiData == null) {
        print('   ❌ Không tìm thấy trang Wiki phù hợp');
        failed++;
        failedList.add('$breedName (Wiki Not Found)');
        continue;
      }

      print('      ✅ Đã tìm thấy trang: "${wikiData['title']}"');

      // 3. Groq AI
      print('   🤖 Đang nhờ AI phân tích...');
      final structuredData = await parseWithGroq(breedName, wikiData);

      if (structuredData == null) {
        print('   ❌ AI lỗi parse JSON');
        failed++;
        failedList.add('$breedName (AI Error)');
        continue;
      }

      structuredData['image_url'] = wikiData['image_url'];

      // 4. Upload
      print('   📤 Đang lưu vào Supabase...');
      bool uploaded = await uploadToSupabase(structuredData);

      if (uploaded) {
        success++;
        print('   🎉 THÀNH CÔNG!');
      } else {
        failed++;
        failedList.add('$breedName (Upload Failed)');
      }

      // Nghỉ 2 giây để an toàn
      await Future.delayed(Duration(milliseconds: 2000));

    } catch (e) {
      print('   ❌ Lỗi ngoại lệ: $e');
      failed++;
      failedList.add('$breedName (Exception: $e)');
    }
  }

  print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('📊 TỔNG KẾT:');
  print('   ✅ Mới thêm:  $success');
  print('   ⏭️  Đã có sẵn: $skipped');
  print('   ❌ Thất bại:   $failed');

  if (failedList.isNotEmpty) {
    print('\n⚠️  DANH SÁCH LỖI:');
    for (var item in failedList) {
      print('   ❌ $item');
    }
  }
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
}

// ═══════════════════════════════════════════════════════
// HÀM KIỂM TRA TỒN TẠI
// ═══════════════════════════════════════════════════════
Future<bool> checkIfExist(String name) async {
  try {
    final url = '$SUPABASE_URL/rest/v1/animals?name_english=eq.${Uri.encodeComponent(name)}&select=id';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': 'Bearer $SUPABASE_KEY',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.isNotEmpty;
    }
  } catch (e) {}
  return false;
}

// ═══════════════════════════════════════════════════════
// HÀM FETCH WIKI THÔNG MINH (SỬA LỖI TÌM KIẾM)
// ═══════════════════════════════════════════════════════
Future<Map<String, dynamic>?> fetchWikipediaSmart(String query) async {
  try {
    // BƯỚC 1: Dùng OpenSearch để tìm đúng tên trang (Title chính xác)
    // Ví dụ: Gõ "American Wirehair cat" -> Nó trả về "American Wirehair"
    final searchUrl = 'https://en.wikipedia.org/w/api.php?action=opensearch&search=${Uri.encodeComponent(query)}&limit=1&namespace=0&format=json';
    final searchRes = await http.get(Uri.parse(searchUrl));

    String correctTitle = query;
    if (searchRes.statusCode == 200) {
      final searchData = json.decode(searchRes.body) as List;
      if (searchData.length > 1 && (searchData[1] as List).isNotEmpty) {
        correctTitle = searchData[1][0]; // Lấy title chuẩn từ Wiki
      } else {
        // Nếu opensearch không ra, thử query gốc
        correctTitle = query;
      }
    }

    // BƯỚC 2: Lấy nội dung dựa trên Title chuẩn
    final contentUrl = 'https://en.wikipedia.org/w/api.php?action=query&titles=${Uri.encodeComponent(correctTitle)}&prop=extracts|pageimages&exintro=true&explaintext=true&piprop=original&format=json';
    final contentRes = await http.get(Uri.parse(contentUrl));

    if (contentRes.statusCode == 200) {
      final data = json.decode(contentRes.body);
      final pages = data['query']['pages'];
      final pageId = pages.keys.first;

      if (pageId == "-1") return null;

      final page = pages[pageId];
      if (page['extract'] == null || page['extract'].toString().isEmpty) return null;

      return {
        'title': page['title'],
        'extract': page['extract'],
        'image_url': page['original']?['source'],
      };
    }
  } catch (e) {
    print('      ⚠️ Lỗi Wiki: $e');
  }
  return null;
}

// ═══════════════════════════════════════════════════════
// FUNCTION 2: PARSE WITH GROQ AI (DEBUG MODE - SHOW RAW ERROR)
// ═══════════════════════════════════════════════════════
Future<Map<String, dynamic>?> parseWithGroq(
    String animalName,
    Map<String, dynamic> wikiData,
    ) async {

  final prompt = '''
You are a zoology expert. Parse this Wikipedia extract into structured JSON.
Animal: $animalName
Wiki Title: ${wikiData['title']}
Wiki Text:
${wikiData['extract']}

CRITICAL INSTRUCTIONS:
1. **MISSING DATA:** Use general knowledge to ESTIMATE numeric data (weight, height, lifespan) if missing. Do NOT use null for common metrics.
2. **FORCE VALUES:** - "primary_habitat": "domestic"
   - "diet_type": "carnivore"
3. **SOCIAL STRUCTURE:** Choose "social_structure" from ["solitary", "pair", "small_group", "herd", "pack", "colony"] based on the wiki text. For domestic cats, default to "solitary" if unclear.
4. **JSON ONLY:** Return valid JSON. Do NOT include markdown code blocks (```json). Do NOT add explanations.

Return JSON Structure:
{
  "name_vietnamese": "Tên tiếng Việt",
  "name_english": "$animalName",
  "scientific_name": "Felis catus",
  "class": "Mammalia", "order_name": "Carnivora", "family": "Felidae",
  "primary_habitat": "domestic",
  "diet_type": "carnivore",
  "legs": 4, "locomotion": "quadrupedal", "size_category": "small",
  "weight_avg_kg": number,
  "height_avg_m": number,
  "length_avg_m": number,
  "primary_colors": ["color1"],
  "patterns": ["solid"],
  "max_speed_kmh": 48,
  "speed_category": "fast",
  "has_horns": false, "has_tusks": false, "has_trunk": false, "has_mane": false,
  "has_wings": false, "has_fins": false, "has_claws": true, "has_sharp_teeth": true,
  "temperament": "affectionate",
  "social_structure": "solitary",
  "activity_pattern": "crepuscular",
  "aggression_level": 2,
  "intelligence_level": 7,
  "danger_to_humans": "harmless",
  "lifespan_avg_years": 14,
  "conservation_status": "Domesticated",
  "is_endangered": false,
  "fun_fact_vietnamese": "Fact tiếng Việt",
  "description_short": "Mô tả ngắn tiếng Việt"
}
''';

  for (int attempt = 0; attempt < 3; attempt++) {
    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $GROQ_API_KEY',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [{'role': 'user', 'content': prompt}],
          'temperature': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'];

        // 🛑 DEBUG: In ra nội dung AI trả về trước khi xử lý
        // (Chỉ bật cái này nếu muốn xem tất cả, còn không thì xem đoạn catch bên dưới)

        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
        if (jsonMatch != null) {
          try {
            return json.decode(jsonMatch.group(0)!);
          } catch (e) {
            print('      ❌ JSON PARSE ERROR (Cú pháp sai): $e');
            print('      📄 RAW CONTENT TỪ AI:');
            print('      --------------------------------------------------');
            print(content); // <--- QUAN TRỌNG: Xem nó sai chỗ nào
            print('      --------------------------------------------------');
            return null;
          }
        } else {
          print('      ❌ KHÔNG TÌM THẤY JSON TRONG CÂU TRẢ LỜI');
          print('      📄 RAW CONTENT TỪ AI:');
          print('      --------------------------------------------------');
          print(content); // <--- QUAN TRỌNG
          print('      --------------------------------------------------');
          return null;
        }
      }
      else if (response.statusCode == 429) {
        print('      ⚠️ Hết quota (429). Đợi 10s thử lại...');
        await Future.delayed(Duration(seconds: 10));
      } else {
        print('      ❌ HTTP ERROR: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('      ⚠️ Lỗi kết nối (Thử lại): $e');
      await Future.delayed(Duration(seconds: 2));
    }
  }
  return null;
}

// ═══════════════════════════════════════════════════════
// UPLOAD SUPABASE
// ═══════════════════════════════════════════════════════
Future<bool> uploadToSupabase(Map<String, dynamic> animal) async {
  try {
    final response = await http.post(
      Uri.parse('$SUPABASE_URL/rest/v1/animals'),
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': 'Bearer $SUPABASE_KEY',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      },
      body: json.encode(animal),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      print('   ❌ Lỗi Upload Supabase: ${response.body}');
      return false;
    }
  } catch (e) {
    print('   ❌ Lỗi mạng Upload: $e');
    return false;
  }
}