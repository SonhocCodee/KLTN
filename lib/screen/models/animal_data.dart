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
