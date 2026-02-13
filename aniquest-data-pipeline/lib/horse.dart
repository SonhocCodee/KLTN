import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ═══════════════════════════════════════════════════════════════
// 🐴 HORSE DATA FETCHER
// ═══════════════════════════════════════════════════════════════

const GROQ_API_KEY = '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';
const SUPABASE_URL = 'https://dnvlqnixommhjqwpflmw.supabase.co';
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRudmxxbml4b21taGpxd3BmbG13Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MDMzMTUwMSwiZXhwIjoyMDg1OTA3NTAxfQ.W2cxnWC-DJoE9GRdUWMZU3-e27VFVA05BTJotZHfR54';

class AnimalConfig {
  static const String ANIMAL_TYPE = 'horse';
  static const String TRAITS_TABLE = 'horse_traits';
  static const String ANIMAL_NAME_VI = 'Ngựa';
  static const String ANIMAL_NAME_EN = 'Horse';

  static const List<String> BREED_LIST = [
    'Arabian Horse',
    'Thoroughbred',
    'Quarter Horse',
    'Appaloosa',
    'Mustang',
    'Friesian Horse',
    'Clydesdale',
    'Shetland Pony',
    'Andalusian Horse',
    'Morgan Horse',
  ];

  static const String WIKI_KEYWORD = 'horse';
}

void main() async {
  print('\n🐴 BẮT ĐẦU XỬ LÝ ${AnimalConfig.BREED_LIST.length} GIỐNG ${AnimalConfig.ANIMAL_NAME_EN.toUpperCase()}');

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
    final searchUrl = 'https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=$breedName ${AnimalConfig.WIKI_KEYWORD}&format=json';
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

String _buildPrompt(String breedName, String wikiText) {
  return '''Parse $breedName breed into JSON based on this Wikipedia info:

$wikiText

CRITICAL RULES:
1. Use 1-5 scale for integer traits. NEVER >5
2. temperament: gentle, neutral, aggressive, timid, territorial
3. coat_pattern: solid, spotted, pinto, appaloosa, roan
4. body_type: light, medium, heavy, draft
5. primary_use: racing, show, work, pleasure, sport
6. breed_group: warmblood, coldblood, hotblood, pony

Return EXACTLY this JSON (no markdown, no extra text):

{
  "animal": {
    "animal_type": "horse",
    "name_vietnamese": "Ngựa [Vietnamese translation]",
    "name_english": "$breedName",
    "scientific_name": "Equus ferus caballus",
    "kingdom": "Animalia",
    "phylum": "Chordata",
    "class": "Mammalia",
    "order_name": "Perissodactyla",
    "family": "Equidae",
    "genus": "Equus",
    "species": "Equus ferus",
    "primary_habitat": "grassland",
    "domestication_status": "domestic",
    "diet_type": "herbivore",
    "legs": 4,
    "locomotion": "quadrupedal",
    "relative_size": "large",
    "weight_avg_kg": 500.0,
    "height_avg_m": 1.6,
    "length_avg_m": 2.4,
    "primary_colors": ["brown","black","white"],
    "patterns": ["solid"],
    "fur_type": "short_fur",
    "max_speed_kmh": 70,
    "temperament": "gentle",
    "social_structure": "herd",
    "activity_pattern": "diurnal",
    "aggression_level": 2,
    "intelligence_level": 4,
    "danger_to_humans": "low",
    "lifespan_avg_years": 25,
    "conservation_status": "Domesticated",
    "is_endangered": false,
    "has_claws": false,
    "has_sharp_teeth": false,
    "has_tail": true,
    "has_whiskers": false,
    "has_mane": true,
    "fun_fact_vietnamese": "Thông tin thú vị bằng tiếng Việt",
    "description_short": "Mô tả ngắn bằng tiếng Việt"
  },
  "horse_traits": {
    "coat_color": "brown",
    "coat_pattern": "solid",
    "mane_type": "long",
    "tail_length": "long",
    "body_type": "medium",
    "withers_height_hands": 15.0,
    "gait_types": ["walk","trot","canter","gallop"],
    "temperament_level": 3,
    "trainability": 4,
    "stamina_level": 4,
    "speed_rating": 3,
    "primary_use": "riding",
    "jumping_ability": 3,
    "endurance_rating": 3,
    "breed_origin": "Country/Region",
    "breed_group": "warmblood",
    "grooming_needs": "moderate",
    "exercise_needs": "high",
    "herd_instinct": 5,
    "good_with_riders": true,
    "suitable_for_beginners": false,
    "typical_sounds": ["neigh","whinny","nicker","snort"]
  }
}

Use realistic values based on breed knowledge from the Wikipedia text.''';
}

Future<bool> uploadToSupabase(Map<String, dynamic> data) async {
  try {
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