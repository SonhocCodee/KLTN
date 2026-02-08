
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ═══════════════════════════════════════════════════════
// CẤU HÌNH - THAY ĐỔI Ở ĐÂY
// ═══════════════════════════════════════════════════════

// 1. Groq API Key (https://console.groq.com/)
const GROQ_API_KEY = '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'; // ← PASTE KEY

// 2. Supabase Config (https://supabase.com/dashboard)
const SUPABASE_URL = 'https://dnvlqnixommhjqwpflmw.supabase.co'; // ← PASTE URL
const SUPABASE_KEY = 'sb_publishable_ekHCVhUZ3t5vkJKyV9qxyw_j17TzJB6'; // ← PASTE KEY

// 3. Danh sách động vật để test (5 con đầu)
const TEST_ANIMALS = [
  'Lion',
  'Tiger',
  'African Elephant',
  'Bottlenose Dolphin',
  'Emperor Penguin',
];

// ═══════════════════════════════════════════════════════
// MAIN FUNCTION
// ═══════════════════════════════════════════════════════

void main() async {
  print('\n');
  print('╔════════════════════════════════════════════╗');
  print('║   ANIQUEST DATA PIPELINE - GROQ FREE       ║');
  print('╚════════════════════════════════════════════╝');
  print('\n');

  // Validate config
  if (GROQ_API_KEY == 'gsk_YOUR_KEY_HERE') {
    print('❌ ERROR: Chưa cấu hình GROQ_API_KEY!');
    print('   Vào https://console.groq.com/ để lấy key');
    return;
  }

  if (SUPABASE_URL == 'https://xxx.supabase.co') {
    print('❌ ERROR: Chưa cấu hình SUPABASE_URL!');
    print('   Vào Supabase Dashboard → Settings → API');
    return;
  }

  // Tạo folder output
  final outputDir = Directory('output');
  if (!outputDir.existsSync()) {
    outputDir.createSync();
  }

  print('📋 Sẽ xử lý ${TEST_ANIMALS.length} động vật\n');

  final allData = <Map<String, dynamic>>[];
  int successCount = 0;
  int failCount = 0;

  for (var i = 0; i < TEST_ANIMALS.length; i++) {
    final animalName = TEST_ANIMALS[i];

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('[${i + 1}/${TEST_ANIMALS.length}] 🦁 $animalName');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      // BƯỚC 1: Fetch Wikipedia
      print('  📚 Fetching Wikipedia...');
      final wikiData = await fetchWikipedia(animalName);

      if (wikiData == null) {
        print('  ❌ Wikipedia failed\n');
        failCount++;
        continue;
      }

      print('  ✅ Wikipedia OK');

      // BƯỚC 2: Parse với Groq AI
      print('  🤖 Parsing with Groq AI...');
      final structuredData = await parseWithGroq(animalName, wikiData);

      if (structuredData == null) {
        print('  ❌ Groq AI failed\n');
        failCount++;
        continue;
      }

      print('  ✅ Groq AI OK');

      // BƯỚC 3: Add image URL
      structuredData['image_url'] = wikiData['image_url'];

      allData.add(structuredData);
      successCount++;

      print('  🎉 SUCCESS!\n');

      // Rate limiting - 1 request/giây
      if (i < TEST_ANIMALS.length - 1) {
        await Future.delayed(Duration(seconds: 1));
      }

    } catch (e) {
      print('  ❌ ERROR: $e\n');
      failCount++;
    }
  }

  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('📊 KẾT QUẢ:');
  print('   ✅ Thành công: $successCount');
  print('   ❌ Thất bại: $failCount');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  if (allData.isEmpty) {
    print('❌ Không có data nào được tạo!\n');
    return;
  }

  // Save JSON file
  final jsonFile = File('output/animals.json');
  jsonFile.writeAsStringSync(
    JsonEncoder.withIndent('  ').convert(allData),
  );

  print('💾 Đã lưu file: output/animals.json');
  print('   (${allData.length} động vật)\n');

  // Upload to Supabase
  print('📤 Uploading to Supabase...\n');
  await uploadToSupabase(allData);

  print('\n╔════════════════════════════════════════════╗');
  print('║          ✅ HOÀN THÀNH!                    ║');
  print('╚════════════════════════════════════════════╝\n');
}

// ═══════════════════════════════════════════════════════
// FUNCTION 1: FETCH WIKIPEDIA
// ═══════════════════════════════════════════════════════

Future<Map<String, dynamic>?> fetchWikipedia(String animalName) async {
  try {
    final url = 'https://en.wikipedia.org/w/api.php?'
        'action=query&'
        'titles=${Uri.encodeComponent(animalName)}&'
        'prop=extracts|pageimages&'
        'exintro=true&'
        'explaintext=true&'
        'piprop=original&'
        'format=json';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final pages = data['query']['pages'];
      final pageId = pages.keys.first;
      final page = pages[pageId];

      if (page['extract'] == null || page['extract'].toString().isEmpty) {
        return null;
      }

      return {
        'title': page['title'],
        'extract': page['extract'],
        'image_url': page['original']?['source'],
      };
    }
  } catch (e) {
    print('    Wikipedia error: $e');
  }

  return null;
}

// ═══════════════════════════════════════════════════════
// FUNCTION 2: PARSE WITH GROQ AI (FREE!)
// ═══════════════════════════════════════════════════════

Future<Map<String, dynamic>?> parseWithGroq(
    String animalName,
    Map<String, dynamic> wikiData,
    ) async {

  final prompt = '''
You are a wildlife database expert. Parse this Wikipedia extract into structured JSON.

Animal: $animalName

Wikipedia Text:
${wikiData['extract']}

Return ONLY a valid JSON object with these fields:

{
  "name_vietnamese": "Tên tiếng Việt",
  "name_english": "$animalName",
  "scientific_name": "Genus species",
  
  "class": "Mammalia|Aves|Reptilia|Amphibia|Pisces",
  "order_name": "Order name",
  "family": "Family name",
  
  "primary_habitat": "tropicalRainforest|savanna|desert|temperateForest|ocean|arctic|mountain|grassland",
  "geographic_regions": ["continent1", "continent2"],
  "countries": ["country1", "country2"],
  
  "diet_type": "carnivore|herbivore|omnivore|piscivore",
  "primary_food": ["food1", "food2"],
  "hunting_method": "ambush|chase|pack_hunting|stalking|grazing|null",
  
  "legs": 0 or 2 or 4,
  "locomotion": "quadrupedal|bipedal|flying|swimming",
  "size_category": "tiny|small|medium|large|huge|giant",
  
  "weight_avg_kg": number or null,
  "height_avg_m": number or null,
  "length_avg_m": number or null,
  
  "primary_colors": ["color1", "color2"],
  "patterns": ["spots|stripes|solid"],
  
  "max_speed_kmh": number or null,
  "speed_category": "very_slow|slow|medium|fast|very_fast",
  
  "has_horns": true or false,
  "has_tusks": true or false,
  "has_trunk": true or false,
  "has_mane": true or false,
  "has_wings": true or false,
  "has_fins": true or false,
  "has_claws": true or false,
  "has_sharp_teeth": true or false,
  
  "temperament": "gentle|neutral|aggressive|timid",
  "social_structure": "solitary|pair|small_group|herd|pack|colony",
  "activity_pattern": "nocturnal|diurnal|crepuscular",
  
  "aggression_level": 1-10,
  "intelligence_level": 1-10,
  "danger_to_humans": "harmless|low|moderate|high|extreme",
  
  "lifespan_avg_years": number or null,
  
  "conservation_status": "LC|NT|VU|EN|CR",
  "is_endangered": true or false,
  
  "fun_fact_vietnamese": "Một câu thú vị bằng tiếng Việt",
  "description_short": "Mô tả ngắn 2-3 câu"
}

RULES:
- Return ONLY the JSON object
- No markdown code blocks
- No explanations
- Use exact enum values
- If data not found, use null or false
- fun_fact_vietnamese MUST be in Vietnamese
- Be accurate with scientific data
''';

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
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.1,
        'max_tokens': 2000,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final content = data['choices'][0]['message']['content'];

      // Extract JSON
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);

      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final parsed = json.decode(jsonStr);
        return parsed;
      }
    } else {
      print('    Groq API error: ${response.statusCode}');
      print('    ${response.body}');
    }
  } catch (e) {
    print('    Groq exception: $e');
  }

  return null;
}

// ═══════════════════════════════════════════════════════
// FUNCTION 3: UPLOAD TO SUPABASE
// ═══════════════════════════════════════════════════════

Future<void> uploadToSupabase(List<Map<String, dynamic>> animals) async {
  int uploaded = 0;
  int failed = 0;

  for (var animal in animals) {
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
        uploaded++;
        print('  ✅ ${animal['name_vietnamese']}');
      } else {
        failed++;
        print('  ❌ ${animal['name_vietnamese']}');
        print('     Error: ${response.body}');
      }
    } catch (e) {
      failed++;
      print('  ❌ ${animal['name_vietnamese']}: $e');
    }
  }

  print('\n📊 Upload kết quả:');
  print('   ✅ Thành công: $uploaded');
  print('   ❌ Thất bại: $failed');
}