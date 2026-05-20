import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import '../language/Locale_provider.dart';

// ════════════════════════════════════════════════════════
// MODEL
// ════════════════════════════════════════════════════════
class _DailyAnimal {
  final String id;
  final String nameVi;
  final String nameEn;
  final String scientificName;
  final String descriptionVi;   // description_short (VI)
  final String descriptionEn;   // description_english (EN) — có thể rỗng
  final List<String> factsVi;   // facts tiếng Việt
  final List<String> factsEn;   // facts tiếng Anh
  final String funFactVi;
  final String funFactEn;
  final String imageUrl;

  const _DailyAnimal({
    required this.id,
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

  static const _clipDropKey =
      '3b8eb2533aa22dceadae396085872396d2346fd038f39b50003f9741f58063d3e04777284a68dad84aacbaaf3454b45e';
  static const _imageCacheTable = 'daily_fact_image_cache';
  // Đổi version để app bỏ cache ảnh cũ đã crop hỏng.
  static const _imageProcessVersion = 'center_uncrop_v3';
  static const _factCacheKey    = 'daily_fact_v6';
  static const _factDateKey     = 'daily_fact_date_v6';

  _DailyAnimal? _animal;
  bool  _isLoading   = true;
  bool  _isExtending = false;
  String? _error;

  late AnimationController _anim;
  late Animation<double>   _fadeAnim;

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
    setState(() { _isLoading = true; _error = null; });

    try {
      final today = _todayStr();

      final local = await _readLocalCache(today);
      if (local != null) { _show(local); return; }

      final row = await _randomAnimal(today);
      if (row == null) throw Exception(t.tr('Không lấy được dữ liệu từ Supabase'));

      final origUrl  = (row['image_url'] as String?) ?? '';
      final imageUrl = await _resolveImage(today, row['id'].toString(), origUrl);

      final animal = _buildAnimal(row, imageUrl, t);
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
  // RANDOM ANIMAL
  // ════════════════════════════════════════════════════════
  Future<Map<String, dynamic>?> _randomAnimal(String today) async {
    final seed = today.replaceAll('-', '').hashCode;
    final rng  = Random(seed);

    final countRes = await _db.from('animals').select('id').count(CountOption.exact);
    final total = countRes.count;
    if (total == 0) return null;

    final offset = rng.nextInt(total);
    final rows = await _db
        .from('animals')
        .select(
      'id, name_vietnamese, name_english, scientific_name, '
          'description_short, description_english, '          // 👈 thêm description_english
          'fun_fact_vietnamese, fun_fact_english, image_url, ' // 👈 thêm fun_fact_english
          'weight_avg_kg, height_avg_m, length_avg_m, '
          'max_speed_kmh, lifespan_avg_years, '
          'diet_type, primary_habitat, conservation_status',
    )
        .range(offset, offset);

    return rows.isNotEmpty ? rows.first : null;
  }

  // ════════════════════════════════════════════════════════
  // ẢNH
  // ════════════════════════════════════════════════════════
  Future<String> _resolveImage(
      String today, String animalId, String origUrl) async {
    if (origUrl.isEmpty) return origUrl;

    try {
      final row = await _db
          .from(_imageCacheTable)
          .select('extended_url')
          .eq('cache_date', today)
          .eq('animal_id', animalId)
          .maybeSingle();
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
      debugPrint('⚠️ [ImgCache] $e');
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
    try {
      debugPrint('📥 [ClipDrop] Downloading: $imageUrl');

      final imgRes = await http.get(Uri.parse(imageUrl));
      if (imgRes.statusCode != 200 || imgRes.bodyBytes.isEmpty) {
        debugPrint('❌ [ClipDrop] Download failed: ${imgRes.statusCode}');
        return null;
      }

      final req = http.MultipartRequest(
        'POST',
        Uri.parse('https://clipdrop-api.co/uncrop/v1'),
      )
        ..headers['x-api-key'] = _clipDropKey
        ..files.add(http.MultipartFile.fromBytes(
          'image_file',
          imgRes.bodyBytes,
          filename: 'animal.jpg',
        ));

      // Mục tiêu: biến ảnh ngang/lệch thành nền dọc dễ dùng cho màn hình điện thoại.
      // ClipDrop Uncrop sẽ tự fill phần thiếu. Ta nới cả 4 phía để khi BoxFit.cover
      // không cắt mất đầu/thân con vật như trước.
      req.fields['extend_up']    = '900';
      req.fields['extend_down']  = '900';
      req.fields['extend_left']  = '550';
      req.fields['extend_right'] = '550';

      final res = await http.Response.fromStream(await req.send());
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
      String today, String animalId, Uint8List bytes) async {
    try {
      final path = 'daily/$today/${animalId}_$_imageProcessVersion.png';
      await _db.storage.from('animal-images').uploadBinary(
        path, bytes,
        fileOptions: const FileOptions(contentType: 'image/png', upsert: true),
      );
      final url = _db.storage.from('animal-images').getPublicUrl(path);

      await _db.from(_imageCacheTable).upsert({
        'cache_date':   today,
        'animal_id':    animalId,
        'extended_url': url,
        'created_at':   DateTime.now().toIso8601String(),
      }, onConflict: 'cache_date,animal_id');

      debugPrint('☁️ [ImgCache] Uploaded: $url');
      return url;
    } catch (e) {
      debugPrint('❌ [ImgCache] Upload thất bại: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════
  // BUILD MODEL — tách facts VI / EN riêng
  // ════════════════════════════════════════════════════════
  _DailyAnimal _buildAnimal(
      Map<String, dynamic> a, String imageUrl, LocaleProvider t) {

    // ── Facts tiếng Việt ──
    final factsVi = <String>[];
    final w  = a['weight_avg_kg'];
    final l  = a['length_avg_m'];
    final h  = a['height_avg_m'];
    final s  = a['max_speed_kmh'];
    final ls = a['lifespan_avg_years'];

    if (w  != null) factsVi.add('⚖️ Cân nặng: ${_fmt(w)} kg');
    if (l  != null) factsVi.add('📏 Dài: ${_fmtLen(l)}');
    else if (h != null) factsVi.add('📐 Cao: ${_fmtLen(h)}');
    if (s  != null) factsVi.add('💨 Tốc độ: ${_fmt(s)} km/h');
    if (ls != null) factsVi.add('⏳ Tuổi thọ: ~${_fmt(ls)} năm');

    final dietVi = _mapDiet(a['diet_type'] as String?, false);
    if (dietVi != null) factsVi.add('🍽️ $dietVi');
    final consVi = _mapConservation(a['conservation_status'] as String?, false);
    if (consVi != null) factsVi.add(consVi);

    // ── Facts tiếng Anh ──
    final factsEn = <String>[];
    if (w  != null) factsEn.add('⚖️ Weight: ${_fmt(w)} kg');
    if (l  != null) factsEn.add('📏 Length: ${_fmtLen(l)}');
    else if (h != null) factsEn.add('📐 Height: ${_fmtLen(h)}');
    if (s  != null) factsEn.add('💨 Speed: ${_fmt(s)} km/h');
    if (ls != null) factsEn.add('⏳ Lifespan: ~${_fmt(ls)} years');

    final dietEn = _mapDiet(a['diet_type'] as String?, true);
    if (dietEn != null) factsEn.add('🍽️ $dietEn');
    final consEn = _mapConservation(a['conservation_status'] as String?, true);
    if (consEn != null) factsEn.add(consEn);

    return _DailyAnimal(
      id:             a['id'].toString(),
      nameVi:         a['name_vietnamese']   as String? ?? '',
      nameEn:         a['name_english']      as String? ?? '',
      scientificName: a['scientific_name']   as String? ?? '',
      descriptionVi:  (a['description_short']  as String? ?? '').trim(),
      descriptionEn:  (a['description_english'] as String? ?? '').trim(),
      factsVi:        factsVi,
      factsEn:        factsEn,
      funFactVi:      (a['fun_fact_vietnamese'] as String? ?? '').trim(),
      funFactEn:      (a['fun_fact_english']    as String? ?? '').trim(),
      imageUrl:       imageUrl,
    );
  }

  // ════════════════════════════════════════════════════════
  // LOCAL CACHE
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
        descriptionVi:  m['descriptionVi']  as String,
        descriptionEn:  m['descriptionEn']  as String? ?? '',
        factsVi:        List<String>.from(m['factsVi'] as List),
        factsEn:        List<String>.from(m['factsEn'] as List? ?? []),
        funFactVi:      m['funFactVi']      as String? ?? '',
        funFactEn:      m['funFactEn']      as String? ?? '',
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
        'descriptionVi':  a.descriptionVi,
        'descriptionEn':  a.descriptionEn,
        'factsVi':        a.factsVi,
        'factsEn':        a.factsEn,
        'funFactVi':      a.funFactVi,
        'funFactEn':      a.funFactEn,
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

  // isEnglish=true → trả tiếng Anh, false → tiếng Việt
  String? _mapDiet(String? d, bool isEnglish) {
    if (d == null) return null;
    const vi = {
      'carnivore': 'Ăn thịt', 'herbivore': 'Ăn thực vật',
      'omnivore': 'Ăn tạp',   'insectivore': 'Ăn côn trùng',
      'piscivore': 'Ăn cá',   'frugivore': 'Ăn trái cây',
    };
    const en = {
      'carnivore': 'Carnivore', 'herbivore': 'Herbivore',
      'omnivore': 'Omnivore',   'insectivore': 'Insectivore',
      'piscivore': 'Piscivore', 'frugivore': 'Frugivore',
    };
    return isEnglish ? en[d] : vi[d];
  }

  String? _mapConservation(String? c, bool isEnglish) {
    if (c == null) return null;
    final cl = c.toLowerCase();
    if (isEnglish) {
      if (cl.contains('least concern'))         return '🟢 Least Concern';
      if (cl.contains('near threatened'))       return '🔵 Near Threatened';
      if (cl.contains('vulnerable'))            return '🟡 Vulnerable';
      if (cl.contains('critically endangered')) return '🔴 Critically Endangered';
      if (cl.contains('endangered'))            return '🟠 Endangered';
      if (cl.contains('extinct in the wild'))   return '⚫ Extinct in the Wild';
    } else {
      if (cl.contains('least concern'))         return '🟢 Ít lo ngại';
      if (cl.contains('near threatened'))       return '🔵 Sắp bị đe dọa';
      if (cl.contains('vulnerable'))            return '🟡 Dễ bị tổn thương';
      if (cl.contains('critically endangered')) return '🔴 Cực kỳ nguy cấp';
      if (cl.contains('endangered'))            return '🟠 Nguy cấp';
      if (cl.contains('extinct in the wild'))   return '⚫ Tuyệt chủng ngoài TN';
    }
    return null;
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
              Text(t.tr('Đang tải thông tin loài vật...'),
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    if (_animal == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(t.tr(_error ?? 'Có lỗi xảy ra'),
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _load(t),
                icon: const Icon(Icons.refresh),
                label: Text(t.tr('Thử lại')),
              ),
            ],
          ),
        ),
      );
    }

    final a  = _animal!;
    final isEn = t.isEnglish;

    // ── Chọn nội dung theo ngôn ngữ ──────────────────────
    final displayName = isEn
        ? (a.nameEn.isNotEmpty ? a.nameEn : a.nameVi)
        : a.nameVi;
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
        fit: StackFit.expand, // 👈 fix ảnh tràn: stack fill toàn màn hình
        children: [
          // ── ẢNH NỀN — fix: SizedBox.expand + BoxFit.cover ─
          _buildBackground(a.imageUrl),

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
                            shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEn
                              ? '${_monthEn(DateTime.now().month)} ${DateTime.now().day}, ${DateTime.now().year}'
                              : '${t.tr('Ngày')} ${DateTime.now().day} ${t.tr('tháng')} ${DateTime.now().month} ${t.tr('năm')} ${DateTime.now().year}',
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
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 12, height: 12,
                              child: CircularProgressIndicator(
                                  color: Colors.white60, strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(t.tr('Đang xử lý ảnh...'),
                                style: const TextStyle(
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
                        // Tên chính
                        Text(
                          displayName,
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

                        // Tên phụ (ngôn ngữ còn lại)
                        if (subName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subName,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 13),
                          ),
                        ],

                        // Mô tả
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            description,
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
                        ...facts.take(4).map((fact) => Padding(
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

                        // Fun fact
                        if (funFact.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 1),
                                child: Icon(Icons.lightbulb_outline,
                                    size: 13, color: Colors.yellowAccent),
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
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],

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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.keyboard_arrow_up_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(t.tr('Trượt lên để khám phá'),
                                    style: const TextStyle(
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

  // ── Ảnh nền: dùng ảnh đã Uncrop, căn giữa để con vật dễ nằm trung tâm ─────
  Widget _buildBackground(String url) {
    if (url.isEmpty) {
      return Container(color: const Color(0xFF0F172A));
    }

    return SizedBox.expand(
      child: Image.network(
        url,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) =>
            Container(color: const Color(0xFF0F172A)),
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

  String _monthEn(int month) => const [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ][month];
}