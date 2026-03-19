// File: screens/daily_fact_screen.dart
//
// ĐÃ SỬA:
// 1. Dùng đúng tên cột database (name_vietnamese, name_english, scientific_name,
//    description_short, fun_fact_vietnamese, image_url, diet_type, primary_habitat,
//    max_speed_kmh, weight_avg_kg, lifespan_avg_years, conservation_status, etc.)
// 2. Đơn vị Việt Nam: kg, km/h, cm/m, năm
// 3. Flow cache đúng: check Supabase shared cache → generate nếu chưa có → lưu lại
// 4. Ảnh lấy từ field image_url trong DB trước, Wikipedia là fallback
// 5. SharedImageCacheService được tích hợp vào flow chính

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/daily_fact_cache.dart';
import '../../services/extended_animal_image.dart';
import '../../services/shared_image_cache_service.dart';
import '../models/animal_data.dart';

class DailyFactScreen extends StatefulWidget {
  const DailyFactScreen({super.key});

  @override
  State<DailyFactScreen> createState() => _DailyFactScreenState();
}

class _DailyFactScreenState extends State<DailyFactScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // Getter lazy — tránh gọi trước khi Supabase.initialize() xong
  SupabaseClient get _supabase => Supabase.instance.client;

  AnimalFact? _todayFact;
  bool _isLoading = true;
  String? _error;

  // ─────────────────────────────────────────────────────────────
  // KHỞI TẠO
  // ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _loadTodayAnimal();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // FORMAT ĐƠN VỊ VIỆT NAM
  // ─────────────────────────────────────────────────────────────

  /// Chuyển đổi tất cả đơn vị sang Việt Nam
  String _formatVietnameseUnits(String? text) {
    if (text == null || text.isEmpty) return '';
    var result = text;

    // mph → km/h
    final mphRegex = RegExp(r'(\d+(?:\.\d+)?)\s*(?:–|-|to)\s*(\d+(?:\.\d+)?)\s*mph');
    result = result.replaceAllMapped(mphRegex, (m) {
      final low = (double.parse(m.group(1)!) * 1.609).round();
      final high = (double.parse(m.group(2)!) * 1.609).round();
      return '$low–$high km/h';
    });
    final mphSingle = RegExp(r'(\d+(?:\.\d+)?)\s*mph');
    result = result.replaceAllMapped(mphSingle, (m) {
      final speed = (double.parse(m.group(1)!) * 1.609).round();
      return '$speed km/h';
    });

    // lbs / pounds → kg
    final lbsRegex = RegExp(r'(\d+(?:\.\d+)?)\s*(?:–|-|to)\s*(\d+(?:\.\d+)?)\s*(?:lbs?|pounds?)');
    result = result.replaceAllMapped(lbsRegex, (m) {
      final low = (double.parse(m.group(1)!) * 0.453).round();
      final high = (double.parse(m.group(2)!) * 0.453).round();
      return '$low–$high kg';
    });
    final lbsSingle = RegExp(r'(\d+(?:\.\d+)?)\s*(?:lbs?|pounds?)');
    result = result.replaceAllMapped(lbsSingle, (m) {
      final kg = (double.parse(m.group(1)!) * 0.453).round();
      return '$kg kg';
    });

    // feet → cm hoặc m
    final feetRegex = RegExp(r'(\d+(?:\.\d+)?)\s*(?:–|-|to)\s*(\d+(?:\.\d+)?)\s*(?:feet|ft)');
    result = result.replaceAllMapped(feetRegex, (m) {
      final low = (double.parse(m.group(1)!) * 30.48).round();
      final high = (double.parse(m.group(2)!) * 30.48).round();
      return '${low}–${high} cm';
    });
    final feetSingle = RegExp(r'(\d+(?:\.\d+)?)\s*(?:feet|ft)');
    result = result.replaceAllMapped(feetSingle, (m) {
      final cm = (double.parse(m.group(1)!) * 30.48).round();
      return '$cm cm';
    });

    // inches → cm
    final inchRegex = RegExp(r'(\d+(?:\.\d+)?)\s*(?:inches?|in\b)');
    result = result.replaceAllMapped(inchRegex, (m) {
      final cm = (double.parse(m.group(1)!) * 2.54).round();
      return '$cm cm';
    });

    // miles → km
    final milesRegex = RegExp(r'(\d+(?:\.\d+)?)\s*miles?');
    result = result.replaceAllMapped(milesRegex, (m) {
      final km = (double.parse(m.group(1)!) * 1.609).round();
      return '$km km';
    });

    // Địa danh tiếng Anh → tiếng Việt
    const locationMap = {
      'Sub-Saharan Africa': 'Châu Phi hạ Sahara',
      'North Africa': 'Bắc Phi',
      'South Africa': 'Nam Phi',
      'Africa': 'Châu Phi',
      'Asia': 'Châu Á',
      'Southeast Asia': 'Đông Nam Á',
      'South Asia': 'Nam Á',
      'East Asia': 'Đông Á',
      'Central Asia': 'Trung Á',
      'Europe': 'Châu Âu',
      'North America': 'Bắc Mỹ',
      'South America': 'Nam Mỹ',
      'Central America': 'Trung Mỹ',
      'Australia': 'Châu Úc',
      'Antarctica': 'Nam Cực',
      'Arctic': 'Bắc Cực',
      'Amazon': 'Amazon',
      'Savanna': 'Thảo nguyên',
      'savanna': 'thảo nguyên',
      'Rainforest': 'Rừng nhiệt đới',
      'rainforest': 'rừng nhiệt đới',
      'Forest': 'Rừng',
      'forest': 'rừng',
      'Desert': 'Sa mạc',
      'desert': 'sa mạc',
      'Ocean': 'Đại dương',
      'ocean': 'đại dương',
      'Grassland': 'Đồng cỏ',
      'grassland': 'đồng cỏ',
      'Tropical': 'Nhiệt đới',
      'tropical': 'nhiệt đới',
      'Mountain': 'Núi',
      'mountain': 'núi',
      'Wetland': 'Đất ngập nước',
      'wetland': 'đất ngập nước',
    };

    locationMap.forEach((en, vi) {
      result = result.replaceAll(en, vi);
    });

    return result.trim();
  }

  /// Build chuỗi mô tả thống kê từ các trường số trong DB
  String _buildDescription(Map<String, dynamic> animal) {
    final List<String> parts = [];

    // Mô tả gốc (tiếng Việt nếu có)
    final descVi = animal['description_short'] as String?;
    if (descVi != null && descVi.isNotEmpty) {
      parts.add(_formatVietnameseUnits(descVi));
    }

    return parts.join(' ');
  }

  /// Build danh sách facts từ các trường DB
  List<String> _buildFacts(Map<String, dynamic> animal) {
    final List<String> facts = [];

    // Cân nặng
    final wMin = animal['weight_min_kg'];
    final wMax = animal['weight_max_kg'];
    final wAvg = animal['weight_avg_kg'];
    if (wMin != null && wMax != null) {
      facts.add('Cân nặng: ${_formatNum(wMin)}–${_formatNum(wMax)} kg');
    } else if (wAvg != null) {
      facts.add('Cân nặng trung bình: ${_formatNum(wAvg)} kg');
    }

    // Chiều dài
    final lMin = animal['length_min_m'];
    final lMax = animal['length_max_m'];
    if (lMin != null && lMax != null) {
      final lowCm = (lMin * 100).round();
      final highCm = (lMax * 100).round();
      if (highCm > 200) {
        facts.add('Chiều dài: ${lMin.toStringAsFixed(1)}–${lMax.toStringAsFixed(1)} m');
      } else {
        facts.add('Chiều dài: $lowCm–$highCm cm');
      }
    }

    // Tốc độ tối đa
    final speed = animal['max_speed_kmh'];
    if (speed != null) {
      facts.add('Tốc độ tối đa: ${_formatNum(speed)} km/h');
    }

    // Tuổi thọ
    final lifeMin = animal['lifespan_min_years'];
    final lifeMax = animal['lifespan_max_years'];
    if (lifeMin != null && lifeMax != null) {
      facts.add('Tuổi thọ: $lifeMin–$lifeMax năm');
    }

    // Chế độ ăn
    final dietType = animal['diet_type'] as String?;
    if (dietType != null) {
      const dietMap = {
        'carnivore': 'Ăn thịt (Carnivore)',
        'herbivore': 'Ăn cỏ (Herbivore)',
        'omnivore': 'Ăn tạp (Omnivore)',
        'insectivore': 'Ăn côn trùng',
        'piscivore': 'Ăn cá (Piscivore)',
        'frugivore': 'Ăn trái cây (Frugivore)',
      };
      facts.add('Chế độ ăn: ${dietMap[dietType] ?? dietType}');
    }

    // Môi trường sống
    final habitat = animal['primary_habitat'] as String?;
    if (habitat != null) {
      const habitatMap = {
        'tropicalRainforest': 'Rừng nhiệt đới',
        'savanna': 'Thảo nguyên',
        'desert': 'Sa mạc',
        'temperateForest': 'Rừng ôn đới',
        'tundra': 'Đồng băng',
        'mountain': 'Núi cao',
        'freshwater': 'Nước ngọt',
        'ocean': 'Đại dương',
        'coastal': 'Ven biển',
        'arctic': 'Bắc Cực',
        'antarctic': 'Nam Cực',
        'wetland': 'Đất ngập nước',
        'grassland': 'Đồng cỏ',
      };
      facts.add('Môi trường sống: ${habitatMap[habitat] ?? habitat}');
    }

    // Tình trạng bảo tồn
    final conservation = animal['conservation_status'] as String?;
    if (conservation != null) {
      const conservationMap = {
        'EX': '🔴 Tuyệt chủng (EX)',
        'EW': '🔴 Tuyệt chủng ngoài tự nhiên (EW)',
        'CR': '🟠 Cực kỳ nguy cấp (CR)',
        'EN': '🟡 Nguy cấp (EN)',
        'VU': '🟡 Sắp nguy cấp (VU)',
        'NT': '🟢 Sắp bị đe dọa (NT)',
        'LC': '🟢 Ít lo ngại (LC)',
        'DD': '⚪ Thiếu dữ liệu (DD)',
      };
      facts.add('Tình trạng: ${conservationMap[conservation] ?? conservation}');
    }

    // Fun fact tiếng Việt ưu tiên
    final funFactVi = animal['fun_fact_vietnamese'] as String?;
    final funFactEn = animal['fun_fact_english'] as String?;
    final funFact = (funFactVi != null && funFactVi.isNotEmpty)
        ? funFactVi
        : (funFactEn != null && funFactEn.isNotEmpty ? _formatVietnameseUnits(funFactEn) : null);
    if (funFact != null) {
      facts.add('✨ $funFact');
    }

    return facts;
  }

  String _formatNum(dynamic val) {
    if (val == null) return '?';
    final d = (val is num) ? val.toDouble() : double.tryParse(val.toString()) ?? 0;
    if (d == d.roundToDouble()) return d.round().toString();
    return d.toStringAsFixed(1);
  }

  // ─────────────────────────────────────────────────────────────
  // TÌM ẢNH WIKIPEDIA (fallback)
  // ─────────────────────────────────────────────────────────────
  Future<String?> _fetchWikiImage(String englishName) async {
    try {
      final encoded = Uri.encodeComponent(englishName);
      final url = 'https://en.wikipedia.org/w/api.php'
          '?action=query&titles=$encoded&prop=pageimages'
          '&format=json&pithumbsize=1200&redirects=1';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final pages = data['query']?['pages'] as Map?;
        if (pages != null) {
          final page = pages.values.first;
          return page['thumbnail']?['source'] as String?;
        }
      }
    } catch (e) {
      print('⚠️ [Wiki] $e');
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // FORCE REFRESH
  // ─────────────────────────────────────────────────────────────
  Future<void> _forceRefresh() async {
    await DailyFactCache.clearCache();
    _loadTodayAnimal();
  }

  // ─────────────────────────────────────────────────────────────
  // LOAD DỮ LIỆU CHÍNH
  // ─────────────────────────────────────────────────────────────
  Future<void> _loadTodayAnimal() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // ══════════════════════════════════════════
      // BƯỚC 1: Check cache local + Supabase
      // ══════════════════════════════════════════
      final cached = await DailyFactCache.getCache();
      if (cached != null) {
        print('✅ [DailyFact] Dùng cache');
        if (mounted) {
          setState(() {
            _todayFact = cached;
            _isLoading = false;
          });
          _controller.forward();
        }
        return;
      }

      // ══════════════════════════════════════════════════════════════
      // BƯỚC 2: Chọn ngẫu nhiên 1 con theo seed ngày
      //
      // Chiến lược:
      //  - Các bảng loài (cats, dogs, tigers...) chỉ lưu đặc điểm riêng
      //    và dùng animal_id → FK tới bảng animals
      //  - Bảng animals chứa toàn bộ tên, ảnh, mô tả
      //  - Ta random trong animals, nhưng ưu tiên những con có data
      //    trong ít nhất 1 bảng loài (cats, dogs, tigers, lions, bears...)
      //  - Nếu không có → random toàn bộ animals
      // ══════════════════════════════════════════════════════════════
      final now = DateTime.now();
      final seed = now.year * 10000 + now.month * 100 + now.day;
      final random = Random(seed);

      // Danh sách các bảng loài hiện có trong DB
      // Thêm tên bảng mới vào đây khi có data
      const speciesTables = ['cats', 'dogs', 'tigers', 'lions', 'bears', 'horses', 'cattle', 'buffalo'];

      // Lấy tất cả animal_id có trong các bảng loài
      final Set<String> idsWithSpeciesData = {};
      for (final table in speciesTables) {
        try {
          final res = await _supabase.from(table).select('animal_id');
          for (final row in res) {
            final id = row['animal_id']?.toString();
            if (id != null) idsWithSpeciesData.add(id);
          }
        } catch (_) {
          // Bảng chưa tồn tại hoặc chưa có data → bỏ qua
        }
      }
      print('📊 [DailyFact] Tìm thấy ${idsWithSpeciesData.length} con có data loài');

      Map<String, dynamic>? animal;

      // Ưu tiên random trong danh sách con có đầy đủ data
      if (idsWithSpeciesData.isNotEmpty) {
        final idList = idsWithSpeciesData.toList();
        // Dùng seed ngày để chọn cùng 1 con trong ngày, khác ngày khác con
        final pickedId = idList[random.nextInt(idList.length)];

        final rows = await _supabase
            .from('animals')
            .select(
          'id, name_vietnamese, name_english, scientific_name, '
              'description_short, description_long, '
              'fun_fact_vietnamese, fun_fact_english, '
              'image_url, image_urls, '
              'diet_type, primary_habitat, '
              'weight_min_kg, weight_max_kg, weight_avg_kg, '
              'length_min_m, length_max_m, '
              'max_speed_kmh, '
              'lifespan_min_years, lifespan_max_years, lifespan_avg_years, '
              'conservation_status, is_endangered, '
              'geographic_regions, countries',
        )
            .eq('id', pickedId);

        if (rows.isNotEmpty) animal = rows.first;
      }

      // Fallback: random toàn bộ bảng animals nếu chưa có species data
      if (animal == null) {
        print('⚠️ [DailyFact] Không có species data, random toàn bộ animals...');
        final countRes = await _supabase
            .from('animals')
            .select('id')
            .count(CountOption.exact);
        final totalCount = countRes.count;

        if (totalCount == 0) throw Exception('Bảng animals trống — hãy thêm data vào Supabase');

        final offset = random.nextInt(totalCount);
        final rows = await _supabase
            .from('animals')
            .select(
          'id, name_vietnamese, name_english, scientific_name, '
              'description_short, description_long, '
              'fun_fact_vietnamese, fun_fact_english, '
              'image_url, image_urls, '
              'diet_type, primary_habitat, '
              'weight_min_kg, weight_max_kg, weight_avg_kg, '
              'length_min_m, length_max_m, '
              'max_speed_kmh, '
              'lifespan_min_years, lifespan_max_years, lifespan_avg_years, '
              'conservation_status, is_endangered, '
              'geographic_regions, countries',
        )
            .range(offset, offset);

        if (rows.isEmpty) throw Exception('Không lấy được dữ liệu');
        animal = rows.first;
      }
      print('✅ [DailyFact] Đã chọn: ${animal['name_vietnamese']} (${animal['name_english']})');

      // ══════════════════════════════════════════
      // BƯỚC 4: Xử lý ảnh
      // Thứ tự: DB image_url → SharedCache (Supabase) → Wikipedia
      // ══════════════════════════════════════════
      String? finalImageUrl = animal['image_url'] as String?;

      if (finalImageUrl == null || finalImageUrl.isEmpty) {
        // Thử image_urls array
        final imageUrls = animal['image_urls'];
        if (imageUrls is List && imageUrls.isNotEmpty) {
          finalImageUrl = imageUrls.first as String?;
        }
      }

      if (finalImageUrl == null || finalImageUrl.isEmpty) {
        // Fallback Wikipedia
        print('📷 [DailyFact] Không có ảnh trong DB, thử Wikipedia...');
        final nameEn = animal['name_english'] as String? ?? '';
        finalImageUrl = await _fetchWikiImage(nameEn);
      }

      // Fallback cuối cùng
      finalImageUrl ??= 'https://upload.wikimedia.org/wikipedia/commons/7/73/Lion_waiting_in_Namibia.jpg';

      // ══════════════════════════════════════════
      // BƯỚC 5: Check shared image cache (Supabase Storage)
      // Người đầu tiên vào sẽ trigger ClipDrop → lưu lên Supabase
      // Người sau đọc thẳng URL từ Supabase
      // ══════════════════════════════════════════
      final sharedImageUrl = await SharedImageCacheService.getSharedCachedImage(finalImageUrl);
      if (sharedImageUrl != null) {
        print('🌐 [DailyFact] Dùng shared image cache: $sharedImageUrl');
        finalImageUrl = sharedImageUrl;
      }
      // Nếu chưa có shared cache → ExtendedAnimalImage widget sẽ gọi ClipDrop
      // và sau đó lưu lên qua SharedImageCacheService (xem extended_animal_image.dart)

      // ══════════════════════════════════════════
      // BƯỚC 6: Build AnimalFact object
      // ══════════════════════════════════════════
      final description = _buildDescription(animal);
      final facts = _buildFacts(animal);

      // Region/countries
      final regions = (animal['geographic_regions'] as List?)
          ?.map((e) => e.toString())
          .toList() ?? [];
      final locationText = regions.isNotEmpty
          ? regions.map(_translateRegion).join(', ')
          : null;

      final finalFact = AnimalFact(
        name: animal['name_vietnamese'] as String? ?? 'Động vật',
        englishName: animal['name_english'] as String? ?? '',
        scientificName: animal['scientific_name'] as String? ?? '',
        description: description.isNotEmpty
            ? description
            : (locationText != null ? 'Phân bố tại $locationText.' : ''),
        facts: facts,
        imageUrl: finalImageUrl,
        category: animal['diet_type'] as String? ?? '',
      );

      // ══════════════════════════════════════════
      // BƯỚC 7: Lưu cache (local + Supabase)
      // ══════════════════════════════════════════
      await DailyFactCache.saveCache(finalFact);

      if (mounted) {
        setState(() {
          _todayFact = finalFact;
          _isLoading = false;
        });
        _controller.forward();
      }

    } catch (e) {
      print('❌ [DailyFact] Error: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _todayFact = _getFallbackData();
          _isLoading = false;
        });
        _controller.forward();
      }
    }
  }

  String _translateRegion(String region) {
    const map = {
      'Africa': 'Châu Phi',
      'Asia': 'Châu Á',
      'Europe': 'Châu Âu',
      'North America': 'Bắc Mỹ',
      'South America': 'Nam Mỹ',
      'Australia': 'Châu Úc',
      'Antarctica': 'Nam Cực',
      'Southeast Asia': 'Đông Nam Á',
      'South Asia': 'Nam Á',
      'East Asia': 'Đông Á',
    };
    return map[region] ?? region;
  }

  AnimalFact _getFallbackData() {
    return AnimalFact(
      name: 'Sư tử',
      englishName: 'Lion',
      scientificName: 'Panthera leo',
      description: 'Vua của các loài thú, phân bố tại Châu Phi hạ Sahara.',
      facts: [
        'Cân nặng: 120–249 kg',
        'Tốc độ tối đa: 80 km/h',
        'Tuổi thọ: 10–14 năm',
        'Chế độ ăn: Ăn thịt (Carnivore)',
        'Môi trường sống: Thảo nguyên',
        'Tình trạng: 🟡 Sắp nguy cấp (VU)',
        '✨ Sư tử đực có thể ngủ đến 20 giờ mỗi ngày!',
      ],
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/7/73/Lion_waiting_in_Namibia.jpg',
      category: 'carnivore',
    );
  }

  // ─────────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          color: const Color(0xFF0F172A),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Đang tải thông tin loài vật...',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
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
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Có lỗi xảy ra'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadTodayAnimal,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
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
          // ── ẢNH NỀN (ExtendedAnimalImage xử lý ClipDrop + SharedCache) ──
          Positioned.fill(
            child: ExtendedAnimalImage(
              originalImageUrl: _todayFact!.imageUrl,
              animalName: _todayFact!.englishName,
            ),
          ),

          // ── GRADIENT CHE MỜ ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.transparent,
                    Colors.black.withOpacity(0.90),
                  ],
                  stops: const [0.0, 0.35, 1.0],
                ),
              ),
            ),
          ),

          // ── NỘI DUNG ──
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KIẾN THỨC THÚ VỊ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
                          shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ngày ${DateTime.now().day} tháng ${DateTime.now().month} năm ${DateTime.now().year}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // THÔNG TIN CHÍNH
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên Việt Nam
                      Text(
                        _todayFact!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          shadows: [
                            Shadow(blurRadius: 12, color: Colors.black87),
                          ],
                        ),
                      ),

                      // Tên khoa học
                      if (_todayFact!.scientificName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _todayFact!.scientificName,
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],

                      // Tên tiếng Anh
                      if (_todayFact!.englishName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _todayFact!.englishName,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 13,
                          ),
                        ),
                      ],

                      // Mô tả
                      if (_todayFact!.description.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          _todayFact!.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: 14,
                            height: 1.55,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // Danh sách facts (tối đa 4)
                      const SizedBox(height: 16),
                      ..._todayFact!.facts.take(4).map((fact) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 3),
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: 12,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  fact,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      // Nút gợi ý
                      const SizedBox(height: 28),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.25)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.keyboard_arrow_up_rounded,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Trượt lên để khám phá',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
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