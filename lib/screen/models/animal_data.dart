class AnimalData {
  final String name; // Tên tiếng Anh gốc từ API
  final String taxonomy;
  final List<String> locations;
  final Map<String, dynamic> characteristics;
  final String? remoteImageUrl;

  AnimalData({
    required this.name,
    required this.taxonomy,
    required this.locations,
    required this.characteristics,
    this.remoteImageUrl,
  });

  factory AnimalData.fromJson(Map<String, dynamic> json) {
    return AnimalData(
      name: json['name'] ?? '',
      taxonomy: json['taxonomy']?['scientific_classification'] ?? '',
      locations: List<String>.from(json['locations'] ?? []),
      characteristics: json['characteristics'] ?? {},
      remoteImageUrl: json['custom_image_url'],
    );
  }

  AnimalFact toAnimalFact() {
    final facts = <String>[];

    if (characteristics['top_speed'] != null) {
      facts.add('Tốc độ: ${characteristics['top_speed']}');
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

    final imageUrl = remoteImageUrl ??
        'https://upload.wikimedia.org/wikipedia/commons/7/73/Lion_waiting_in_Namibia.jpg';

    return AnimalFact(
      name: _getVietnameseName(name),
      englishName: name, // GIỮ TÊN TIẾNG ANH ĐỂ TÌM ẢNH
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
    final location = locations.isNotEmpty ? locations[0] : 'tự nhiên';
    return 'Sinh sống chủ yếu ở $location. Là một loài động vật đặc biệt với nhiều đặc điểm thú vị.';
  }
}

class AnimalFact {
  final String name; // Tên tiếng Việt hiển thị
  final String englishName; // Tên tiếng Anh (để tìm ảnh)
  final String scientificName;
  final String description;
  final List<String> facts;
  final String imageUrl;
  final String category;

  AnimalFact({
    required this.name,
    required this.englishName,
    required this.scientificName,
    required this.description,
    required this.facts,
    required this.imageUrl,
    required this.category,
  });

  // Constructor cho cache
  factory AnimalFact.fromCache(Map<String, dynamic> data) {
    return AnimalFact(
      name: data['name'],
      englishName: data['englishName'] ?? '',
      scientificName: data['scientificName'],
      description: data['description'],
      facts: List<String>.from(data['facts']),
      imageUrl: data['imageUrl'],
      category: data['category'],
    );
  }

  Map<String, dynamic> toCache() {
    return {
      'name': name,
      'englishName': englishName,
      'scientificName': scientificName,
      'description': description,
      'facts': facts,
      'imageUrl': imageUrl,
      'category': category,
    };
  }
}