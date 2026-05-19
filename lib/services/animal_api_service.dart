import 'dart:convert';
import 'package:http/http.dart' as http;
import '../screen/models/animal_data.dart';

class AnimalApiService {
  // ─────────────────────────────────────────────
  // API KEYS
  // ─────────────────────────────────────────────
  static const String _ninjasBaseUrl = 'https://api.api-ninjas.com/v1/animals';
  static const String _ninjasApiKey = '6Iuf5OY4tyKp0LzSqwLhIwEE4eCzRcXa9teNFT7m';

  static const String _pixabayUrl = 'https://pixabay.com/api/';
  static const String _pixabayKey = 'Y54250368-3e02b997bbfb975c685ca2fbc';

  // Groq — miễn phí, nhanh, đăng ký tại console.groq.com
  static const String _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _groqKey = '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'; // Thay bằng key thật

  // Supabase shared cache
  static const String _supabaseUrl = 'https://dnvlqnixommhjqwpflmw.supabase.co';
  static const String _supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRudmxxbml4b21taGpxd3BmbG13Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAzMzE1MDEsImV4cCI6MjA4NTkwNzUwMX0.sz5oI5lhecJ0DCJNByI3CIHFICHh2PBt5FHnrMfmDaE';

  // ─────────────────────────────────────────────
  // DANH SÁCH 60 CON — không lặp trong 60 ngày
  // ─────────────────────────────────────────────
  static const List<String> _animalNames = [
    'cheetah', 'snow leopard', 'clouded leopard', 'serval', 'caracal',
    'ocelot', 'fishing cat', 'sand cat', 'pallas cat', 'margay',
    'african elephant', 'asian elephant', 'giraffe', 'okapi', 'tapir',
    'rhinoceros', 'hippopotamus', 'capybara', 'giant otter', 'wolverine',
    'honey badger', 'binturong', 'fossa', 'aardvark', 'pangolin',
    'platypus', 'echidna', 'axolotl', 'olm', 'komodo dragon',
    'gila monster', 'basilisk lizard', 'frilled lizard', 'secretary bird',
    'shoebill', 'harpy eagle', 'kakapo', 'cassowary', 'lyrebird',
    'bowerbird', 'hoatzin', 'kiwi', 'narwhal', 'beluga whale',
    'dugong', 'manatee', 'goblin shark', 'whale shark', 'hammerhead shark',
    'manta ray', 'leafy sea dragon', 'mantis shrimp', 'horseshoe crab',
    'nautilus', 'mimic octopus', 'giant pacific octopus', 'lion',
    'tiger', 'gorilla', 'wolf',
  ];

  // seed theo ngày → cùng ngày = cùng con, không đổi khi rebuild widget
  static String getAnimalOfTheDay() {
    final daysSinceEpoch =
        DateTime.now().difference(DateTime(2024, 1, 1)).inDays;
    final hash = (daysSinceEpoch * 2654435761) & 0x7FFFFFFF;
    return _animalNames[hash % _animalNames.length];
  }

  // ─────────────────────────────────────────────
  // PUBLIC: Lấy con vật hôm nay (check cache trước)
  // ─────────────────────────────────────────────
  Future<AnimalData?> getTodayAnimal() async {
    final animalName = getAnimalOfTheDay();
    final today = _todayString();
    print('📅 Hôm nay ($today): $animalName');

    // 1. Check Supabase shared cache
    final cached = await _getSharedCache(today, animalName);
    if (cached != null) {
      print('✅ [Cache] Dùng data từ Supabase');
      return cached;
    }

    // 2. Chưa có → người đầu tiên fetch + lưu cho mọi người sau
    print('🚀 [First user today] Fetching fresh data...');
    final fresh = await _fetchFreshData(animalName);
    if (fresh != null) {
      await _saveSharedCache(today, animalName, fresh);
    }
    return fresh;
  }

  // Dùng cho identify screen (không cần cache)
  Future<AnimalData?> fetchAnimalInfo(String animalName) async {
    return _fetchFreshData(animalName);
  }

  // ─────────────────────────────────────────────
  // FETCH MỚI: Ninjas + Pixabay + Groq
  // ─────────────────────────────────────────────
  Future<AnimalData?> _fetchFreshData(String animalName) async {
    try {
      // Bước 1: API Ninjas
      final response = await http.get(
        Uri.parse('$_ninjasBaseUrl?name=$animalName'),
        headers: {'X-Api-Key': _ninjasApiKey},
      );
      if (response.statusCode != 200) return null;

      final List<dynamic> list = json.decode(response.body);
      if (list.isEmpty) return null;

      // FIX LỖI "final": dùng var để có thể gán lại
      var raw = Map<String, dynamic>.from(list[0]);

      // Bước 2: Fix mph → km/h
      raw = _convertSpeedsToKmh(raw);

      // Bước 3: Việt hóa địa danh
      raw = _localizeLocations(raw);

      // Bước 4: Ảnh Pixabay
      final imageUrl = await _fetchPixabayImage(animalName);
      raw['custom_image_url'] = imageUrl;

      // Bước 5: Groq generate mô tả độc đáo
      final description = await _generateDescriptionWithGroq(animalName, raw);
      raw['ai_description'] = description;

      return AnimalData.fromJson(raw);
    } catch (e) {
      print('❌ [FetchFresh] Lỗi: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // GROQ — miễn phí, thay Claude
  // Đăng ký: console.groq.com → API Keys → Create key
  // ─────────────────────────────────────────────
  Future<String?> _generateDescriptionWithGroq(
      String animalName, Map<String, dynamic> rawData) async {
    if (_groqKey == 'YOUR_GROQ_API_KEY') {
      print('⚠️ Chưa điền Groq API key');
      return null;
    }

    try {
      final chars = rawData['characteristics'] as Map<String, dynamic>? ?? {};
      final taxonomy = rawData['taxonomy'] as Map<String, dynamic>? ?? {};
      final locations = rawData['locations'] as List? ?? [];

      final prompt =
          'Viết mô tả 2-3 câu tiếng Việt về loài $animalName. '
          'Dữ liệu: tên khoa học="${taxonomy['scientific_classification'] ?? ''}", '
          'môi trường="${chars['habitat'] ?? locations.take(2).join(', ')}", '
          'chế độ ăn="${chars['diet'] ?? ''}", '
          'tốc độ="${chars['top_speed'] ?? ''}". '
          'Yêu cầu: (1) bắt đầu bằng điều bất ngờ nhất của loài này, '
          '(2) KHÔNG dùng tên địa danh tiếng Anh (Africa→châu Phi, Australia→châu Úc), '
          '(3) KHÔNG dùng mph, chỉ dùng km/h, '
          '(4) KHÔNG bắt đầu bằng tên loài hoặc "Đây là một loài...", '
          '(5) mô tả phải đặc trưng riêng loài này, không áp dụng cho loài khác. '
          'Chỉ trả về đoạn văn, không có gì khác.';

      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqKey',
        },
        body: json.encode({
          'model': 'llama-3.1-8b-instant',
          'max_tokens': 200,
          'temperature': 0.7,
          'messages': [
            {
              'role': 'system',
              'content':
              'Bạn là chuyên gia động vật học. Viết mô tả ngắn, hấp dẫn bằng tiếng Việt.'
            },
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text = data['choices'][0]['message']['content'] as String;
        print('✅ [Groq] ${text.trim()}');
        return text.trim();
      } else {
        print('❌ [Groq] ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ [Groq] Exception: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // Fix mph → km/h
  // ─────────────────────────────────────────────
  Map<String, dynamic> _convertSpeedsToKmh(Map<String, dynamic> raw) {
    final result = Map<String, dynamic>.from(raw);
    final chars = result['characteristics'] as Map<String, dynamic>?;
    if (chars == null) return result;

    final speed = chars['top_speed'];
    if (speed is String && speed.toLowerCase().contains('mph')) {
      final mph = double.tryParse(
          speed.toLowerCase().replaceAll('mph', '').trim());
      if (mph != null) {
        final kmh = (mph * 1.60934).round();
        chars['top_speed'] = '$kmh km/h';
        print('🔄 Tốc độ: $speed → $kmh km/h');
      }
    }
    return result;
  }

  // ─────────────────────────────────────────────
  // Việt hóa địa danh — sort dài trước để tránh replace một phần
  // (vd: "Sub-Saharan Africa" phải replace trước "Africa")
  // ─────────────────────────────────────────────
  static const Map<String, String> _locationMap = {
    'Sub-Saharan Africa': 'châu Phi cận Sahara',
    'North Africa': 'Bắc Phi',
    'East Africa': 'Đông Phi',
    'West Africa': 'Tây Phi',
    'Central Africa': 'Trung Phi',
    'South Africa': 'Nam Phi',
    'Africa': 'châu Phi',
    'Southeast Asia': 'Đông Nam Á',
    'South Asia': 'Nam Á',
    'East Asia': 'Đông Á',
    'Central Asia': 'Trung Á',
    'South America': 'Nam Mỹ',
    'North America': 'Bắc Mỹ',
    'Central America': 'Trung Mỹ',
    'Australia': 'châu Úc',
    'Europe': 'châu Âu',
    'Arctic': 'Bắc Cực',
    'Antarctica': 'Nam Cực',
    'Amazon': 'rừng Amazon',
    'Sahara': 'sa mạc Sahara',
    'India': 'Ấn Độ',
    'China': 'Trung Quốc',
    'Borneo': 'đảo Borneo',
    'Madagascar': 'đảo Madagascar',
    'Pacific Ocean': 'Thái Bình Dương',
    'Atlantic Ocean': 'Đại Tây Dương',
    'Indian Ocean': 'Ấn Độ Dương',
  };

  Map<String, dynamic> _localizeLocations(Map<String, dynamic> raw) {
    var str = json.encode(raw);
    final sorted = _locationMap.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final entry in sorted) {
      str = str.replaceAll(entry.key, entry.value);
    }
    return json.decode(str);
  }

  // ─────────────────────────────────────────────
  // Pixabay
  // ─────────────────────────────────────────────
  Future<String?> _fetchPixabayImage(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent('$query animal wildlife');
      final url =
          '$_pixabayUrl?key=$_pixabayKey&q=$encodedQuery&image_type=photo&per_page=5&category=animals&safesearch=true';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final hits = json.decode(response.body)['hits'] as List?;
        if (hits != null && hits.isNotEmpty) {
          return hits[0]['largeImageURL'] as String;
        }
      }
    } catch (e) {
      print('❌ Pixabay: $e');
    }
    return null;
  }

  // ─────────────────────────────────────────────
  // Supabase shared cache
  // ─────────────────────────────────────────────
  Future<AnimalData?> _getSharedCache(String date, String animalName) async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/daily_animal_cache'
            '?cache_date=eq.$date'
            '&animal_name=eq.$animalName'
            '&select=*'
            '&limit=1'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
        },
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) return AnimalData.fromCacheJson(data[0]);
      }
    } catch (e) {
      print('⚠️ [Cache] Đọc thất bại: $e');
    }
    return null;
  }

  Future<void> _saveSharedCache(
      String date, String animalName, AnimalData data) async {
    try {
      await http.post(
        Uri.parse('$_supabaseUrl/rest/v1/daily_animal_cache'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
          'Content-Type': 'application/json',
          'Prefer': 'resolution=ignore-duplicates',
        },
        body: json.encode({
          'cache_date': date,
          ...data.toCacheJson(),
        }),
      );
      print('💾 [Cache] Đã lưu Supabase');
    } catch (e) {
      print('⚠️ [Cache] Lưu thất bại: $e');
    }
  }

  static String _todayString() =>
      DateTime.now().toIso8601String().split('T')[0];
}

