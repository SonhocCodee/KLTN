

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
  SupabaseClient get _supabase => Supabase.instance.client;

  AnimalFact? _todayFact;
  bool _isLoading = true;
  String? _error;

  // Danh sách tất cả bảng có thể random (mỗi bảng là độc lập)
  static const _allTables = ['animals', 'cats', 'dogs', 'tigers', 'lions', 'bears', 'horses', 'cattle', 'buffalo'];

  // Các cột cần select (chỉ những cột tồn tại trong schema)
  static const _selectCols =
      'id, name_vietnamese, name_english, scientific_name, '
      'description_short, description_long, '
      'fun_fact_vietnamese, fun_fact_english, '
      'image_url, image_urls, '
      'diet_type, primary_habitat, '
      'weight_avg_kg, height_avg_m, length_avg_m, '
      'max_speed_kmh, lifespan_avg_years, '
      'conservation_status, is_endangered, '
      'geographic_regions, countries, '
      'social_structure, activity_pattern, '
      'gestation_period_days, litter_size_avg, '
      'has_horns, has_tusks, has_mane, has_wings, has_trunk, '
      'temperament, danger_to_humans, intelligence_level';

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
  // FORMAT SỐ
  // ─────────────────────────────────────────────────────────────
  String _fmt(dynamic val, {int decimals = 1}) {
    if (val == null) return '?';
    final d = (val is num) ? val.toDouble() : double.tryParse(val.toString()) ?? 0;
    if (d == d.roundToDouble()) return d.round().toString();
    return d.toStringAsFixed(decimals);
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD DESCRIPTION từ DB
  // ─────────────────────────────────────────────────────────────
  String _buildDescription(Map<String, dynamic> a) {
    final descVi = a['description_short'] as String?;
    if (descVi != null && descVi.trim().isNotEmpty) return descVi.trim();

    final descLong = a['description_long'] as String?;
    if (descLong != null && descLong.trim().isNotEmpty) {
      // Lấy câu đầu tiên từ description_long
      final firstSentence = descLong.split(RegExp(r'[.!?]')).first.trim();
      if (firstSentence.isNotEmpty) return '$firstSentence.';
    }

    // Build mô tả từ các trường có sẵn
    final parts = <String>[];
    final habitat = _mapHabitat(a['primary_habitat'] as String?);
    final regions = (a['geographic_regions'] as List?)?.map((e) => _mapRegion(e.toString())).toList();

    if (habitat != null) parts.add('Sống ở $habitat');
    if (regions != null && regions.isNotEmpty) parts.add('phân bố tại ${regions.take(2).join(', ')}');

    return parts.isNotEmpty ? '${parts.join(', ')}.' : '';
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD FACTS từ các cột thực tế trong DB
  // ─────────────────────────────────────────────────────────────
  List<String> _buildFacts(Map<String, dynamic> a) {
    final facts = <String>[];

    // Cân nặng (chỉ có avg)
    final weight = a['weight_avg_kg'];
    if (weight != null) facts.add('⚖️ Cân nặng: ${_fmt(weight)} kg');

    // Chiều dài
    final length = a['length_avg_m'];
    if (length != null) {
      final cm = ((length as num).toDouble() * 100).round();
      if (cm > 200) {
        facts.add('📏 Chiều dài: ${_fmt(length)} m');
      } else {
        facts.add('📏 Chiều dài: $cm cm');
      }
    }

    // Chiều cao
    final height = a['height_avg_m'];
    if (height != null && length == null) {
      final cm = ((height as num).toDouble() * 100).round();
      facts.add('📐 Chiều cao: $cm cm');
    }

    // Tốc độ tối đa
    final speed = a['max_speed_kmh'];
    if (speed != null) facts.add('💨 Tốc độ tối đa: ${_fmt(speed)} km/h');

    // Tuổi thọ
    final lifespan = a['lifespan_avg_years'];
    if (lifespan != null) facts.add('⏳ Tuổi thọ: ~${_fmt(lifespan)} năm');

    // Chế độ ăn
    final diet = _mapDiet(a['diet_type'] as String?);
    if (diet != null) facts.add('🍽️ Chế độ ăn: $diet');

    // Môi trường sống
    final habitat = _mapHabitat(a['primary_habitat'] as String?);
    if (habitat != null) facts.add('🌍 Môi trường: $habitat');

    // Tình trạng bảo tồn
    final conservation = _mapConservation(a['conservation_status'] as String?);
    if (conservation != null) facts.add('Tình trạng: $conservation');

    // Fun fact (ưu tiên tiếng Việt)
    final funFactVi = a['fun_fact_vietnamese'] as String?;
    final funFactEn = a['fun_fact_english'] as String?;
    final funFact = (funFactVi?.isNotEmpty == true) ? funFactVi : funFactEn;
    if (funFact != null && funFact.isNotEmpty) facts.add('✨ $funFact');

    // Thời gian mang thai (nếu có)
    final gestation = a['gestation_period_days'];
    if (gestation != null && facts.length < 5) {
      facts.add('🤰 Mang thai: $gestation ngày');
    }

    return facts;
  }

  // ─────────────────────────────────────────────────────────────
  // MAP HELPERS
  // ─────────────────────────────────────────────────────────────
  String? _mapDiet(String? d) {
    if (d == null) return null;
    const map = {
      'carnivore': 'Ăn thịt',
      'herbivore': 'Ăn thực vật',
      'omnivore': 'Ăn tạp',
      'insectivore': 'Ăn côn trùng',
      'piscivore': 'Ăn cá',
      'frugivore': 'Ăn trái cây',
    };
    return map[d] ?? d;
  }

  String? _mapHabitat(String? h) {
    if (h == null) return null;
    const map = {
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
      'urban': 'Đô thị',
      'domestic': 'Trong nhà',
    };
    return map[h] ?? h;
  }

  String? _mapConservation(String? c) {
    if (c == null) return null;
    const map = {
      'EX': '🔴 Tuyệt chủng (EX)',
      'EW': '🔴 Tuyệt chủng ngoài tự nhiên (EW)',
      'CR': '🟠 Cực kỳ nguy cấp (CR)',
      'EN': '🟡 Nguy cấp (EN)',
      'VU': '🟡 Sắp nguy cấp (VU)',
      'NT': '🟢 Sắp bị đe dọa (NT)',
      'LC': '🟢 Ít lo ngại (LC)',
      'DD': '⚪ Thiếu dữ liệu (DD)',
    };
    return map[c] ?? c;
  }

  String _mapRegion(String r) {
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
      'Central Asia': 'Trung Á',
    };
    return map[r] ?? r;
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
  // GỌI AI GENERATE NỘI DUNG (nếu DB thiếu description/fun_fact)
  // ─────────────────────────────────────────────────────────────
  Future<Map<String, String>> _generateAIContent(Map<String, dynamic> animal) async {
    final nameVi = animal['name_vietnamese'] ?? '';
    final nameEn = animal['name_english'] ?? '';
    final sciName = animal['scientific_name'] ?? '';

    // Tổng hợp thông tin có sẵn để AI viết chính xác hơn
    final knownFacts = <String>[];
    if (animal['weight_avg_kg'] != null) knownFacts.add('nặng ${_fmt(animal['weight_avg_kg'])} kg');
    if (animal['max_speed_kmh'] != null) knownFacts.add('tốc độ tối đa ${_fmt(animal['max_speed_kmh'])} km/h');
    if (animal['lifespan_avg_years'] != null) knownFacts.add('tuổi thọ ${_fmt(animal['lifespan_avg_years'])} năm');
    if (animal['primary_habitat'] != null) knownFacts.add('sống ở ${_mapHabitat(animal['primary_habitat'])}');
    if (animal['diet_type'] != null) knownFacts.add('chế độ ăn: ${_mapDiet(animal['diet_type'])}');

    final knownFactsStr = knownFacts.isNotEmpty ? 'Thông tin đã biết: ${knownFacts.join(', ')}.' : '';

    final prompt = '''Bạn là chuyên gia động vật học viết nội dung tiếng Việt cho trẻ em và người lớn.

Loài: $nameVi ($nameEn)
Tên khoa học: $sciName
$knownFactsStr

Hãy viết JSON với 2 trường:
1. "description": Mô tả ngắn 1-2 câu về loài này bằng tiếng Việt, thú vị và dễ hiểu (tối đa 120 ký tự)
2. "fun_fact": 1 sự thật thú vị bất ngờ về loài này bằng tiếng Việt (tối đa 100 ký tự)

Chỉ trả về JSON, không giải thích thêm.
Ví dụ: {"description": "...", "fun_fact": "..."}''';

    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'anthropic-version': '2023-06-01',
        },
        body: json.encode({
          'model': 'claude-haiku-4-5-20251001',
          'max_tokens': 300,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text = data['content'][0]['text'] as String;
        // Parse JSON từ response
        final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(text);
        if (jsonMatch != null) {
          final parsed = json.decode(jsonMatch.group(0)!);
          return {
            'description': parsed['description'] ?? '',
            'fun_fact': parsed['fun_fact'] ?? '',
          };
        }
      }
    } catch (e) {
      print('⚠️ [AI] Không generate được nội dung: $e');
    }
    return {'description': '', 'fun_fact': ''};
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
      // BƯỚC 0: Chờ Supabase initialize xong
      // ══════════════════════════════════════════
      int retries = 0;
      while (retries < 10) {
        try {
          Supabase.instance.client; // sẽ throw nếu chưa init
          break; // init xong → thoát vòng lặp
        } catch (_) {
          retries++;
          print('⏳ [DailyFact] Chờ Supabase init... ($retries/10)');
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
      if (retries >= 10) throw Exception('Supabase không khởi động được sau 3 giây');

      // ══════════════════════════════════════════
      // BƯỚC 1: Check cache local
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

      // ══════════════════════════════════════════
      // BƯỚC 2: Random bảng + random dòng
      //
      // Mỗi bảng (animals, cats, dogs, tigers...)
      // là bảng ĐỘC LẬP chứa đầy đủ thông tin.
      // → Thử từng bảng theo thứ tự random cho đến khi lấy được data.
      // ══════════════════════════════════════════
      final now = DateTime.now();
      final seed = now.year * 10000 + now.month * 100 + now.day;
      final random = Random(seed);

      // Shuffle bảng theo seed ngày để mỗi ngày ưu tiên bảng khác nhau
      final tables = List<String>.from(_allTables)..shuffle(random);

      Map<String, dynamic>? animal;
      String? sourceTable;

      for (final table in tables) {
        try {
          // Đếm số dòng trong bảng
          final countRes = await _supabase
              .from(table)
              .select('id')
              .count(CountOption.exact);
          final total = countRes.count;

          if (total == 0) {
            print('⚠️ [DailyFact] Bảng $table trống, bỏ qua...');
            continue;
          }

          // Random 1 dòng dựa trên seed ngày
          final offset = random.nextInt(total);
          final rows = await _supabase
              .from(table)
              .select(_selectCols)
              .range(offset, offset);

          if (rows.isNotEmpty) {
            animal = rows.first;
            sourceTable = table;
            print('✅ [DailyFact] Lấy từ bảng "$table" offset=$offset: ${animal['name_vietnamese']}');
            break;
          }
        } catch (e) {
          print('⚠️ [DailyFact] Bảng $table lỗi: $e');
          continue;
        }
      }

      if (animal == null) {
        throw Exception('Không lấy được dữ liệu từ bất kỳ bảng nào. Hãy kiểm tra Supabase.');
      }

      // ══════════════════════════════════════════
      // BƯỚC 3: Build description + facts
      // ══════════════════════════════════════════
      String description = _buildDescription(animal);
      List<String> facts = _buildFacts(animal);

      // Nếu thiếu description hoặc fun_fact → gọi AI generate
      final hasDescription = description.isNotEmpty;
      final hasFunFact = (animal['fun_fact_vietnamese'] as String?)?.isNotEmpty == true ||
          (animal['fun_fact_english'] as String?)?.isNotEmpty == true;

      if (!hasDescription || !hasFunFact) {
        print('🤖 [DailyFact] Thiếu nội dung, gọi AI generate...');
        final aiContent = await _generateAIContent(animal);

        if (!hasDescription && aiContent['description']!.isNotEmpty) {
          description = aiContent['description']!;
        }

        if (!hasFunFact && aiContent['fun_fact']!.isNotEmpty) {
          // Thêm fun fact từ AI vào đầu facts (sau các stats)
          facts.add('✨ ${aiContent['fun_fact']}');
        }
      }

      // ══════════════════════════════════════════
      // BƯỚC 4: Xử lý ảnh
      // Thứ tự: DB image_url → image_urls[0] → Wikipedia
      // ══════════════════════════════════════════
      String? finalImageUrl = animal['image_url'] as String?;

      if (finalImageUrl == null || finalImageUrl.isEmpty) {
        final imageUrls = animal['image_urls'];
        if (imageUrls is List && imageUrls.isNotEmpty) {
          finalImageUrl = imageUrls.first as String?;
        }
      }

      if (finalImageUrl == null || finalImageUrl.isEmpty) {
        print('📷 [DailyFact] Không có ảnh trong DB, thử Wikipedia...');
        final nameEn = animal['name_english'] as String? ?? '';
        finalImageUrl = await _fetchWikiImage(nameEn);
      }

      finalImageUrl ??= 'https://upload.wikimedia.org/wikipedia/commons/7/73/Lion_waiting_in_Namibia.jpg';

      // ══════════════════════════════════════════
      // BƯỚC 5: Check shared image cache
      // ══════════════════════════════════════════
      final sharedImageUrl = await SharedImageCacheService.getSharedCachedImage(finalImageUrl);
      if (sharedImageUrl != null) {
        print('🌐 [DailyFact] Dùng shared image cache: $sharedImageUrl');
        finalImageUrl = sharedImageUrl;
      }

      // ══════════════════════════════════════════
      // BƯỚC 6: Build AnimalFact object
      // ══════════════════════════════════════════
      final regions = (animal['geographic_regions'] as List?)
          ?.map((e) => _mapRegion(e.toString()))
          .toList() ?? [];

      final locationText = regions.isNotEmpty ? regions.take(2).join(', ') : null;

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
      // BƯỚC 7: Lưu cache
      // ══════════════════════════════════════════
      await DailyFactCache.saveCache(finalFact);
      print('💾 [DailyFact] Đã lưu cache (nguồn: $sourceTable)');

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

  AnimalFact _getFallbackData() {
    return AnimalFact(
      name: 'Sư tử',
      englishName: 'Lion',
      scientificName: 'Panthera leo',
      description: 'Vua của các loài thú, phân bố tại thảo nguyên Châu Phi.',
      facts: [
        '⚖️ Cân nặng: ~190 kg',
        '💨 Tốc độ tối đa: 80 km/h',
        '⏳ Tuổi thọ: ~12 năm',
        '🍽️ Chế độ ăn: Ăn thịt',
        '🌍 Môi trường: Thảo nguyên',
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
          // ── ẢNH NỀN ──
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
                                padding: EdgeInsets.only(top: 1),
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