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
  // ── Colors (Đã tinh chỉnh cho độ tương phản cao, phong cách động vật) ─────
  static const _primaryGreen = Color(0xFF2E7D32); // Xanh Safari
  static const _accentOrange = Color(0xFFEF6C00); // Cam Hổ
  static const _bgColor = Colors.white; // Nền trắng tinh

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
      duration: const Duration(milliseconds: 600), // Làm mượt hơn chút
    );
    _cardFadeAnim = CurvedAnimation(
      parent: _cardAnimCtrl,
      curve: Curves.easeOut,
    );
    _cardSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardAnimCtrl, curve: Curves.easeOutBack));
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
      'breed': breed,
      'nameVi': nameVi,
      'confidence': tiLe,
    };
  }

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
  };

  // ── Query Supabase 3 tầng + AI remap tầng 4 ─────────────────────────────
  Future<bool> _fetchAndSetResult(Map<String, String> parsed, String source) async {
    final breed = parsed['breed']!;
    final nameVi = parsed['nameVi']!;
    debugPrint('🔍 Tìm DB: "$breed" / "$nameVi"');

    Map<String, dynamic>? animal;

    try {
      animal = await _querySupabase('name_english=eq.${Uri.encodeComponent(breed)}');
      animal ??= await _querySupabase('name_english=ilike.${Uri.encodeComponent('%${breed.trim()}%')}');
      if (animal == null && nameVi.isNotEmpty) {
        animal ??= await _querySupabase('name_vietnamese=ilike.${Uri.encodeComponent('%${nameVi.trim()}%')}');
      }

      if (animal == null) {
        debugPrint('⚠️ Không khớp DB → Tầng 4: AI remap...');
        final remapped = await _remapBreedWithAI(breed, nameVi);
        if (remapped != null) {
          animal = await _querySupabase('name_english=eq.${Uri.encodeComponent(remapped)}');
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
        for (final b in dbList) {
          if (b.toLowerCase() == text.toLowerCase()) return b;
        }
      }
    } catch (e) {
      debugPrint('❌ AI remap: $e');
    }
    return null;
  }

  String _detectAnimalType(String breed, String nameVi) {
    final s = '${breed.toLowerCase()} ${nameVi.toLowerCase()}';
    if (s.contains('dog') || s.contains('chó') || s.contains('puppy')) return 'dog';
    return 'cat';
  }

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
  // GIAO DIỆN MỚI (Lively, High Contrast, Animal Theme)
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
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildImageFrame(),
                        const SizedBox(height: 24),
                        _buildPickButtons(),
                        if (_selectedImage != null) ...[
                          const SizedBox(height: 20),
                          _buildSearchButton(),
                        ],
                        const SizedBox(height: 24),
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Camera Thú Vị',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: _primaryGreen, // Chữ xanh nổi bật
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.pets_rounded, color: _accentOrange, size: 28), // Icon chân thú
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Khám phá thế giới động vật qua ống kính',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
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
      aspectRatio: 4 / 3.5, // Hơi vuông một chút giống polaroid
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _selectedImage == null ? Colors.grey[50] : Colors.white,
          borderRadius: BorderRadius.circular(32), // Bo góc tròn trịa hơn
          border: Border.all(
            color: _selectedImage == null ? Colors.grey[300]! : _primaryGreen,
            width: 3, // Viền dày tạo độ tương phản
          ),
          boxShadow: _selectedImage != null
              ? [
            BoxShadow(
              color: _primaryGreen.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 12),
            )
          ]
              : null,
        ),
        child: _selectedImage != null
            ? Stack(
          fit: StackFit.expand,
          children: [
            Image.file(_selectedImage!, fit: BoxFit.cover),
            // Nút xóa ảnh nổi bật
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedImage = null;
                  _clearResult();
                }),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                  ),
                  child: const Icon(CupertinoIcons.clear_thick, color: Colors.redAccent, size: 20),
                ),
              ),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: _accentOrange.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: Icon(Icons.center_focus_strong_rounded,
                  color: _accentOrange, size: 50),
            ),
            const SizedBox(height: 16),
            const Text('Chưa có dấu chân nào',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 8),
            Text('Chọn một bức ảnh để bắt đầu',
                style: TextStyle(fontSize: 14, color: Colors.grey[500])),
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
              icon: Icons.camera_alt_rounded,
              label: 'Chụp Mới',
              bgColor: _primaryGreen, // Màu mảng khối rõ ràng
              onTap: () => _pickImage(ImageSource.camera),
            )),
        const SizedBox(width: 16),
        Expanded(
            child: _buildOptionCard(
              icon: Icons.photo_library_rounded,
              label: 'Thư Viện',
              bgColor: _accentOrange, // Tương phản với màu xanh
              onTap: () => _pickImage(ImageSource.gallery),
            )),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String label,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: bgColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return ElevatedButton(
      onPressed: _isAnalyzing ? null : _startSearching,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        backgroundColor: Colors.black87, // Màu đen tạo sự tập trung chú ý
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.saved_search_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          const Text('Bắt Đầu Phân Tích',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
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
            Row(
              children: [
                Icon(Icons.stars_rounded, color: _accentOrange),
                const SizedBox(width: 8),
                const Text('Kết Quả Hồ Sơ',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 16),
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
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: canNavigate ? _primaryGreen : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: canNavigate ? _primaryGreen.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            // Ảnh preview
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 100,
                  height: 100,
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
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 16, top: 12, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _resultNameVi ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          height: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _resultNameEn ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey[600], fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Badge tỉ lệ
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _accentOrange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_resultConfidence ?? '?'}% Khớp',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _accentOrange),
                          ),
                        ),
                        if (canNavigate)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                          ),
                      ],
                    ),
                    if (!canNavigate) ...[
                      const SizedBox(height: 8),
                      const Text('Loài này chưa có trong từ điển',
                          style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w600)),
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
      color: Colors.grey[100],
      child: Center(
        child: Icon(Icons.pets_rounded, color: Colors.grey[400], size: 36),
      ),
    );
  }

  // ── Loading overlay ───────────────────────────────────────────────────────
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white.withOpacity(0.9), // Nền trắng mờ để vẫn nhìn thấy mờ mờ UI phía sau
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                )
              ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      color: _accentOrange,
                      strokeWidth: 4,
                    ),
                  ),
                  Icon(Icons.pets_rounded, color: _primaryGreen, size: 28),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Đang đánh hơi...',
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                _aiSource == 'groq'
                    ? '⚡ Groq Llama 4 đang dò tìm'
                    : '✨ Gemini 2.5 đang tra cứu',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
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
        ? 'Gemini AI'
        : isGroq
        ? 'Groq AI'
        : _aiSource == 'local_fallback'
        ? 'Local AI*'
        : 'Local AI';
    final IconData icon = isGemini
        ? Icons.auto_awesome
        : isGroq
        ? Icons.bolt
        : Icons.memory;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }
}