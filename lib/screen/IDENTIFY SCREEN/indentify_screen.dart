import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Import trang chi tiết và model — chỉnh đường dẫn cho đúng với project
import '../animal_list/Animal detail screen.dart';
import '../home/animal_category_model.dart';


class IdentifyScreen extends StatefulWidget {
  const IdentifyScreen({super.key});

  @override
  State<IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends State<IdentifyScreen>
    with SingleTickerProviderStateMixin {
  // ── Colors ────────────────────────────────────────────────────────────────
  static const _primaryGreen = Color(0xFF34D399);
  static const _bgColor = Color(0xFFF8FAFC);

  // ── API ───────────────────────────────────────────────────────────────────
  static const _geminiApiKey = 'AIzaSyCWcewCDAfJZASHrb5RyjTjEz2c901Wb_U';
  static const _geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static const _groqApiKey = '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';
  static const _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _groqModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

  // ── Supabase ──────────────────────────────────────────────────────────────
  static const _supabaseUrl = 'https://dnvlqnixommhjqwpflmw.supabase.co';
  static const _supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRudmxxbml4b21taGpxd3BmbG13Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MDMzMTUwMSwiZXhwIjoyMDg1OTA3NTAxfQ.W2cxnWC-DJoE9GRdUWMZU3-e27VFVA05BTJotZHfR54';

  // ── State (AI nhận diện tự do, Supabase fuzzy search khớp tên) ─────────
  // ── State ─────────────────────────────────────────────────────────────────
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  File? _selectedImage;
  String _aiSource = '';

  // Kết quả nhận diện
  String? _resultNameVi;    // tên tiếng Việt (hiển thị)
  String? _resultNameEn;    // tên tiếng Anh (query DB)
  String? _resultConfidence;
  String? _resultAnimalId;  // id trong Supabase
  String? _resultImageUrl;  // ảnh từ DB để preview

  // Animation cho result card
  late AnimationController _cardAnimCtrl;
  late Animation<double> _cardFadeAnim;
  late Animation<Offset> _cardSlideAnim;

  // Local model
  Interpreter? _interpreter;
  List<String> _labels = [];

  @override
  void initState() {
    super.initState();
    _loadModel();
    _cardAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cardFadeAnim = CurvedAnimation(
      parent: _cardAnimCtrl,
      curve: Curves.easeOut,
    );
    _cardSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardAnimCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _interpreter?.close();
    _cardAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter =
      await Interpreter.fromAsset('assets/cat_classifier.tflite');
      final raw = await rootBundle.loadString('assets/labels.txt');
      _labels = raw.trim().split('\n');
    } catch (e) {
      debugPrint('❌ Load model: $e');
    }
  }

  Future<bool> _hasNetwork() async {
    try {
      final res = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isAnalyzing) return;
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: null,
        maxWidth: null,
        maxHeight: null,
      );
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
          _clearResult();
        });
      }
    } catch (e) {
      debugPrint('Lỗi chọn ảnh: $e');
    }
  }

  void _clearResult() {
    _resultNameVi = null;
    _resultNameEn = null;
    _resultConfidence = null;
    _resultAnimalId = null;
    _resultImageUrl = null;
    _aiSource = '';
    _cardAnimCtrl.reset();
  }

  // ── Entry point ───────────────────────────────────────────────────────────
  Future<void> _startSearching() async {
    if (_selectedImage == null || _isAnalyzing) return;
    final File snap = _selectedImage!;
    setState(() {
      _isAnalyzing = true;
      _clearResult();
    });

    final online = await _hasNetwork();
    if (!online) {
      await _identifyWithLocalModel(imageFile: snap);
      return;
    }

    debugPrint('🔄 Bước 1: Thử Gemini...');
    final geminiOk = await _identifyWithGemini(snap);
    if (geminiOk) { debugPrint('✅ Gemini thành công'); return; }

    debugPrint('🔄 Bước 2: Gemini thất bại → thử Groq Llama...');
    final groqOk = await _identifyWithGroq(snap);
    if (groqOk) { debugPrint('✅ Groq thành công'); return; }

    debugPrint('🔄 Bước 3: Groq thất bại → dùng Local model');
    await _identifyWithLocalModel(imageFile: snap, fallback: true);
  }

  // ── Chuẩn bị ảnh ─────────────────────────────────────────────────────────
  Future<Uint8List> _prepareImage(File f) async {
    final raw = await f.readAsBytes();
    final decoded = img.decodeImage(raw);
    if (decoded == null) throw Exception('Không decode được ảnh');
    final resized = (decoded.width > 800 || decoded.height > 800)
        ? img.copyResize(decoded,
        width: decoded.width >= decoded.height ? 800 : -1,
        height: decoded.height > decoded.width ? 800 : -1)
        : decoded;
    final jpeg = Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    debugPrint('📤 ${resized.width}x${resized.height} '
        '${(jpeg.length / 1024).toStringAsFixed(0)}KB');
    return jpeg;
  }

  // ── Prompt: AI nhận diện tự do, trả tên chuẩn quốc tế ─────────────────────
  // Không hard-code danh sách → dùng được cho mọi loài (mèo, chó, trâu, hổ...)
  // Supabase sẽ fuzzy search để khớp tên dù AI trả về hơi khác
  static const _prompt =
      'You are an expert zoologist and animal breed identifier. '
      'Look at this image carefully and identify:\n'
      '1. The animal type (cat, dog, tiger, buffalo, horse, etc.)\n'
      '2. The specific breed or subspecies\n\n'
      'Reply with ONLY these 3 lines, no extra text, no markdown:\n'
      'BREED===[internationally recognized English breed/species name, e.g. British Shorthair]\n'
      'NAMEVI===[Vietnamese name, e.g. Mèo Anh lông ngắn]\n'
      'TYLE===[confidence integer 0-100]';

  // ── Parse kết quả ─────────────────────────────────────────────────────────
  Map<String, String>? _parseResponse(String raw) {
    debugPrint('📥 Raw:\n$raw');
    String breed = '';
    String nameVi = '';
    String tiLe = '';

    for (final line in raw
        .replaceAll('\r', '')
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll('[', '')
        .replaceAll(']', '')
        .trim()
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)) {
      if (line.contains('BREED===')) {
        breed = line.split('BREED===').last.trim();
      } else if (line.contains('NAMEVI===')) {
        nameVi = line.split('NAMEVI===').last.trim();
      } else if (line.contains('TYLE===')) {
        tiLe = line.split('TYLE===').last.replaceAll('%', '').trim();
      }
    }

    debugPrint('✅ breed=$breed | nameVi=$nameVi | tyle=$tiLe');
    if (breed.isEmpty) return null;
    if (nameVi.isEmpty) nameVi = breed;
    if (tiLe.isEmpty) tiLe = '?';

    return {
      'breed': breed,     // tên AI trả về → Supabase sẽ fuzzy search
      'nameVi': nameVi,
      'confidence': tiLe,
    };
  }

  // Không cần local list matching nữa — Supabase xử lý trong _fetchAndSetResult

  // ── Gemini ────────────────────────────────────────────────────────────────
  Future<bool> _identifyWithGemini(File f) async {
    try {
      final jpeg = await _prepareImage(f);
      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'inline_data': {'mime_type': 'image/jpeg', 'data': base64Encode(jpeg)}},
              {'text': _prompt}
            ]
          }
        ],
        'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 80},
      });

      final res = await http
          .post(Uri.parse('$_geminiUrl?key=$_geminiApiKey'),
          headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        debugPrint('⚠️ Gemini lỗi ${res.statusCode} → thử Groq');
        return false;
      }

      final json = jsonDecode(res.body);
      // Kiểm tra có candidates không (đôi khi Gemini trả 200 nhưng bị filter)
      final candidates = json['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        debugPrint('⚠️ Gemini không có candidates → thử Groq');
        return false;
      }

      final text = candidates[0]['content']['parts'][0]['text'] as String;
      final result = _parseResponse(text);
      if (result == null) {
        debugPrint('⚠️ Gemini parse thất bại → thử Groq');
        return false;
      }

      return await _fetchAndSetResult(result, 'gemini');
    } catch (e) {
      debugPrint('⚠️ Gemini exception: $e → thử Groq');
      return false;
    }
  }

  // ── Groq Llama ────────────────────────────────────────────────────────────
  Future<bool> _identifyWithGroq(File f) async {
    try {
      final jpeg = await _prepareImage(f);
      final body = jsonEncode({
        'model': _groqModel,
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,${base64Encode(jpeg)}'}},
              {'type': 'text', 'text': _prompt}
            ]
          }
        ],
        'temperature': 0.1,
        'max_tokens': 80,
      });

      final res = await http
          .post(Uri.parse(_groqUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_groqApiKey',
          },
          body: body)
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        debugPrint('⚠️ Groq lỗi ${res.statusCode} → thử Local');
        return false;
      }

      final choices = jsonDecode(res.body)['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        debugPrint('⚠️ Groq không có choices → thử Local');
        return false;
      }

      final text = choices[0]['message']['content'] as String;
      final result = _parseResponse(text);
      if (result == null) {
        debugPrint('⚠️ Groq parse thất bại → thử Local');
        return false;
      }

      return await _fetchAndSetResult(result, 'groq');
    } catch (e) {
      debugPrint('⚠️ Groq exception: $e → thử Local');
      return false;
    }
  }

  // ── Danh sách breed trong DB theo loài ─────────────────────────────────────
  static const _dbBreedsByType = {
    'cat': [
      'Abyssinian', 'Aegean', 'American Bobtail', 'American Curl',
      'American Shorthair', 'American Wirehair', 'Aphrodite Giant',
      'Arabian Mau', 'Australian Mist', 'Balinese', 'Bambino', 'Bengal',
      'Birman', 'Bombay', 'Brazilian Shorthair', 'British Longhair',
      'British Shorthair', 'Burmese', 'Burmilla', 'California Spangled',
      'Chantilly-Tiffany', 'Chartreux', 'Chausie', 'Cheetoh',
      'Colorpoint Shorthair', 'Cornish Rex', 'Cymric', 'Cyprus', 'Devon Rex',
      'Donskoy', 'Dragon Li', 'Egyptian Mau', 'European Shorthair',
      'Exotic Shorthair', 'German Rex', 'Havana Brown', 'Highlander',
      'Himalayan', 'Japanese Bobtail', 'Javanese', 'Kanaani', 'Khao Manee',
      'Kinkalow', 'Korat', 'Kurilian Bobtail', 'LaPerm', 'Lykoi',
      'Maine Coon', 'Manx', 'Mekong Bobtail', 'Minskin', 'Minuet',
      'Munchkin', 'Nebelung', 'Norwegian Forest Cat', 'Ocicat', 'Ojos Azules',
      'Oregon Rex', 'Oriental Bicolour', 'Oriental Longhair',
      'Oriental Shorthair', 'Persian', 'Peterbald', 'Pixie-bob', 'Ragamuffin',
      'Ragdoll', 'Russian Blue', 'Savannah', 'Scottish Fold', 'Selkirk Rex',
      'Serengeti', 'Siamese', 'Siberian', 'Singapura', 'Snowshoe', 'Sokoke',
      'Somali', 'Sphynx', 'Thai', 'Tonkinese', 'Toyger', 'Turkish Angora',
      'Turkish Van', 'Ukranian Levkoy', 'York Chocolate',
    ],
    // Khi có data chó/hổ/trâu trong DB → thêm vào đây:
    // 'dog': ['Golden Retriever', 'Labrador', ...],
  };

  // ── Query Supabase 3 tầng + AI remap tầng 4 nếu vẫn không tìm thấy ─────────
  Future<bool> _fetchAndSetResult(Map<String, String> parsed, String source) async {
    final breed = parsed['breed']!;
    final nameVi = parsed['nameVi']!;
    debugPrint('🔍 Tìm DB: "$breed" / "$nameVi"');

    Map<String, dynamic>? animal;

    try {
      // Tầng 1: exact match
      animal = await _querySupabase('name_english=eq.${Uri.encodeComponent(breed)}');

      // Tầng 2: ilike English
      animal ??= await _querySupabase(
          'name_english=ilike.${Uri.encodeComponent('%${breed.trim()}%')}');

      // Tầng 3: ilike Vietnamese
      if (animal == null && nameVi.isNotEmpty) {
        animal ??= await _querySupabase(
            'name_vietnamese=ilike.${Uri.encodeComponent('%${nameVi.trim()}%')}');
      }

      // Tầng 4: AI remap — Domestic Shorthair → American Shorthair
      if (animal == null) {
        debugPrint('⚠️ Không khớp DB → Tầng 4: AI remap...');
        final remapped = await _remapBreedWithAI(breed, nameVi);
        if (remapped != null) {
          animal = await _querySupabase(
              'name_english=eq.${Uri.encodeComponent(remapped)}');
          if (animal != null) debugPrint('✅ Remap: "$breed" → "$remapped"');
        }
      }
    } catch (e) {
      debugPrint('❌ Supabase: $e');
    }

    if (animal != null) {
      setState(() {
        _resultAnimalId = animal!['id'].toString();
        _resultNameVi = animal['name_vietnamese'] ?? nameVi;
        _resultNameEn = animal['name_english'] ?? breed;
        _resultImageUrl = animal['image_url'];
        _resultConfidence = parsed['confidence'];
        _aiSource = source;
        _isAnalyzing = false;
      });
      _cardAnimCtrl.forward();
      return true;
    }

    // Vẫn không tìm → hiển thị nhưng không navigate
    debugPrint('⚠️ "$breed" không có trong DB');
    setState(() {
      _resultNameVi = nameVi;
      _resultNameEn = breed;
      _resultConfidence = parsed['confidence'];
      _resultAnimalId = null;
      _aiSource = source;
      _isAnalyzing = false;
    });
    _cardAnimCtrl.forward();
    return true;
  }

  // ── Tầng 4: Groq text model map tên lạ → tên chuẩn trong DB ─────────────────
  // "Domestic Shorthair" → "American Shorthair"
  // "Tabby cat"          → "American Shorthair"
  // "Mixed Persian"      → "Persian"
  Future<String?> _remapBreedWithAI(String breed, String nameVi) async {
    try {
      final animalType = _detectAnimalType(breed, nameVi);
      final dbList = _dbBreedsByType[animalType];
      if (dbList == null) return null;

      final prompt = 'The image AI identified a cat as: "$breed" ($nameVi).\n'
          'This name is NOT in the database. '
          'Pick the SINGLE closest breed from this list:\n'
          '${dbList.join(', ')}\n\n'
          'Reply with ONLY the exact breed name from the list above. Nothing else.';

      final res = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [{'role': 'user', 'content': prompt}],
          'temperature': 0.1,
          'max_tokens': 20,
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final text = (jsonDecode(res.body)['choices'][0]['message']['content'] as String)
            .trim().replaceAll('"', '').replaceAll("'", '');
        // Validate phải nằm trong DB list
        for (final b in dbList) {
          if (b.toLowerCase() == text.toLowerCase()) return b;
        }
      }
    } catch (e) {
      debugPrint('❌ AI remap: $e');
    }
    return null;
  }

  // Detect loài từ tên breed
  String _detectAnimalType(String breed, String nameVi) {
    final s = '${breed.toLowerCase()} ${nameVi.toLowerCase()}';
    if (s.contains('dog') || s.contains('chó') || s.contains('puppy')) return 'dog';
    return 'cat'; // mặc định cat
  }
  // ── Supabase helper: query 1 record theo filter bất kỳ ──────────────────────
  // Dùng chung cho exact, ilike English, ilike Vietnamese
  Future<Map<String, dynamic>?> _querySupabase(String filter) async {
    final url = '$_supabaseUrl/rest/v1/animals'
        '?$filter'
        '&select=id,name_vietnamese,name_english,image_url'
        '&limit=1';
    try {
      final res = await http.get(Uri.parse(url), headers: {
        'apikey': _supabaseKey,
        'Authorization': 'Bearer $_supabaseKey',
      }).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        if (data.isNotEmpty) {
          debugPrint('   ✅ Match: $filter');
          return data[0] as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return null;
  }

  // ── Local TFLite ──────────────────────────────────────────────────────────
  Future<void> _identifyWithLocalModel({
    required File imageFile,
    bool fallback = false,
  }) async {
    if (_interpreter == null) {
      setState(() { _isAnalyzing = false; });
      return;
    }
    try {
      final bytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes)!;
      final resized = img.copyResize(decoded, width: 224, height: 224);

      final input = List.generate(1, (_) =>
          List.generate(224, (y) =>
              List.generate(224, (x) => [
                resized.getPixel(x, y).r / 255.0,
                resized.getPixel(x, y).g / 255.0,
                resized.getPixel(x, y).b / 255.0,
              ])));

      final output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);
      _interpreter!.run(input, output);

      final scores = List<double>.from(output[0]);
      final maxIdx = scores.indexOf(scores.reduce((a, b) => a > b ? a : b));
      final confidence = (scores[maxIdx] * 100).toStringAsFixed(1);
      final breed = _labels[maxIdx];

      await _fetchAndSetResult({
        'breed': breed,
        'nameVi': breed,
        'confidence': confidence,
      }, fallback ? 'local_fallback' : 'local');
    } catch (e) {
      setState(() { _isAnalyzing = false; });
    }
  }

  // ── Mở trang chi tiết ─────────────────────────────────────────────────────
  void _openDetail() {
    if (_resultAnimalId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnimalDetailScreen(
          animalId: _resultAnimalId!,
          category: _buildCatCategory(),
        ),
      ),
    );
  }

  AnimalCategory _buildCatCategory() {
    // Dùng getById để lấy đúng category đã định nghĩa sẵn trong allCategories
    return AnimalCategory.getById('cat') ??
        AnimalCategory(
          id: 'cat',
          nameVi: 'Mèo',
          nameEn: 'Cat',
          icon: Icons.pets,
          gradient: [const Color(0xFFEC4899), const Color(0xFFDB2777)],
          imageAssetPath: 'assets/animals/cat.jpg',
          totalExpected: 73,
        );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // UI
  // ═════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildImageFrame(),
                        const SizedBox(height: 16),
                        _buildPickButtons(),
                        if (_selectedImage != null) ...[
                          const SizedBox(height: 12),
                          _buildSearchButton(),
                        ],
                        const SizedBox(height: 20),
                        // Result section
                        if (_resultNameVi != null) _buildResultSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isAnalyzing) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nhận Diện',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B))),
                const Text('Chụp hoặc tải ảnh để nhận diện động vật',
                    style:
                    TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
          ),
          if (_aiSource.isNotEmpty) _buildAiBadge(),
        ],
      ),
    );
  }

  Widget _buildImageFrame() {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _primaryGreen.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: _selectedImage != null
            ? Stack(fit: StackFit.expand, children: [
          Image.file(_selectedImage!, fit: BoxFit.cover),
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedImage = null;
                _clearResult();
              }),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(CupertinoIcons.clear,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ])
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: _primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.photo,
                  color: _primaryGreen, size: 40),
            ),
            const SizedBox(height: 12),
            const Text('Chưa có ảnh nào',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B))),
            const SizedBox(height: 6),
            const Text('Vui lòng chụp hoặc tải ảnh từ thư viện',
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }

  Widget _buildPickButtons() {
    return Row(
      children: [
        Expanded(
            child: _buildOptionCard(
              icon: CupertinoIcons.camera_fill,
              label: 'Chụp ảnh',
              gradient: const [Color(0xFF818CF8), Color(0xFF6366F1)],
              onTap: () => _pickImage(ImageSource.camera),
            )),
        const SizedBox(width: 12),
        Expanded(
            child: _buildOptionCard(
              icon: CupertinoIcons.photo_on_rectangle,
              label: 'Thư viện',
              gradient: const [Color(0xFF818CF8), Color(0xFF6366F1)],
              onTap: () => _pickImage(ImageSource.gallery),
            )),
      ],
    );
  }

  Widget _buildSearchButton() {
    return ElevatedButton(
      onPressed: _isAnalyzing ? null : _startSearching,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: _primaryGreen,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.search, color: Colors.white),
          SizedBox(width: 8),
          Text('Tìm kiếm loài vật',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ── Result section ────────────────────────────────────────────────────────
  Widget _buildResultSection() {
    return FadeTransition(
      opacity: _cardFadeAnim,
      child: SlideTransition(
        position: _cardSlideAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _primaryGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Kết quả nhận diện',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 12),
            // Card loài
            _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final canNavigate = _resultAnimalId != null;

    return GestureDetector(
      onTap: canNavigate ? _openDetail : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: canNavigate
                ? _primaryGreen.withOpacity(0.5)
                : Colors.grey.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _primaryGreen.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Row(
          children: [
            // Ảnh preview từ DB hoặc ảnh người dùng chọn
            ClipRRect(
              borderRadius:
              const BorderRadius.horizontal(left: Radius.circular(19)),
              child: SizedBox(
                width: 110,
                height: 110,
                child: _resultImageUrl != null
                    ? Image.network(
                  _resultImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                )
                    : _selectedImage != null
                    ? Image.file(_selectedImage!, fit: BoxFit.cover)
                    : _buildImagePlaceholder(),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên tiếng Việt
                    Text(
                      _resultNameVi ?? '',
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 2),
                    // Tên tiếng Anh
                    Text(
                      _resultNameEn ?? '',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    // Tỉ lệ chính xác
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_resultConfidence ?? '?'}% phù hợp',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _primaryGreen),
                          ),
                        ),
                      ],
                    ),
                    if (canNavigate) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Xem chi tiết',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: _primaryGreen,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios,
                              size: 12, color: _primaryGreen),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      const Text('Không tìm thấy trong database',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF94A3B8))),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: _primaryGreen.withOpacity(0.08),
      child: const Center(
        child: Icon(CupertinoIcons.photo, color: _primaryGreen, size: 32),
      ),
    );
  }

  // ── Loading overlay ───────────────────────────────────────────────────────
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: _primaryGreen),
            const SizedBox(height: 16),
            const Text('Đang phân tích hình ảnh...',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              _aiSource == 'groq'
                  ? '⚡ Groq Llama 4'
                  : '✨ Gemini 2.5 Flash',
              style:
              const TextStyle(color: _primaryGreen, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ── AI Badge ──────────────────────────────────────────────────────────────
  Widget _buildAiBadge() {
    final isGemini = _aiSource == 'gemini';
    final isGroq = _aiSource == 'groq';
    final Color color = isGemini
        ? const Color(0xFF4285F4)
        : isGroq
        ? const Color(0xFF7C3AED)
        : _primaryGreen;
    final String label = isGemini
        ? 'Gemini'
        : isGroq
        ? 'Groq'
        : _aiSource == 'local_fallback'
        ? 'Local*'
        : 'Local AI';
    final IconData icon = isGemini
        ? Icons.auto_awesome
        : isGroq
        ? Icons.bolt
        : Icons.memory;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: gradient[0].withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}