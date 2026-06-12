import '../language/Locale_provider.dart'; // Chú ý: Đảm bảo đường dẫn này đúng với project của bạn

class AnimalData {
  final String name;
  final String taxonomy;
  final List<String> locations;
  final Map<String, dynamic> characteristics;
  final String? remoteImageUrl;
  final String? aiDescription; // ← Thêm field này để nhận mô tả từ Groq

  AnimalData({
    required this.name,
    required this.taxonomy,
    required this.locations,
    required this.characteristics,
    this.remoteImageUrl,
    this.aiDescription,
  });

  factory AnimalData.fromJson(Map<String, dynamic> json) {
    return AnimalData(
      name: json['name'] ?? '',
      taxonomy: json['taxonomy']?['scientific_classification'] ?? '',
      locations: List<String>.from(json['locations'] ?? []),
      characteristics: json['characteristics'] ?? {},
      remoteImageUrl: json['custom_image_url'],
      aiDescription: json['ai_description'],
    );
  }

  // THÊM MỚI: Đọc từ Supabase cache
  factory AnimalData.fromCacheJson(Map<String, dynamic> json) {
    return AnimalData(
      name: json['animal_name'] ?? '',
      taxonomy: json['scientific_name'] ?? '',
      locations: json['locations'] != null
          ? List<String>.from(json['locations'])
          : [],
      characteristics: json['characteristics'] != null
          ? Map<String, dynamic>.from(json['characteristics'])
          : {},
      remoteImageUrl: json['image_url'],
      aiDescription: json['ai_description'],
    );
  }

  // THÊM MỚI: Lưu lên Supabase cache
  Map<String, dynamic> toCacheJson() {
    return {
      'animal_name': name,
      'scientific_name': taxonomy,
      'locations': locations,
      'characteristics': characteristics,
      'image_url': remoteImageUrl,
      'ai_description': aiDescription,
    };
  }

  // Bổ sung tham số LocaleProvider t vào hàm này
  AnimalFact toAnimalFact(LocaleProvider t) {
    final facts = <String>[];

    if (characteristics['top_speed'] != null) {
      facts.add('${t.tr('Tốc độ:')} ${characteristics['top_speed']}');
    }
    if (characteristics['weight'] != null) {
      facts.add('${t.tr('Cân nặng:')} ${characteristics['weight']}');
    }
    if (characteristics['height'] != null) {
      facts.add('${t.tr('Chiều cao:')} ${characteristics['height']}');
    }
    if (characteristics['lifespan'] != null) {
      facts.add('${t.tr('Tuổi thọ:')} ${characteristics['lifespan']}');
    }
    if (characteristics['diet'] != null) {
      facts.add('${t.tr('Chế độ ăn:')} ${characteristics['diet']}');
    }

    final imageUrl =
        remoteImageUrl ??
        'https://upload.wikimedia.org/wikipedia/commons/7/73/Lion_waiting_in_Namibia.jpg';

    return AnimalFact(
      name: t.tr(
        _getVietnameseName(name),
      ), // Bọc t.tr để dịch ngược tên con vật ra tiếng Anh
      englishName: name,
      scientificName: taxonomy,
      description:
          aiDescription ?? _generateDescription(t), // Truyền t vào desc
      facts: facts.isEmpty ? [t.tr('Đang cập nhật thông tin...')] : facts,
      imageUrl: imageUrl,
      category: characteristics['diet'] ?? 'Unknown',
    );
  }

  String _getVietnameseName(String englishName) {
    final nameMap = {
      'lion': 'Sư tử',
      'tiger': 'Hổ',
      'elephant': 'Voi',
      'african elephant': 'Voi châu Phi',
      'asian elephant': 'Voi châu Á',
      'bear': 'Gấu',
      'wolf': 'Sói',
      'eagle': 'Đại bàng',
      'dolphin': 'Cá heo',
      'shark': 'Cá mập',
      'whale shark': 'Cá mập voi',
      'goblin shark': 'Cá mập yêu tinh',
      'hammerhead shark': 'Cá mập đầu búa',
      'panda': 'Gấu trúc',
      'giraffe': 'Hươu cao cổ',
      'zebra': 'Ngựa vằn',
      'cheetah': 'Báo gêpa',
      'snow leopard': 'Báo tuyết',
      'clouded leopard': 'Báo gấm',
      'gorilla': 'Khỉ đột',
      'penguin': 'Chim cánh cụt',
      'kangaroo': 'Chuột túi',
      'koala': 'Gấu túi',
      'rhino': 'Tê giác',
      'rhinoceros': 'Tê giác',
      'hippo': 'Hà mã',
      'hippopotamus': 'Hà mã',
      'leopard': 'Báo hoa mai',
      'jaguar': 'Báo đốm Mỹ',
      'serval': 'Mèo serval',
      'caracal': 'Mèo tai túm',
      'ocelot': 'Mèo ocelot',
      'capybara': 'Thủy lợn',
      'giant otter': 'Rái cá khổng lồ',
      'wolverine': 'Chồn wolverine',
      'honey badger': 'Chồn mật',
      'binturong': 'Cầy hương đuôi dài',
      'pangolin': 'Tê tê',
      'platypus': 'Thú mỏ vịt',
      'axolotl': 'Sa giông axolotl',
      'komodo dragon': 'Rồng Komodo',
      'narwhal': 'Cá voi một sừng',
      'beluga whale': 'Cá voi trắng',
      'dugong': 'Cá cúi',
      'manatee': 'Bò biển',
      'shoebill': 'Chim mỏ guốc',
      'harpy eagle': 'Đại bàng harpy',
      'kakapo': 'Vẹt kakapo',
      'cassowary': 'Đà điểu cassowary',
      'manta ray': 'Cá đuối manta',
      'leafy sea dragon': 'Rồng biển lá',
      'gila monster': 'Thằn lằn Gila',
      'okapi': 'Ngựa vằn okapi',
      'tapir': 'Heo vòi',
      'aardvark': 'Lợn đất',
      'fossa': 'Cầy fossa',
      'echidna': 'Thú lông nhím',
      'kiwi': 'Chim kiwi',
      'lyrebird': 'Chim đuôi lyre',
      'hoatzin': 'Chim hoatzin',
    };
    return nameMap[englishName.toLowerCase()] ?? englishName;
  }

  // Truyền tham số t vào đây
  String _generateDescription(LocaleProvider t) {
    final parts = <String>[];

    if (characteristics['habitat'] != null) {
      parts.add('${t.tr('Môi trường sống:')} ${characteristics['habitat']}');
    } else if (locations.isNotEmpty) {
      parts.add('${t.tr('Phân bố tại')} ${locations.take(2).join(', ')}');
    }

    if (characteristics['diet'] != null) {
      parts.add('${t.tr('chế độ ăn')} ${characteristics['diet']}');
    }

    if (characteristics['top_speed'] != null) {
      parts.add('${t.tr('tốc độ tối đa')} ${characteristics['top_speed']}');
    }

    return parts.isEmpty
        ? t.tr('Đang cập nhật mô tả cho loài này.')
        : '${parts.join('. ')}.';
  }
}

class AnimalFact {
  final String name;
  final String englishName;
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
