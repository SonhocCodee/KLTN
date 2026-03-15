import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math'; // Thêm để dùng Random
import 'package:http/http.dart' as http;
import '../../services/animal_api_service.dart';
import '../../services/animal_home_service.dart'; // Import service Supabase
import '../../services/daily_fact_cache.dart';
import '../../services/extended_animal_image.dart';
import '../../services/extended_image_cache.dart';
import '../models/animal_data.dart';

class DailyFactScreen extends StatefulWidget {
  const DailyFactScreen({super.key});

  @override
  State<DailyFactScreen> createState() => _DailyFactScreenState();
}

class _DailyFactScreenState extends State<DailyFactScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final AnimalHomeService _homeService = AnimalHomeService(); // Dùng Supabase Service

  AnimalFact? _todayFact;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _loadTodayAnimal();
  }

  /// Hàm hỗ trợ dịch thuật và chuyển đổi đơn vị
  String _processText(String? text) {
    if (text == null || text.isEmpty) return '';

    var result = text;

    // 1. Chuyển đổi đơn vị tốc độ (mph -> km/h)
    // Tìm các số đi kèm với mph, ví dụ "30 - 40 mph" hoặc "50 mph"
    final mphRegex = RegExp(r'(\d+)\s*(?:-\s*(\d+))?\s*mph');
    result = result.replaceAllMapped(mphRegex, (match) {
      try {
        if (match.group(2) != null) {
          int low = (int.parse(match.group(1)!) * 1.609).round();
          int high = (int.parse(match.group(2)!) * 1.609).round();
          return '$low - $high km/h';
        } else {
          int speed = (int.parse(match.group(1)!) * 1.609).round();
          return '$speed km/h';
        }
      } catch (e) {
        return match.group(0)!;
      }
    });

    // 2. Dịch các châu lục và địa danh phổ biến
    final Map<String, String> translationMap = {
      'Africa': 'Châu Phi',
      'Asia': 'Châu Á',
      'Europe': 'Châu Âu',
      'North America': 'Bắc Mỹ',
      'South America': 'Nam Mỹ',
      'Australia': 'Châu Úc',
      'Antarctica': 'Nam Cực',
      'Ocean': 'Đại dương',
      'Forest': 'Rừng rậm',
      'Desert': 'Sa mạc',
      'Tropical': 'Nhiệt đới',
      'Savanna': 'Thảo nguyên',
    };

    translationMap.forEach((en, vi) {
      result = result.replaceAll(RegExp(en, caseSensitive: false), vi);
    });

    // 3. Xóa các câu giới thiệu rập khuôn (nếu có trong dữ liệu)
    result = result.replaceAll(RegExp(r'.*là một loài động vật có nhiều đặc điểm thú vị\.?'), '');
    result = result.replaceAll(RegExp(r'Sống chủ yếu ở', caseSensitive: false), 'Phân bố tại');

    return result.trim();
  }

  /// Tìm ảnh Wikipedia cho động vật
  Future<String?> _fetchWikiImage(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final urlStr = 'https://en.wikipedia.org/w/api.php?'
          'action=query&'
          'titles=$encodedQuery&'
          'prop=pageimages&'
          'format=json&'
          'pithumbsize=1200&'
          'redirects=1';

      final response = await http.get(Uri.parse(urlStr));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']?['pages'];
        if (pages != null) {
          final firstPage = (pages as Map).values.first;
          if (firstPage['thumbnail'] != null) {
            return firstPage['thumbnail']['source'] as String;
          }
        }
      }
    } catch (e) {
      print('❌ Wiki Exception: $e');
    }
    return null;
  }

  Future<void> _forceRefresh() async {
    await DailyFactCache.clearCache();
    await ExtendedImageCache.clearCache();
    _loadTodayAnimal();
  }

  /// Load thông tin động vật của hôm nay (Chống lặp bằng Random Seed)
  Future<void> _loadTodayAnimal() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Kiểm tra cache
      var cached = await DailyFactCache.getCache();
      if (cached != null) {
        setState(() {
          _todayFact = cached;
          _isLoading = false;
        });
        _controller.forward();
        return;
      }

      // 2. Lấy dữ liệu từ Supabase để Random (Dùng ngày làm Seed để không trùng)
      final stats = await _homeService.getStatistics();
      final countsByType = stats['counts_by_type'] as Map<String, int>;

      if (countsByType.isEmpty) throw Exception("Không có dữ liệu");

      // Tạo seed từ ngày hiện tại: 20240520
      final now = DateTime.now();
      final seed = now.year * 10000 + now.month * 100 + now.day;
      final random = Random(seed);

      // Chọn ngẫu nhiên 1 loại động vật từ database
      List<String> allTypes = countsByType.keys.toList();
      String randomType = allTypes[random.nextInt(allTypes.length)];

      // Lấy danh sách con vật thuộc loại đó và chọn 1 con
      final animalsInType = await _homeService.getAnimalsByType(randomType);
      final selectedAnimal = animalsInType[random.nextInt(animalsInType.length)];

      // 3. Xử lý dữ liệu (Dịch và đổi đơn vị)
      String nameEn = selectedAnimal['name_english'] ?? randomType;
      String desc = _processText(selectedAnimal['description'] ?? '');

      // Tạo danh sách facts thực tế từ database
      List<String> facts = [];
      if (selectedAnimal['diet'] != null) facts.add('Chế độ ăn: ${_processText(selectedAnimal['diet'])}');
      if (selectedAnimal['habitat'] != null) facts.add('Môi trường sống: ${_processText(selectedAnimal['habitat'])}');
      if (selectedAnimal['fun_fact'] != null) facts.add(_processText(selectedAnimal['fun_fact']));

      // 4. Tìm ảnh Wikipedia
      String? wikiImageUrl = await _fetchWikiImage(nameEn);
      final finalImageUrl = wikiImageUrl ?? 'https://upload.wikimedia.org/wikipedia/commons/7/73/Lion_waiting_in_Namibia.jpg';

      final finalFact = AnimalFact(
        name: selectedAnimal['name_vietnamese'] ?? randomType,
        englishName: nameEn,
        scientificName: selectedAnimal['scientific_name'] ?? '',
        description: desc,
        facts: facts,
        imageUrl: finalImageUrl,
        category: selectedAnimal['animal_type'] ?? '',
      );

      // 5. Lưu cache
      await DailyFactCache.saveCache(finalFact);

      setState(() {
        _todayFact = finalFact;
        _isLoading = false;
      });
      _controller.forward();

    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _error = 'Không thể tải dữ liệu';
        _todayFact = _getFallbackData();
        _isLoading = false;
      });
      _controller.forward();
    }
  }

  AnimalFact _getFallbackData() {
    return AnimalFact(
      name: 'Sư tử',
      englishName: 'Lion',
      scientificName: 'Panthera leo',
      description: 'Vua của các loài thú, phân bố tại Châu Phi.',
      facts: ['Chạy 80 km/h', 'Nặng 190-270 kg'],
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/7/73/Lion_waiting_in_Namibia.jpg',
      category: 'Carnivore',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          color: const Color(0xFF0F172A),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    if (_todayFact == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              Text(_error ?? 'Lỗi'),
              ElevatedButton(onPressed: _loadTodayAnimal, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: _forceRefresh,
        backgroundColor: Colors.white.withOpacity(0.2),
        elevation: 0,
        child: const Icon(Icons.refresh, color: Colors.white, size: 20),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body: Stack(
        children: [
          Positioned.fill(
            child: ExtendedAnimalImage(
              originalImageUrl: _todayFact!.imageUrl,
              animalName: _todayFact!.englishName,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KIẾN THỨC THÚ VỊ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ngày ${DateTime.now().day}/${DateTime.now().month}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _todayFact!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _todayFact!.scientificName,
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _todayFact!.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ..._todayFact!.facts.take(3).map((fact) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4.0),
                                child: Icon(Icons.auto_awesome, size: 12, color: Colors.orange),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  fact,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 32),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Trượt lên để khám phá',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}