import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ═══════════════════════════════════════════════════════════════
// 🎯 ANIQUEST - UNIVERSAL ANIMAL DATA FETCHER (FIXED RLS)
// ═══════════════════════════════════════════════════════════════

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CẤU HÌNH - QUAN TRỌNG: DÙNG SERVICE_ROLE KEY
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const GROQ_API_KEY = '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';
const SUPABASE_URL = 'https://dnvlqnixommhjqwpflmw.supabase.co';

// ⚠️ QUAN TRỌNG: PHẢI DÙNG SERVICE_ROLE KEY để INSERT
// Cách lấy:
// 1. Vào Supabase Dashboard
// 2. Settings → API
// 3. Copy "service_role" key (KHÔNG phải anon key)

const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRudmxxbml4b21taGpxd3BmbG13Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MDMzMTUwMSwiZXhwIjoyMDg1OTA3NTAxfQ.W2cxnWC-DJoE9GRdUWMZU3-e27VFVA05BTJotZHfR54';

// Nếu không muốn dùng service_role, chạy SQL: FIX_RLS_POLICIES.sql (Option 1 hoặc 2)

// ╔════════════════════════════════════════════════════════════╗
// ║  🔧 CONFIG - CHỈ THAY ĐỔI PHẦN NÀY KHI CHUYỂN LOÀI         ║
// ╚════════════════════════════════════════════════════════════╝

class AnimalConfig {
  static const String ANIMAL_TYPE = 'cat';
  static const String TRAITS_TABLE = 'cat_traits';
  static const String ANIMAL_NAME_VI = 'Mèo';
  static const String ANIMAL_NAME_EN = 'Cat';

  static const List<String> BREED_LIST = [
    'Abyssinian',
    'Aegean',
    'American Bobtail',
    'American Curl',
    'American Shorthair',
    'American Wirehair',
    'Aphrodite Giant',
    'Arabian Mau',
    'Australian Mist',
    'Balinese',
    'Bambino',
    'Bengal',
    'Birman',
    'Bombay',
    'Brazilian Shorthair',
    'British Longhair',
    'British Shorthair',
    'Burmese',
    'Burmilla',
    'California Spangled',
    'Chantilly-Tiffany',
    'Chartreux',
    'Chausie',
    'Cheetoh',
    'Colorpoint Shorthair',
    'Cornish Rex',
    'Cymric',
    'Cyprus',
    'Devon Rex',
    'Donskoy',
    'Dragon Li',
    'Egyptian Mau',
    'European Shorthair',
    'Exotic Shorthair',
    'German Rex',
    'Havana Brown',
    'Highlander',
    'Himalayan',
    'Japanese Bobtail',
    'Javanese',
    'Kanaani',
    'Khao Manee',
    'Kinkalow',
    'Korat',
    'Kurilian Bobtail',
    'LaPerm',
    'Lykoi',
    'Maine Coon',
    'Manx',
    'Mekong Bobtail',
    'Minskin',
    'Minuet',
    'Munchkin',
    'Nebelung',
    'Norwegian Forest Cat',
    'Ocicat',
    'Ojos Azules',
    'Oregon Rex',
    'Oriental Bicolour',
    'Oriental Longhair',
    'Oriental Shorthair',
    'Persian',
    'Peterbald',
    'Pixie-bob',
    'Ragamuffin',
    'Ragdoll',
    'Russian Blue',
    'Savannah',
    'Scottish Fold',
    'Selkirk Rex',
    'Serengeti',
    'Siamese',
    'Siberian',
    'Singapura',
    'Snowshoe',
    'Sokoke',
    'Somali',
    'Sphynx',
    'Thai',
    'Tonkinese',
    'Toyger',
    'Turkish Angora',
    'Turkish Van',
    'Ukranian Levkoy',
    'York Chocolate'
  ];

  static const String WIKI_KEYWORD = 'cat';

  static const Map<String, dynamic> DEFAULT_TAXONOMY = {
    'scientific_name': 'Felis catus',
    'kingdom': 'Animalia',
    'phylum': 'Chordata',
    'class': 'Mammalia',
    'order_name': 'Carnivora',
    'family': 'Felidae',
    'genus': 'Felis',
    'species': 'Felis catus',
  };
}

// ═══════════════════════════════════════════════════════════════
// MAIN FUNCTION
// ═══════════════════════════════════════════════════════════════

void main() async {
  // Kiểm tra service key
  if (SUPABASE_SERVICE_KEY == 'THAY_BẰNG_SERVICE_ROLE_KEY_CỦA_BẠN') {
    print('\n❌ LỖI: Chưa thay SUPABASE_SERVICE_KEY!');
    print('\n📝 HƯỚNG DẪN LẤY SERVICE_ROLE KEY:');
    print('   1. Vào https://supabase.com/dashboard');
    print('   2. Chọn project của bạn');
    print('   3. Settings → API');
    print('   4. Tìm "service_role" key');
    print('   5. Copy và paste vào code (dòng 18)\n');
    print('⚠️  HOẶC chạy FIX_RLS_POLICIES.sql để tắt RLS\n');
    exit(1);
  }

  print('\n╔════════════════════════════════════════════════════════╗');
  print('║  🐾 ANIQUEST - ${AnimalConfig.ANIMAL_NAME_EN.toUpperCase()} DATA IMPORTER  ${' ' * (23 - AnimalConfig.ANIMAL_NAME_EN.length)}║');
  print('╚════════════════════════════════════════════════════════╝\n');

  int success = 0;
  int skipped = 0;
  int failed = 0;
  List<String> failedList = [];

  for (var i = 0; i < AnimalConfig.BREED_LIST.length; i++) {
    final breedName = AnimalConfig.BREED_LIST[i];

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('[${i + 1}/${AnimalConfig.BREED_LIST.length}] 🔍 $breedName');

    if (await checkIfExist(breedName)) {
      print('   ⏭️  Đã tồn tại → BỎ QUA');
      skipped++;
      continue;
    }

    try {
      print('   📚 Wikipedia...');
      var wikiData = await fetchWikipedia(breedName);

      if (wikiData == null) {
        print('   ❌ Không tìm thấy Wiki');
        failed++;
        failedList.add(breedName);
        continue;
      }

      print('   🤖 AI phân tích...');
      final parsedData = await parseWithAI(breedName, wikiData);

      if (parsedData == null) {
        print('   ❌ AI lỗi');
        failed++;
        failedList.add(breedName);
        continue;
      }

      print('   📤 Đang upload...');
      if (await uploadToSupabase(parsedData)) {
        success++;
        print('   ✅ THÀNH CÔNG!');
      } else {
        failed++;
        failedList.add(breedName);
      }

      await Future.delayed(Duration(milliseconds: 2000));

    } catch (e) {
      print('   ❌ Lỗi: $e');
      failed++;
      failedList.add(breedName);
    }
  }

  print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('📊 KẾT QUẢ:');
  print('   ✅ Thành công: $success');
  print('   ⏭️  Đã có: $skipped');
  print('   ❌ Thất bại: $failed');

  if (failedList.isNotEmpty) {
    print('\n❌ Danh sách thất bại:');
    for (var item in failedList) {
      print('   - $item');
    }
  }
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
}

// ═══════════════════════════════════════════════════════════════
// HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════

Future<bool> checkIfExist(String name) async {
  try {
    final url = '$SUPABASE_URL/rest/v1/animals?name_english=eq.${Uri.encodeComponent(name)}&select=id';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': 'Bearer $SUPABASE_SERVICE_KEY',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.isNotEmpty;
    }
  } catch (e) {}
  return false;
}

Future<Map<String, dynamic>?> fetchWikipedia(String searchTerm) async {
  try {
    var result = await _fetchWikiPage(searchTerm);
    if (result != null) return result;

    result = await _fetchWikiPage('$searchTerm ${AnimalConfig.WIKI_KEYWORD}');
    if (result != null) return result;

    return null;
  } catch (e) {
    return null;
  }
}

Future<Map<String, dynamic>?> _fetchWikiPage(String query) async {
  try {
    final searchUrl = 'https://en.wikipedia.org/w/api.php?action=opensearch&search=${Uri.encodeComponent(query)}&limit=1&namespace=0&format=json';
    final searchRes = await http.get(Uri.parse(searchUrl));

    String correctTitle = query;
    if (searchRes.statusCode == 200) {
      final searchData = json.decode(searchRes.body) as List;
      if (searchData.length > 1 && (searchData[1] as List).isNotEmpty) {
        correctTitle = searchData[1][0];
      }
    }

    final contentUrl = 'https://en.wikipedia.org/w/api.php?action=query&titles=${Uri.encodeComponent(correctTitle)}&prop=extracts|pageimages&exintro=true&explaintext=true&piprop=original&format=json';
    final contentRes = await http.get(Uri.parse(contentUrl));

    if (contentRes.statusCode == 200) {
      final data = json.decode(contentRes.body);
      final pages = data['query']['pages'];
      final pageId = pages.keys.first;

      if (pageId == "-1") return null;

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
  } catch (e) {}
  return null;
}

Future<Map<String, dynamic>?> parseWithAI(
    String breedName,
    Map<String, dynamic> wikiData,
    ) async {
  final prompt = _buildPrompt(breedName, wikiData['extract']);

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

String _buildPrompt(String breedName, String wikiText) {
  final config = AnimalConfig.DEFAULT_TAXONOMY;
  final animalType = AnimalConfig.ANIMAL_TYPE;

  return '''
Parse this ${AnimalConfig.ANIMAL_NAME_EN} breed into TWO JSON objects.

Breed: $breedName
Wiki: $wikiText

Return EXACTLY this structure (NO markdown):

{
  "animal": {
    "animal_type": "$animalType",
    "name_vietnamese": "${AnimalConfig.ANIMAL_NAME_VI} [Vietnamese translation of $breedName]",
    "name_english": "$breedName",
    "scientific_name": "${config['scientific_name']}",
    "kingdom": "${config['kingdom']}",
    "phylum": "${config['phylum']}",
    "class": "${config['class']}",
    "order_name": "${config['order_name']}",
    "family": "${config['family']}",
    "genus": "${config['genus']}",
    "species": "${config['species']}",
    "primary_habitat": "domestic",
    "domestication_status": "domestic",
    "diet_type": "carnivore",
    "legs": 4,
    "locomotion": "quadrupedal",
    "relative_size": "cat_sized",
    "weight_avg_kg": 4.5,
    "height_avg_m": 0.25,
    "length_avg_m": 0.45,
    "primary_colors": ["brown", "white"],
    "patterns": ["solid", "tabby"],
    "fur_type": "short_fur",
    "max_speed_kmh": 48,
    "temperament": "gentle",
    "social_structure": "solitary",
    "activity_pattern": "crepuscular",
    "aggression_level": 2,
    "intelligence_level": 7,

CRITICAL - TEMPERAMENT MUST BE ONE OF:
- "gentle" (for friendly, calm cats)
- "neutral" (for balanced cats)
- "aggressive" (for defensive cats)
- "timid" (for shy cats)
- "territorial" (for protective cats)
DO NOT use: playful, friendly, active, etc. ONLY use the 5 values above!
    "danger_to_humans": "harmless",
    "lifespan_avg_years": 14,
    "conservation_status": "Domesticated",
    "is_endangered": false,
    "has_claws": true,
    "has_sharp_teeth": true,
    "has_tail": true,
    "has_whiskers": true,
    "fun_fact_vietnamese": "Thông tin thú vị bằng tiếng Việt",
    "description_short": "Mô tả ngắn bằng tiếng Việt"
  },
  "${AnimalConfig.TRAITS_TABLE}": {
    "has_pointy_ears": true,
    "has_floppy_ears": false,
    "has_long_tail": true,
    "has_spots": false,
    "has_stripes": false,
    "is_fluffy": false,
    "has_big_eyes": true,
    "coat_length": "short",
    "shedding_level": 3,
    "grooming_needs": "moderate",
    "hypoallergenic": false,
    "affection_level": 4,
    "playfulness": 4,
    "energy_level": 3,
    "good_with_children": true,
    "good_with_dogs": false,
    "good_with_cats": true,
    "trainability": 3,
    "vocalization": 3,
    "lap_cat": false,
    "indoor_only": true,
    "can_climb_trees": true
  }
}

Use realistic values based on breed knowledge.
''';
}

Future<bool> uploadToSupabase(Map<String, dynamic> data) async {
  try {
    // BƯỚC 1: Insert animals (DÙNG SERVICE_ROLE KEY)
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

    // BƯỚC 2: Insert traits
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
      // Rollback
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