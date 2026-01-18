import 'dart:convert';
import 'package:http/http.dart' as http;

class AnimalApiService {
  // API miễn phí: api.api-ninjas.com/v1/animals
  // Cần đăng ký key miễn phí tại: https://api-ninjas.com/
  static const String _baseUrl = 'https://api.api-ninjas.com/v1/animals';
  static const String _apiKey = '6Iuf5OY4tyKp0LzSqwLhIwEE4eCzRcXa9teNFT7m'; // Thay bằng key thật

  // Danh sách động vật để random theo ngày
  static const List<String> _animalNames = [
    'lion',
    'tiger',
    'elephant',
    'bear',
    'wolf',
    'eagle',
    'dolphin',
    'shark',
    'panda',
    'giraffe',
    'zebra',
    'cheetah',
    'gorilla',
    'penguin',
    'kangaroo',
    'koala',
    'rhino',
    'hippo',
    'leopard',
    'jaguar',
  ];

  // Lấy động vật theo ngày (seed dựa vào ngày)
  static String getAnimalOfTheDay() {
    final now = DateTime.now();
    final daysSinceEpoch = now.difference(DateTime(2024, 1, 1)).inDays;
    final index = daysSinceEpoch % _animalNames.length;
    return _animalNames[index];
  }

  // Fetch thông tin động vật từ API
  Future<AnimalData?> fetchAnimalInfo(String animalName) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?name=$animalName'),
        headers: {'X-Api-Key': _apiKey},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return AnimalData.fromJson(data[0]);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching animal data: $e');
      return null;
    }
  }

  // Lấy thông tin động vật của ngày hôm nay
  Future<AnimalData?> getTodayAnimal() async {
    final animalName = getAnimalOfTheDay();
    return await fetchAnimalInfo(animalName);
  }
}

// ==========================================
// File: lib/models/animal_data.dart
// ==========================================
class AnimalData {
  final String name;
  final String taxonomy;
  final List<String> locations;
  final Map<String, dynamic> characteristics;

  AnimalData({
    required this.name,
    required this.taxonomy,
    required this.locations,
    required this.characteristics,
  });

  factory AnimalData.fromJson(Map<String, dynamic> json) {
    return AnimalData(
      name: json['name'] ?? '',
      taxonomy: json['taxonomy']?['scientific_classification'] ?? '',
      locations: List<String>.from(json['locations'] ?? []),
      characteristics: json['characteristics'] ?? {},
    );
  }

  // Convert sang AnimalFact để dùng trong UI
  AnimalFact toAnimalFact() {
    // Tạo facts từ characteristics
    final facts = <String>[];

    if (characteristics['top_speed'] != null) {
      facts.add('Tốc độ tối đa: ${characteristics['top_speed']}');
    }
    if (characteristics['weight'] != null) {
      facts.add('Cân nặng: ${characteristics['weight']}');
    }
    if (characteristics['height'] != null) {
      facts.add('Chiều cao: ${characteristics['height']}');
    }
    if (characteristics['lifespan'] != null) {
      facts.add('Tuổi thọ: ${characteristics['lifespan']}');
    }
    if (characteristics['diet'] != null) {
      facts.add('Chế độ ăn: ${characteristics['diet']}');
    }

    // Lấy ảnh từ Unsplash (miễn phí, không cần API key)
    final imageUrl = 'https://source.unsplash.com/800x1200/?${name.toLowerCase()},animal';

    return AnimalFact(
      name: _getVietnameseName(name),
      scientificName: taxonomy,
      description: _generateDescription(),
      facts: facts.isEmpty ? ['Đang cập nhật thông tin...'] : facts,
      imageUrl: imageUrl,
      category: characteristics['diet'] ?? 'Unknown',
    );
  }


  Future<String?> fetchAnimalImage(String animalName) async {
    const pixabayKey = 'YOUR_PIXABAY_KEY_HERE';  // Thay bằng key thật từ pixabay.com
    final query = '$animalName animal wildlife';  // Query để tìm ảnh đẹp
    final apiUrl = 'https://pixabay.com/api/?key=$pixabayKey&q=${Uri.encodeQueryComponent(query)}&image_type=photo&orientation=vertical&safesearch=true&min_width=800&min_height=1200';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['hits'] != null && data['hits'].isNotEmpty) {
          return data['hits'][0]['largeImageURL'];  // Ảnh lớn, vertical
        }
      }
      print('Pixabay error: ${response.body}');
    } catch (e) {
      print('Error fetching Pixabay image: $e');
    }
    // Fallback nếu fail (dùng asset local hoặc URL default)
    return 'https://via.placeholder.com/800x1200?text=$animalName';  // Hoặc asset của bạn
  }

  String _getVietnameseName(String englishName) {
    final nameMap = {
      'lion': 'Sư tử',
      'tiger': 'Hổ',
      'elephant': 'Voi',
      'bear': 'Gấu',
      'wolf': 'Sói',
      'eagle': 'Đại bàng',
      'dolphin': 'Cá heo',
      'shark': 'Cá mập',
      'panda': 'Gấu trúc',
      'giraffe': 'Hươu cao cổ',
      'zebra': 'Ngựa vằn',
      'cheetah': 'Báo gêpa',
      'gorilla': 'Khỉ đột',
      'penguin': 'Chim cánh cụt',
      'kangaroo': 'Chuột túi',
      'koala': 'Gấu túi',
      'rhino': 'Tê giác',
      'hippo': 'Hà mã',
      'leopard': 'Báo đốm',
      'jaguar': 'Báo Mỹ',
    };
    return nameMap[englishName.toLowerCase()] ?? englishName;
  }

  String _generateDescription() {
    final location = locations.isNotEmpty ? locations[0] : 'nhiều nơi';
    return 'Sinh sống chủ yếu ở $location. Là một trong những loài động vật đặc biệt và đáng chú ý nhất trong tự nhiên.';
  }
}

class AnimalFact {
  final String name;
  final String scientificName;
  final String description;
  final List<String> facts;
  final String imageUrl;
  final String category;

  AnimalFact({
    required this.name,
    required this.scientificName,
    required this.description,
    required this.facts,
    required this.imageUrl,
    required this.category,
  });
}


