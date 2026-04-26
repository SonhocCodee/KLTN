import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ════════════════════════════════════════════════════════
// MODEL
// ════════════════════════════════════════════════════════
class _DailyAnimal {
  final String id;
  final String nameVi;
  final String nameEn;
  final String scientificName;
  final String description;
  final List<String> facts;
  final String imageUrl; // URL ảnh đã extend (từ cache) hoặc ảnh gốc

  const _DailyAnimal({
    required this.id,
    required this.nameVi,
    required this.nameEn,
    required this.scientificName,
    required this.description,
    required this.facts,
    required this.imageUrl,
  });
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

  // ── Config ────────────────────────────────────────────
  static const _clipDropKey =
      '3b8eb2533aa22dceadae396085872396d2346fd038f39b50003f9741f58063d3e04777284a68dad84aacbaaf3454b45e';
  static const _imageCacheTable = 'daily_fact_image_cache';
  static const _factCacheKey    = 'daily_fact_v4';
  static const _factDateKey     = 'daily_fact_date_v4';

  // ── State ─────────────────────────────────────────────
  _DailyAnimal? _animal;
  bool  _isLoading   = true;
  bool  _isExtending = false; // đang gọi ClipDrop
  String? _error;

  late AnimationController _anim;
  late Animation<double>   _fadeAnim;

  SupabaseClient get _db => Supabase.instance.client;

  // ── Lifecycle ─────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════
  // BƯỚC 1 — LOAD
  // ════════════════════════════════════════════════════════
  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final today = _todayStr();

      // ── A. Đọc local cache ──────────────────────────────
      final local = await _readLocalCache(today);
      if (local != null) {
        _show(local);
        return;
      }

      // ── B. Random animal từ Supabase ────────────────────
      final row = await _randomAnimal(today);
      if (row == null) throw Exception('Không lấy được dữ liệu từ Supabase');

      // ── C. Lấy ảnh (cache Supabase trước, nếu không có thì ClipDrop) ──
      final origUrl  = (row['image_url'] as String?) ?? '';
      final imageUrl = await _resolveImage(today, row['id'].toString(), origUrl);

      // ── D. Build model ──────────────────────────────────
      final animal = _buildAnimal(row, imageUrl);

      // ── E. Lưu local cache ──────────────────────────────
      await _saveLocalCache(today, animal);

      _show(animal);
    } catch (e) {
      debugPrint('❌ [DailyFact] $e');
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _show(_DailyAnimal animal) {
    if (!mounted) return;
    setState(() { _animal = animal; _isLoading = false; });
    _anim.forward(from: 0);
  }

  // ════════════════════════════════════════════════════════
  // RANDOM ANIMAL — seed theo ngày, nhất quán trong ngày
  // ════════════════════════════════════════════════════════
  Future<Map<String, dynamic>?> _randomAnimal(String today) async {
    // Seed từ ngày → cùng ngày luôn ra cùng con
    final seed = today.replaceAll('-', '').hashCode;
    final rng  = Random(seed);

    // Đếm tổng
    final countRes = await _db
        .from('animals')
        .select('id')
        .count(CountOption.exact);
    final total = countRes.count;
    if (total == 0) return null;

    final offset = rng.nextInt(total);
    final rows = await _db
        .from('animals')
        .select(
      'id, name_vietnamese, name_english, scientific_name, '
          'description_short, fun_fact_vietnamese, image_url, '
          'weight_avg_kg, height_avg_m, length_avg_m, '
          'max_speed_kmh, lifespan_avg_years, '
          'diet_type, primary_habitat, conservation_status',
    )
        .range(offset, offset);

    return rows.isNotEmpty ? rows.first : null;
  }

  // ════════════════════════════════════════════════════════
  // ẢNH — 3 bước: Supabase cache → ClipDrop → ảnh gốc
  // ════════════════════════════════════════════════════════
  Future<String> _resolveImage(
      String today, String animalId, String origUrl) async {

    if (origUrl.isEmpty) return origUrl;

    // 1. Check Supabase image cache
    try {
      final row = await _db
          .from(_imageCacheTable)
          .select('extended_url')
          .eq('cache_date', today)
          .eq('animal_id', animalId)
          .maybeSingle();
      if (row != null) {
        debugPrint('✅ [ImgCache] Supabase hit');
        return row['extended_url'] as String;
      }
    } catch (e) {
      debugPrint('⚠️ [ImgCache] $e');
    }

    // 2. Gọi ClipDrop
    if (mounted) setState(() => _isExtending = true);
    final extended = await _callClipDrop(origUrl);
    if (mounted) setState(() => _isExtending = false);

    if (extended != null) {
      // Upload lên Supabase Storage + lưu cache row
      final publicUrl = await _uploadAndCache(today, animalId, extended);
      return publicUrl ?? origUrl;
    }

    // 3. Fallback ảnh gốc
    return origUrl;
  }

  // ── ClipDrop Uncrop ────────────────────────────────────
  Future<Uint8List?> _callClipDrop(String imageUrl) async {
    try {
      debugPrint('📥 [ClipDrop] Downloading: $imageUrl');
      final imgRes = await http.get(Uri.parse(imageUrl));
      if (imgRes.statusCode != 200) return null;

      final req = http.MultipartRequest(
        'POST',
        Uri.parse('https://clipdrop-api.co/uncrop/v1'),
      )
        ..headers['x-api-key'] = _clipDropKey
        ..files.add(http.MultipartFile.fromBytes(
          'image_file', imgRes.bodyBytes,
          filename: 'animal.jpg',
        ))
        ..fields['extend_up']    = '500'
        ..fields['extend_down']  = '500'
        ..fields['extend_left']  = '0'
        ..fields['extend_right'] = '0';

      final res = await http.Response.fromStream(await req.send());
      if (res.statusCode == 200) {
        debugPrint('✅ [ClipDrop] Thành công');
        return res.bodyBytes;
      }
      debugPrint('❌ [ClipDrop] ${res.statusCode}: ${res.body}');
    } catch (e) {
      debugPrint('❌ [ClipDrop] $e');
    }
    return null;
  }

  // ── Upload Supabase Storage + lưu cache row ────────────
  Future<String?> _uploadAndCache(
      String today, String animalId, Uint8List bytes) async {
    try {
      final path = 'daily/$today/$animalId.png';
      await _db.storage.from('animal-images').uploadBinary(
        path, bytes,
        fileOptions: const FileOptions(contentType: 'image/png', upsert: true),
      );
      final url = _db.storage.from('animal-images').getPublicUrl(path);

      await _db.from(_imageCacheTable).upsert({
        'cache_date':    today,
        'animal_id':     animalId,
        'extended_url':  url,
        'created_at':    DateTime.now().toIso8601String(),
      }, onConflict: 'cache_date,animal_id');

      debugPrint('☁️ [ImgCache] Uploaded: $url');
      return url;
    } catch (e) {
      debugPrint('❌ [ImgCache] Upload thất bại: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════
  // BUILD MODEL TỪ ROW DB
  // ════════════════════════════════════════════════════════
  _DailyAnimal _buildAnimal(Map<String, dynamic> a, String imageUrl) {
    // Mô tả
    final desc = (a['description_short'] as String? ?? '').trim();

    // Facts từ các cột số
    final facts = <String>[];
    final w = a['weight_avg_kg'];
    final l = a['length_avg_m'];
    final h = a['height_avg_m'];
    final s = a['max_speed_kmh'];
    final ls = a['lifespan_avg_years'];

    if (w  != null) facts.add('⚖️ Cân nặng: ${_fmt(w)} kg');
    if (l  != null) facts.add('📏 Dài: ${_fmtLen(l)}');
    else if (h != null) facts.add('📐 Cao: ${_fmtLen(h)}');
    if (s  != null) facts.add('💨 Tốc độ: ${_fmt(s)} km/h');
    if (ls != null) facts.add('⏳ Tuổi thọ: ~${_fmt(ls)} năm');

    final diet = _mapDiet(a['diet_type'] as String?);
    if (diet != null) facts.add('🍽️ $diet');

    final cons = _mapConservation(a['conservation_status'] as String?);
    if (cons != null) facts.add(cons);

    final funFact = (a['fun_fact_vietnamese'] as String? ?? '').trim();
    if (funFact.isNotEmpty) facts.add('✨ $funFact');

    return _DailyAnimal(
      id:             a['id'].toString(),
      nameVi:         a['name_vietnamese'] as String? ?? 'Động vật',
      nameEn:         a['name_english']    as String? ?? '',
      scientificName: a['scientific_name'] as String? ?? '',
      description:    desc,
      facts:          facts,
      imageUrl:       imageUrl,
    );
  }

  // ════════════════════════════════════════════════════════
  // LOCAL CACHE (SharedPreferences)
  // ════════════════════════════════════════════════════════
  Future<_DailyAnimal?> _readLocalCache(String today) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_factDateKey) != today) return null;
      final raw = prefs.getString(_factCacheKey);
      if (raw == null) return null;
      final m = json.decode(raw) as Map<String, dynamic>;
      return _DailyAnimal(
        id:             m['id']             as String,
        nameVi:         m['nameVi']         as String,
        nameEn:         m['nameEn']         as String,
        scientificName: m['scientificName'] as String,
        description:    m['description']    as String,
        facts:          List<String>.from(m['facts'] as List),
        imageUrl:       m['imageUrl']       as String,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveLocalCache(String today, _DailyAnimal a) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_factDateKey, today);
      await prefs.setString(_factCacheKey, json.encode({
        'id':             a.id,
        'nameVi':         a.nameVi,
        'nameEn':         a.nameEn,
        'scientificName': a.scientificName,
        'description':    a.description,
        'facts':          a.facts,
        'imageUrl':       a.imageUrl,
      }));
    } catch (_) {}
  }

  // ════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════
  static String _todayStr() =>
      DateTime.now().toIso8601String().split('T')[0];

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

  String? _mapDiet(String? d) => const {
    'carnivore':   'Ăn thịt',
    'herbivore':   'Ăn thực vật',
    'omnivore':    'Ăn tạp',
    'insectivore': 'Ăn côn trùng',
    'piscivore':   'Ăn cá',
    'frugivore':   'Ăn trái cây',
  }[d];

  String? _mapConservation(String? c) {
    if (c == null) return null;
    final cl = c.toLowerCase();
    if (cl.contains('least concern'))         return '🟢 Ít lo ngại';
    if (cl.contains('near threatened'))       return '🔵 Sắp bị đe dọa';
    if (cl.contains('vulnerable'))            return '🟡 Dễ bị tổn thương';
    if (cl.contains('endangered') &&
        !cl.contains('critically'))           return '🟠 Nguy cấp';
    if (cl.contains('critically endangered')) return '🔴 Cực kỳ nguy cấp';
    if (cl.contains('extinct in the wild'))   return '⚫ Tuyệt chủng ngoài TN';
    return null;
  }

  // ════════════════════════════════════════════════════════
  // UI
  // ════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    // ── Loading ──
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Đang tải thông tin loài vật...',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    // ── Error ──
    if (_animal == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Có lỗi xảy ra',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final a = _animal!;

    return Scaffold(
      body: Stack(
        children: [
          // ── ẢNH NỀN ──────────────────────────────────────
          Positioned.fill(child: _buildBackground(a.imageUrl)),

          // ── GRADIENT ─────────────────────────────────────
          Positioned.fill(
            child: Container(
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
                          'Ngày ${DateTime.now().day} '
                              'tháng ${DateTime.now().month} '
                              'năm ${DateTime.now().year}',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  // Badge "đang xử lý ảnh"
                  if (_isExtending)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12, height: 12,
                              child: CircularProgressIndicator(
                                  color: Colors.white60, strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Đang xử lý ảnh...',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Thông tin chính
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tên Việt
                        Text(
                          a.nameVi,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            shadows: [Shadow(blurRadius: 12, color: Colors.black87)],
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

                        // Tên tiếng Anh
                        if (a.nameEn.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            a.nameEn,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 13),
                          ),
                        ],

                        // Mô tả
                        if (a.description.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            a.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.92),
                              fontSize: 14,
                              height: 1.55,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        // Facts
                        const SizedBox(height: 16),
                        ...a.facts.take(4).map((fact) => Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 1),
                                child: Icon(Icons.auto_awesome,
                                    size: 12, color: Colors.orange),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(fact,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13.5,
                                        height: 1.4)),
                              ),
                            ],
                          ),
                        )),

                        // Hint swipe
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
                                Text('Trượt lên để khám phá',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
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
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(String url) {
    if (url.isEmpty) {
      return Container(color: const Color(0xFF0F172A));
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          Container(color: const Color(0xFF0F172A)),
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: const Color(0xFF0F172A),
          child: const Center(
              child: CircularProgressIndicator(color: Colors.white30)),
        );
      },
    );
  }
}