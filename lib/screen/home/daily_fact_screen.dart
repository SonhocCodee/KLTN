import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_env.dart';
import '../Animal_detail/Animal detail screen.dart';
import '../language/Locale_provider.dart';
import 'animal_category_model.dart';

// ════════════════════════════════════════════════════════
// MODEL
// ════════════════════════════════════════════════════════
class _DailyAnimal {
  final String id;
  final String animalType;
  final String nameVi;
  final String nameEn;
  final String scientificName;
  final String descriptionVi; // description_short (VI)
  final String descriptionEn; // description_english (EN) — có thể rỗng
  final List<String> factsVi; // facts tiếng Việt
  final List<String> factsEn; // facts tiếng Anh
  final String funFactVi;
  final String funFactEn;
  final String imageUrl;

  /// Ảnh đã lưu local dạng base64 để khi mất mạng vẫn hiển thị được ảnh fact.
  final String imageBytesBase64;

  const _DailyAnimal({
    required this.id,
    required this.animalType,
    required this.nameVi,
    required this.nameEn,
    required this.scientificName,
    required this.descriptionVi,
    required this.descriptionEn,
    required this.factsVi,
    required this.factsEn,
    required this.funFactVi,
    required this.funFactEn,
    required this.imageUrl,
    this.imageBytesBase64 = '',
  });

  _DailyAnimal copyWith({
    String? imageUrl,
    String? imageBytesBase64,
  }) {
    return _DailyAnimal(
      id: id,
      animalType: animalType,
      nameVi: nameVi,
      nameEn: nameEn,
      scientificName: scientificName,
      descriptionVi: descriptionVi,
      descriptionEn: descriptionEn,
      factsVi: factsVi,
      factsEn: factsEn,
      funFactVi: funFactVi,
      funFactEn: funFactEn,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBytesBase64: imageBytesBase64 ?? this.imageBytesBase64,
    );
  }
}

// ════════════════════════════════════════════════════════
// SCREEN
// ════════════════════════════════════════════════════════
class DailyFactScreen extends StatefulWidget {
  const DailyFactScreen({super.key});

  @override
  State<DailyFactScreen> createState() => _DailyFactScreenState();
}

class _DailyFactScreenState extends State<DailyFactScreen>
    with SingleTickerProviderStateMixin {
  static const _clipDropKey = AppEnv.clipDropApiKey;
  static const _imageCacheTable = 'daily_fact_image_cache';

  // Đổi version để app bỏ cache ảnh cũ đã crop hỏng.
  static const _imageProcessVersion = 'center_uncrop_v3';

  // v7: thêm animal_type + ảnh local base64.
  static const _factCacheKey = 'daily_fact_v7';
  static const _factDateKey = 'daily_fact_date_v7';
  static const _imageBytesPrefix = 'daily_fact_image_bytes_v7_';

  // Tránh nhồi ảnh quá lớn vào SharedPreferences.
  // Nếu ảnh quá lớn thì app vẫn dùng URL khi có mạng, còn offline có thể không có ảnh.
  static const int _maxLocalImageBytes = 2500000;

  _DailyAnimal? _animal;
  bool _isLoading = true;
  bool _isExtending = false;
  bool _isUsingOfflineCache = false;
  bool _showFullDescription = false;
  String? _error;

  late AnimationController _anim;
  late Animation<double> _fadeAnim;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _anim, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load(context.read<LocaleProvider>());
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════
  // LOAD
  // ════════════════════════════════════════════════════════
  Future<void> _load(LocaleProvider t) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _isUsingOfflineCache = false;
      _showFullDescription = false;
    });

    final today = _todayStr();

    try {
      // 1. Nếu hôm nay đã có cache thì hiện ngay, không cần mạng.
      final local = await _readLocalCache(today);
      if (local != null) {
        _show(local);
        return;
      }

      // 2. Không có cache hôm nay thì gọi Supabase.
      final row = await _randomAnimal(today);
      if (row == null) {
        throw Exception(t.tr('Không lấy được dữ liệu từ Supabase'));
      }

      final origUrl = (row['image_url'] as String?) ?? '';
      final imageUrl = await _resolveImage(today, row['id'].toString(), origUrl);
      final imageBytesBase64 = await _cacheImageBytesForOffline(
        today: today,
        animalId: row['id'].toString(),
        imageUrl: imageUrl,
      );

      final animal = _buildAnimal(row, imageUrl, t).copyWith(
        imageBytesBase64: imageBytesBase64,
      );

      await _saveLocalCache(today, animal);
      _show(animal);
    } catch (e) {
      debugPrint('❌ [DailyFact] $e');

      // 3. Mất mạng sang ngày mới: dùng fact gần nhất đã lưu thay vì trắng màn.
      final stale = await _readLocalCache(today, allowStale: true);
      if (stale != null) {
        _show(stale, offlineCache: true);
        return;
      }

      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _show(_DailyAnimal animal, {bool offlineCache = false}) {
    if (!mounted) return;
    setState(() {
      _animal = animal;
      _isLoading = false;
      _isUsingOfflineCache = offlineCache;
      _showFullDescription = false;
    });
    _anim.forward(from: 0);
  }

  // ════════════════════════════════════════════════════════
  // RANDOM ANIMAL
  // ════════════════════════════════════════════════════════
  Future<Map<String, dynamic>?> _randomAnimal(String today) async {
    final seed = today.replaceAll('-', '').hashCode;
    final rng = Random(seed);

    final countRes = await _db
        .from('animals')
        .select('id')
        .count(CountOption.exact)
        .timeout(const Duration(seconds: 5));

    final total = countRes.count;
    if (total == 0) return null;

    final offset = rng.nextInt(total);
    final rows = await _db
        .from('animals')
        .select(
          'id, animal_type, name_vietnamese, name_english, scientific_name, '
          'description_short, description_english, '
          'fun_fact_vietnamese, fun_fact_english, image_url, '
          'weight_avg_kg, height_avg_m, length_avg_m, '
          'max_speed_kmh, lifespan_avg_years, '
          'diet_type, primary_habitat, conservation_status',
        )
        .range(offset, offset)
        .timeout(const Duration(seconds: 5));

    return rows.isNotEmpty ? rows.first : null;
  }

  // ════════════════════════════════════════════════════════
  // ẢNH
  // ════════════════════════════════════════════════════════
  Future<String> _resolveImage(
    String today,
    String animalId,
    String origUrl,
  ) async {
    if (origUrl.isEmpty) return origUrl;

    try {
      final row = await _db
          .from(_imageCacheTable)
          .select('extended_url')
          .eq('cache_date', today)
          .eq('animal_id', animalId)
          .maybeSingle()
          .timeout(const Duration(seconds: 4));

      if (row != null) {
        final cachedUrl = (row['extended_url'] as String?) ?? '';

        // Nếu cache cũ chưa phải bản center/uncrop mới thì bỏ qua và xử lý lại.
        if (cachedUrl.contains(_imageProcessVersion)) {
          debugPrint('✅ [ImgCache] Supabase hit $_imageProcessVersion');
          return cachedUrl;
        }

        debugPrint('♻️ [ImgCache] Cache cũ, tạo lại ảnh $_imageProcessVersion');
      }
    } catch (e) {
      debugPrint('⚠️ [ImgCache] Không đọc được Supabase image cache: $e');
    }

    if (mounted) setState(() => _isExtending = true);
    final extended = await _callClipDrop(origUrl);
    if (mounted) setState(() => _isExtending = false);

    if (extended != null) {
      final publicUrl = await _uploadAndCache(today, animalId, extended);
      return publicUrl ?? origUrl;
    }

    return origUrl;
  }

  Future<Uint8List?> _callClipDrop(String imageUrl) async {
    if (!AppEnv.hasClipDrop) {
      debugPrint('⚠️ Thiếu CLIPDROP_API_KEY, dùng ảnh gốc');
      return null;
    }

    try {
      debugPrint('📥 [ClipDrop] Downloading: $imageUrl');

      final imgRes = await http
          .get(Uri.parse(imageUrl))
          .timeout(const Duration(seconds: 6));

      if (imgRes.statusCode != 200 || imgRes.bodyBytes.isEmpty) {
        debugPrint('❌ [ClipDrop] Download failed: ${imgRes.statusCode}');
        return null;
      }

      final req = http.MultipartRequest(
        'POST',
        Uri.parse('https://clipdrop-api.co/uncrop/v1'),
      )
        ..headers['x-api-key'] = _clipDropKey
        ..files.add(
          http.MultipartFile.fromBytes(
            'image_file',
            imgRes.bodyBytes,
            filename: 'animal.jpg',
          ),
        );

      // Mục tiêu: biến ảnh ngang/lệch thành nền dọc dễ dùng cho màn hình điện thoại.
      req.fields['extend_up'] = '900';
      req.fields['extend_down'] = '900';
      req.fields['extend_left'] = '550';
      req.fields['extend_right'] = '550';

      final streamed = await req.send().timeout(const Duration(seconds: 12));
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        debugPrint('✅ [ClipDrop] Uncrop thành công');
        return res.bodyBytes;
      }

      debugPrint('❌ [ClipDrop] ${res.statusCode}: ${res.body}');
    } catch (e) {
      debugPrint('❌ [ClipDrop] $e');
    }
    return null;
  }

  Future<String?> _uploadAndCache(
    String today,
    String animalId,
    Uint8List bytes,
  ) async {
    try {
      final path = 'daily/$today/${animalId}_$_imageProcessVersion.png';

      await _db.storage
          .from('animal-images')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: true,
            ),
          )
          .timeout(const Duration(seconds: 12));

      final url = _db.storage.from('animal-images').getPublicUrl(path);

      await _db
          .from(_imageCacheTable)
          .upsert({
            'cache_date': today,
            'animal_id': animalId,
            'extended_url': url,
            'created_at': DateTime.now().toIso8601String(),
          }, onConflict: 'cache_date,animal_id')
          .timeout(const Duration(seconds: 6));

      debugPrint('☁️ [ImgCache] Uploaded: $url');
      return url;
    } catch (e) {
      debugPrint('❌ [ImgCache] Upload thất bại: $e');
      return null;
    }
  }

  /// Lưu ảnh thật xuống SharedPreferences dạng base64 để offline vẫn xem được.
  Future<String> _cacheImageBytesForOffline({
    required String today,
    required String animalId,
    required String imageUrl,
  }) async {
    if (imageUrl.isEmpty) return '';

    final key = '$_imageBytesPrefix${today}_$animalId';

    try {
      final prefs = await SharedPreferences.getInstance();
      final old = prefs.getString(key);
      if (old != null && old.isNotEmpty) return old;

      final res = await http
          .get(Uri.parse(imageUrl))
          .timeout(const Duration(seconds: 8));

      if (res.statusCode != 200 || res.bodyBytes.isEmpty) return '';

      if (res.bodyBytes.length > _maxLocalImageBytes) {
        debugPrint(
          '⚠️ [LocalImgCache] Ảnh quá lớn ${res.bodyBytes.length} bytes, bỏ qua cache local',
        );
        return '';
      }

      final b64 = base64Encode(res.bodyBytes);
      await prefs.setString(key, b64);
      debugPrint('✅ [LocalImgCache] Đã lưu ảnh offline: ${res.bodyBytes.length} bytes');
      return b64;
    } catch (e) {
      debugPrint('⚠️ [LocalImgCache] Không cache được ảnh: $e');
      return '';
    }
  }

  // ════════════════════════════════════════════════════════
  // BUILD MODEL — tách facts VI / EN riêng
  // ════════════════════════════════════════════════════════
  _DailyAnimal _buildAnimal(
    Map<String, dynamic> a,
    String imageUrl,
    LocaleProvider t,
  ) {
    // ── Facts tiếng Việt ──
    final factsVi = <String>[];
    final w = a['weight_avg_kg'];
    final l = a['length_avg_m'];
    final h = a['height_avg_m'];
    final s = a['max_speed_kmh'];
    final ls = a['lifespan_avg_years'];

    if (w != null) factsVi.add('⚖️ Cân nặng: ${_fmt(w)} kg');
    if (l != null) {
      factsVi.add('📏 Dài: ${_fmtLen(l)}');
    } else if (h != null) {
      factsVi.add('📐 Cao: ${_fmtLen(h)}');
    }
    if (s != null) factsVi.add('💨 Tốc độ: ${_fmt(s)} km/h');
    if (ls != null) factsVi.add('⏳ Tuổi thọ: ~${_fmt(ls)} năm');

    final dietVi = _mapDiet(a['diet_type'] as String?, false);
    if (dietVi != null) factsVi.add('🍽️ $dietVi');
    final consVi = _mapConservation(a['conservation_status'] as String?, false);
    if (consVi != null) factsVi.add(consVi);

    // ── Facts tiếng Anh ──
    final factsEn = <String>[];
    if (w != null) factsEn.add('⚖️ Weight: ${_fmt(w)} kg');
    if (l != null) {
      factsEn.add('📏 Length: ${_fmtLen(l)}');
    } else if (h != null) {
      factsEn.add('📐 Height: ${_fmtLen(h)}');
    }
    if (s != null) factsEn.add('💨 Speed: ${_fmt(s)} km/h');
    if (ls != null) factsEn.add('⏳ Lifespan: ~${_fmt(ls)} years');

    final dietEn = _mapDiet(a['diet_type'] as String?, true);
    if (dietEn != null) factsEn.add('🍽️ $dietEn');
    final consEn = _mapConservation(a['conservation_status'] as String?, true);
    if (consEn != null) factsEn.add(consEn);

    return _DailyAnimal(
      id: a['id'].toString(),
      animalType: (a['animal_type'] as String? ?? '').trim(),
      nameVi: a['name_vietnamese'] as String? ?? '',
      nameEn: a['name_english'] as String? ?? '',
      scientificName: a['scientific_name'] as String? ?? '',
      descriptionVi: (a['description_short'] as String? ?? '').trim(),
      descriptionEn: (a['description_english'] as String? ?? '').trim(),
      factsVi: factsVi,
      factsEn: factsEn,
      funFactVi: (a['fun_fact_vietnamese'] as String? ?? '').trim(),
      funFactEn: (a['fun_fact_english'] as String? ?? '').trim(),
      imageUrl: imageUrl,
    );
  }

  // ════════════════════════════════════════════════════════
  // LOCAL CACHE
  // ════════════════════════════════════════════════════════
  Future<_DailyAnimal?> _readLocalCache(
    String today, {
    bool allowStale = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheDate = prefs.getString(_factDateKey);
      if (!allowStale && cacheDate != today) return null;

      final raw = prefs.getString(_factCacheKey);
      if (raw == null) return null;

      final m = json.decode(raw) as Map<String, dynamic>;
      final id = m['id'] as String;
      final storedImageB64 = m['imageBytesBase64'] as String? ?? '';

      // Trường hợp cache fact có nhưng ảnh lưu ở key riêng thì lấy lại.
      String imageB64 = storedImageB64;
      if (imageB64.isEmpty && cacheDate != null) {
        imageB64 = prefs.getString('$_imageBytesPrefix${cacheDate}_$id') ?? '';
      }

      return _DailyAnimal(
        id: id,
        animalType: m['animalType'] as String? ?? '',
        nameVi: m['nameVi'] as String? ?? '',
        nameEn: m['nameEn'] as String? ?? '',
        scientificName: m['scientificName'] as String? ?? '',
        descriptionVi: m['descriptionVi'] as String? ?? '',
        descriptionEn: m['descriptionEn'] as String? ?? '',
        factsVi: List<String>.from(m['factsVi'] as List? ?? []),
        factsEn: List<String>.from(m['factsEn'] as List? ?? []),
        funFactVi: m['funFactVi'] as String? ?? '',
        funFactEn: m['funFactEn'] as String? ?? '',
        imageUrl: m['imageUrl'] as String? ?? '',
        imageBytesBase64: imageB64,
      );
    } catch (e) {
      debugPrint('⚠️ [DailyFact] Read local cache lỗi: $e');
      return null;
    }
  }

  Future<void> _saveLocalCache(String today, _DailyAnimal a) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_factDateKey, today);
      await prefs.setString(
        _factCacheKey,
        json.encode({
          'id': a.id,
          'animalType': a.animalType,
          'nameVi': a.nameVi,
          'nameEn': a.nameEn,
          'scientificName': a.scientificName,
          'descriptionVi': a.descriptionVi,
          'descriptionEn': a.descriptionEn,
          'factsVi': a.factsVi,
          'factsEn': a.factsEn,
          'funFactVi': a.funFactVi,
          'funFactEn': a.funFactEn,
          'imageUrl': a.imageUrl,
          'imageBytesBase64': a.imageBytesBase64,
        }),
      );
    } catch (e) {
      debugPrint('⚠️ [DailyFact] Save local cache lỗi: $e');
    }
  }

  // ════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════
  static String _todayStr() => DateTime.now().toIso8601String().split('T')[0];

  String _fmt(dynamic v) {
    if (v == null) return '?';
    final d = (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0;
    return d == d.roundToDouble() ? d.round().toString() : d.toStringAsFixed(1);
  }

  String _fmtLen(dynamic v) {
    final m = (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0;
    final cm = (m * 100).round();
    return cm > 200 ? '${m.toStringAsFixed(1)} m' : '$cm cm';
  }

  // isEnglish=true → trả tiếng Anh, false → tiếng Việt
  String? _mapDiet(String? d, bool isEnglish) {
    if (d == null) return null;
    const vi = {
      'carnivore': 'Ăn thịt',
      'herbivore': 'Ăn thực vật',
      'omnivore': 'Ăn tạp',
      'insectivore': 'Ăn côn trùng',
      'piscivore': 'Ăn cá',
      'frugivore': 'Ăn trái cây',
    };
    const en = {
      'carnivore': 'Carnivore',
      'herbivore': 'Herbivore',
      'omnivore': 'Omnivore',
      'insectivore': 'Insectivore',
      'piscivore': 'Piscivore',
      'frugivore': 'Frugivore',
    };
    return isEnglish ? en[d] : vi[d];
  }

  String? _mapConservation(String? c, bool isEnglish) {
    if (c == null) return null;
    final cl = c.toLowerCase();
    if (isEnglish) {
      if (cl.contains('least concern')) return '🟢 Least Concern';
      if (cl.contains('near threatened')) return '🔵 Near Threatened';
      if (cl.contains('vulnerable')) return '🟡 Vulnerable';
      if (cl.contains('critically endangered')) {
        return '🔴 Critically Endangered';
      }
      if (cl.contains('endangered')) return '🟠 Endangered';
      if (cl.contains('extinct in the wild')) return '⚫ Extinct in the Wild';
    } else {
      if (cl.contains('least concern')) return '🟢 Ít lo ngại';
      if (cl.contains('near threatened')) return '🔵 Sắp bị đe dọa';
      if (cl.contains('vulnerable')) return '🟡 Dễ bị tổn thương';
      if (cl.contains('critically endangered')) return '🔴 Cực kỳ nguy cấp';
      if (cl.contains('endangered')) return '🟠 Nguy cấp';
      if (cl.contains('extinct in the wild')) return '⚫ Tuyệt chủng ngoài TN';
    }
    return null;
  }

  AnimalCategory? _categoryForAnimal(_DailyAnimal a) {
    if (a.animalType.isEmpty) return null;

    for (final c in AnimalCategory.allCategories) {
      if (c.id == a.animalType) return c;
    }

    return null;
  }

  void _openAnimalDetail(_DailyAnimal a) {
    final category = _categoryForAnimal(a);
    if (category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<LocaleProvider>().tr('Không tìm thấy danh mục loài'))),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnimalDetailScreen(
          animalId: a.id,
          category: category,
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // UI
  // ════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleProvider>();

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                t.tr('Đang tải thông tin loài vật...'),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_animal == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  t.tr(_error ?? 'Có lỗi xảy ra'),
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _load(t),
                  icon: const Icon(Icons.refresh),
                  label: Text(t.tr('Thử lại')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final a = _animal!;
    final isEn = t.isEnglish;

    // ── Chọn nội dung theo ngôn ngữ ──────────────────────
    final displayName = isEn ? (a.nameEn.isNotEmpty ? a.nameEn : a.nameVi) : a.nameVi;
    final subName = isEn ? a.nameVi : a.nameEn; // dòng phụ nhỏ

    final description = isEn
        ? (a.descriptionEn.isNotEmpty ? a.descriptionEn : a.descriptionVi)
        : a.descriptionVi;

    final facts = isEn ? a.factsEn : a.factsVi;

    final funFact = isEn
        ? (a.funFactEn.isNotEmpty ? a.funFactEn : a.funFactVi)
        : a.funFactVi;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── ẢNH NỀN — ưu tiên ảnh local base64 khi có ─────────────
          _buildBackground(
            a.imageUrl,
            imageBytesBase64: a.imageBytesBase64,
          ),

          // ── GRADIENT ─────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x8D000000),
                  Color(0x00000000),
                  Color(0xE6000000),
                ],
                stops: [0.0, 0.35, 1.0],
              ),
            ),
          ),

          // ── NỘI DUNG ─────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.tr('KIẾN THỨC THÚ VỊ'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.5,
                            shadows: [
                              Shadow(blurRadius: 6, color: Colors.black54),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEn
                              ? '${_monthEn(DateTime.now().month)} ${DateTime.now().day}, ${DateTime.now().year}'
                              : '${t.tr('Ngày')} ${DateTime.now().day} ${t.tr('tháng')} ${DateTime.now().month} ${t.tr('năm')} ${DateTime.now().year}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badge "đang xử lý ảnh"
                  if (_isExtending)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: _buildStatusBadge(
                        icon: const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            color: Colors.white60,
                            strokeWidth: 2,
                          ),
                        ),
                        text: t.tr('Đang xử lý ảnh...'),
                      ),
                    ),

                  if (_isUsingOfflineCache)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: _buildStatusBadge(
                        icon: const Icon(
                          Icons.offline_bolt_rounded,
                          color: Colors.orangeAccent,
                          size: 15,
                        ),
                        text: t.tr('Đang dùng dữ liệu đã lưu'),
                      ),
                    ),

                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tên chính
                            Text(
                              displayName,
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
                            if (a.scientificName.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                a.scientificName,
                                style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],

                            // Tên phụ (ngôn ngữ còn lại)
                            if (subName.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                subName,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 13,
                                ),
                              ),
                            ],

                            // Mô tả — luôn hiển thị đầy đủ, không còn dấu "...".
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Text(
                                description,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.92),
                                  fontSize: 14,
                                  height: 1.55,
                                ),
                              ),
                            ],

                            // Facts
                            const SizedBox(height: 16),
                            ...facts.take(4).map(
                              (fact) => Padding(
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
                              ),
                            ),

                            // Fun fact
                            if (funFact.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 1),
                                    child: Icon(
                                      Icons.lightbulb_outline,
                                      size: 13,
                                      color: Colors.yellowAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      funFact,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                        height: 1.4,
                                      ),

                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => _openAnimalDetail(a),
                                icon: const Icon(Icons.pets_rounded),
                                label: Text(t.tr('Xem chi tiết loài')),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                            ),

                            // Hint swipe
                            const SizedBox(height: 18),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.25),
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
                                    Text(
                                      t.tr('Trượt lên để khám phá'),
                                      style: const TextStyle(
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge({required Widget icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Ảnh nền: ưu tiên ảnh local khi có, fallback sang network URL ─────
  Widget _buildBackground(String url, {String imageBytesBase64 = ''}) {
    if (imageBytesBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(imageBytesBase64);
        if (bytes.isNotEmpty) {
          return SizedBox.expand(
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => _fallbackBackground(),
            ),
          );
        }
      } catch (e) {
        debugPrint('⚠️ [LocalImgCache] Decode ảnh lỗi: $e');
      }
    }

    if (url.isEmpty) return _fallbackBackground();

    return SizedBox.expand(
      child: Image.network(
        url,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _fallbackBackground(),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            color: const Color(0xFF0F172A),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white30),
            ),
          );
        },
      ),
    );
  }

  Widget _fallbackBackground() {
    return Container(color: const Color(0xFF0F172A));
  }

  String _monthEn(int month) => const [
        '',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ][month];
}
