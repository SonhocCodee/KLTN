import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/animal_api_service.dart';
import '../../services/daily_fact_cache.dart';

import '../../services/gemini_extended_image.dart';
import '../../utils/extended_animal_image.dart';
import '../../utils/smart_animal_image.dart';
import '../models/animal_data.dart';

class DailyFactScreen extends StatefulWidget {
  final String imageUrl = 'https://example.com/animal.jpg';
  const DailyFactScreen({super.key});

  @override
  State<DailyFactScreen> createState() => _DailyFactScreenState();
}

class _DailyFactScreenState extends State<DailyFactScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final AnimalApiService _apiService = AnimalApiService();

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

  // TÌM ẢNH WIKI - DÙNG TÊN TIẾNG ANH
  Future<String?> _fetchWikiImage(String query) async {
    print('🔍 Tìm Wiki cho: "$query"');

    try {
      // URL encode để xử lý space và ký tự đặc biệt
      final encodedQuery = Uri.encodeComponent(query);
      final urlStr = 'https://en.wikipedia.org/w/api.php?'
          'action=query&'
          'titles=$encodedQuery&'
          'prop=pageimages&'
          'format=json&'
          'pithumbsize=1200&'
          'redirects=1';

      print('🌐 URL: $urlStr');

      final response = await http.get(Uri.parse(urlStr));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']?['pages'];

        if (pages != null) {
          final firstPage = (pages as Map).values.first;

          // Check nếu trang tồn tại và có ảnh
          if (firstPage['thumbnail'] != null) {
            final imageUrl = firstPage['thumbnail']['source'] as String;
            print('✅ Tìm thấy: $imageUrl');
            return imageUrl;
          } else {
            print('⚠️ Trang tồn tại nhưng không có ảnh');
          }
        }
      } else {
        print('❌ Wiki HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Wiki Exception: $e');
    }

    return null;
  }

  Future<void> _forceRefresh() async {
    print('🔄 Force refresh...');
    await DailyFactCache.clearCache();
    _loadTodayAnimal();
  }

  Future<void> _loadTodayAnimal() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Check cache
      var cached = await DailyFactCache.getCache();

      if (cached != null) {
        // Nếu cache có ảnh fallback/placeholder → xóa để fetch lại
        if (cached.imageUrl.contains('Lion_waiting_in_Namibia') ||
            cached.imageUrl.contains('pixabay.com') ||
            cached.imageUrl.contains('unsplash.com')) {
          print('🧹 Cache có ảnh cũ, xóa để fetch lại...');
          cached = null;
          await DailyFactCache.clearCache();
        }
      }

      if (cached != null) {
        print('💾 Dùng cache: ${cached.name}');
        setState(() {
          _todayFact = cached;
          _isLoading = false;
        });
        _controller.forward();
        return;
      }

      print('🚀 Fetch API mới...');

      // 2. Fetch từ API Ninjas
      final animalData = await _apiService.getTodayAnimal();

      if (animalData != null) {
        var fact = animalData.toAnimalFact();

        print('🦁 Animal: ${fact.name} (EN: ${fact.englishName})');

        // 3. Tìm ảnh Wiki - DÙNG TÊN TIẾNG ANH
        String? realImageUrl;

        // Thử 1: Tên tiếng Anh thường
        realImageUrl = await _fetchWikiImage(fact.englishName);

        // Thử 2: Tên khoa học
        if (realImageUrl == null && fact.scientificName.isNotEmpty) {
          print('🔄 Thử tên khoa học: ${fact.scientificName}');
          realImageUrl = await _fetchWikiImage(fact.scientificName);
        }

        // Thử 3: Thêm "animal"
        if (realImageUrl == null) {
          print('🔄 Thử thêm "(animal)"');
          realImageUrl = await _fetchWikiImage('${fact.englishName} animal');
        }

        // Fallback cuối cùng
        final finalImageUrl = realImageUrl ??
            'https://upload.wikimedia.org/wikipedia/commons/7/73/Lion_waiting_in_Namibia.jpg';

        final finalFact = AnimalFact(
          name: fact.name,
          englishName: fact.englishName,
          scientificName: fact.scientificName,
          description: fact.description,
          facts: fact.facts,
          imageUrl: finalImageUrl,
          category: fact.category,
        );

        await DailyFactCache.saveCache(finalFact);

        setState(() {
          _todayFact = finalFact;
          _isLoading = false;
        });
        _controller.forward();
      } else {
        setState(() {
          _todayFact = _getFallbackData();
          _isLoading = false;
        });
        _controller.forward();
      }
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
      description: 'Vua của các loài thú',
      facts: ['Chạy 50-80 km/h', 'Nặng 190-270 kg'],
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
              ElevatedButton(
                onPressed: _loadTodayAnimal,
                child: const Text('Thử lại'),
              ),
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
          // Background Image
          Positioned.fill(
            child: GeminiExtendedImage(
              originalImageUrl: _todayFact!.imageUrl,
              animalName: _todayFact!.englishName,
            ),
          ),

          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KIẾN THỨC THÚ VỊ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hôm nay: ${_todayFact!.name}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Animal Info
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _todayFact!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _todayFact!.scientificName,
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _todayFact!.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ..._todayFact!.facts.take(4).map((fact) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.circle, size: 6, color: Colors.orange),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  fact,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 32),
                      // Swipe indicator
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.keyboard_arrow_up_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Trượt lên để khám phá',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
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