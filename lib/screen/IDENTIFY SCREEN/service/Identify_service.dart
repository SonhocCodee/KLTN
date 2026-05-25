import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ── Model lịch sử tìm kiếm ────────────────────────────────────────────────
class SearchHistoryItem {
  final int id;
  final DateTime createdAt;
  final String nameVi;
  final String nameEn;
  final String? confidence;
  final String? aiSource;
  final String? animalId;
  final String? animalImageUrl;

  const SearchHistoryItem({
    required this.id,
    required this.createdAt,
    required this.nameVi,
    required this.nameEn,
    this.confidence,
    this.aiSource,
    this.animalId,
    this.animalImageUrl,
  });

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      nameVi: json['name_vi'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      confidence: json['confidence'] as String?,
      aiSource: json['ai_source'] as String?,
      animalId: json['animal_id'] as String?,
      animalImageUrl: json['animal_image_url'] as String?,
    );
  }
}

class IdentifyService extends ChangeNotifier {
  // ── API Keys & Endpoints (Giữ nguyên 100%) ────────────────────────────────
  static const _geminiApiKey = 'AIzaSyCWcewCDAfJZASHrb5RyjTjEz2c901Wb_U';
  static const _geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static const _groqApiKey = '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';
  static const _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _groqModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

  static const _supabaseUrl = 'https://dnvlqnixommhjqwpflmw.supabase.co';
  static const _supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRudmxxbml4b21taGpxd3BmbG13Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MDMzMTUwMSwiZXhwIjoyMDg1OTA3NTAxfQ.W2cxnWC-DJoE9GRdUWMZU3-e27VFVA05BTJotZHfR54';

  static const _prompt =
      'You are an expert zoologist and animal breed identifier. '
      'Look at this image carefully and identify:\n'
      '1. The animal type (cat, dog, tiger, buffalo, horse, etc.)\n'
      '2. The specific breed or subspecies\n\n'
      'If the image does NOT contain any animal, reply with exactly: NOT_ANIMAL\n\n'
      'Otherwise, reply with ONLY these 3 lines, no extra text, no markdown:\n'
      'BREED===[internationally recognized English breed/species name, e.g. British Shorthair]\n'
      'NAMEVI===[Vietnamese name, e.g. Mèo Anh lông ngắn]\n'
      'TYLE===[confidence integer 0-100]';

  // ── State Variables ───────────────────────────────────────────────────────
  final ImagePicker _picker = ImagePicker();
  bool isAnalyzing = false;
  File? selectedImage;
  String aiSource = '';

  String? resultNameVi;
  String? resultNameEn;
  String? resultConfidence;
  String? resultAnimalId;
  String? resultImageUrl;

  // Trạng thái ảnh không hợp lệ (không phải động vật)
  bool isNotAnimal = false;

  // ── Lịch sử tìm kiếm ─────────────────────────────────────────────────────
  List<SearchHistoryItem> historyItems = [];
  bool isLoadingHistory = false;

  Interpreter? _interpreter;
  List<String> _labels = [];

  // ── Initialize Local Model ────────────────────────────────────────────────
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/cat_classifier.tflite');
      final raw = await rootBundle.loadString('assets/labels.txt');
      _labels = raw.trim().split('\n');
    } catch (e) {
      debugPrint('❌ Load model: $e');
    }
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  // ── Core Actions ──────────────────────────────────────────────────────────
  Future<void> pickImage(ImageSource source) async {
    if (isAnalyzing) return;
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: null,
        maxWidth: null,
        maxHeight: null,
      );
      if (picked != null) {
        selectedImage = File(picked.path);
        clearResult();
      }
    } catch (e) {
      debugPrint('Lỗi chọn ảnh: $e');
    }
  }

  void clearImage() {
    selectedImage = null;
    clearResult();
  }

  void clearResult() {
    resultNameVi = null;
    resultNameEn = null;
    resultConfidence = null;
    resultAnimalId = null;
    resultImageUrl = null;
    aiSource = '';
    isNotAnimal = false;
    notifyListeners();
  }

  // ── Search Flow ───────────────────────────────────────────────────────────
  Future<void> startSearching(VoidCallback onDone) async {
    if (selectedImage == null || isAnalyzing) return;
    final File snap = selectedImage!;

    isAnalyzing = true;
    clearResult();

    final online = await _hasNetwork();
    if (!online) {
      await _identifyWithLocalModel(imageFile: snap, onDone: onDone);
      return;
    }

    debugPrint('🔄 Bước 1: Thử Gemini...');
    final geminiResult = await _identifyWithGemini(snap, onDone);
    if (geminiResult) { debugPrint('✅ Kết thúc xử lý Gemini'); return; }

    debugPrint('🔄 Bước 2: Thử Groq Llama...');
    final groqResult = await _identifyWithGroq(snap, onDone);
    if (groqResult) { debugPrint('✅ Kết thúc xử lý Groq'); return; }

    debugPrint('🔄 Bước 3: Dùng Local model (API lỗi mạng)');
    await _identifyWithLocalModel(imageFile: snap, fallback: true, onDone: onDone);
  }

  Future<bool> _hasNetwork() async {
    try {
      final res = await http.get(Uri.parse('https://www.google.com')).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

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
    return jpeg;
  }

  Map<String, String>? _parseResponse(String raw) {
    if (raw.toUpperCase().contains('NOT_ANIMAL')) {
      return {'status': 'NOT_ANIMAL'};
    }

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
      if (line.contains('BREED===')) breed = line.split('BREED===').last.trim();
      else if (line.contains('NAMEVI===')) nameVi = line.split('NAMEVI===').last.trim();
      else if (line.contains('TYLE===')) tiLe = line.split('TYLE===').last.replaceAll('%', '').trim();
    }

    if (breed.isEmpty) return null;
    if (nameVi.isEmpty) nameVi = breed;
    if (tiLe.isEmpty) tiLe = '?';

    return {'breed': breed, 'nameVi': nameVi, 'confidence': tiLe, 'status': 'OK'};
  }

  // ── AI Identifications ────────────────────────────────────────────────────
  Future<bool> _identifyWithGemini(File f, VoidCallback onDone) async {
    try {
      final jpeg = await _prepareImage(f);
      final body = jsonEncode({
        'contents': [{'parts': [{'inline_data': {'mime_type': 'image/jpeg', 'data': base64Encode(jpeg)}}, {'text': _prompt}]}],
        'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 80},
      });

      final res = await http.post(Uri.parse('$_geminiUrl?key=$_geminiApiKey'),
          headers: {'Content-Type': 'application/json'}, body: body).timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) return false;

      final json = jsonDecode(res.body);
      final candidates = json['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return false;

      final text = candidates[0]['content']['parts'][0]['text'] as String;
      final result = _parseResponse(text);
      if (result == null) return false;

      return await _fetchAndSetResult(result, 'gemini', onDone);
    } catch (e) {
      return false;
    }
  }

  Future<bool> _identifyWithGroq(File f, VoidCallback onDone) async {
    try {
      final jpeg = await _prepareImage(f);
      final body = jsonEncode({
        'model': _groqModel,
        'messages': [
          {'role': 'user', 'content': [{'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,${base64Encode(jpeg)}'}}, {'type': 'text', 'text': _prompt}]}
        ],
        'temperature': 0.1, 'max_tokens': 80,
      });

      final res = await http.post(Uri.parse(_groqUrl),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_groqApiKey'}, body: body).timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) return false;

      final choices = jsonDecode(res.body)['choices'] as List?;
      if (choices == null || choices.isEmpty) return false;

      final text = choices[0]['message']['content'] as String;
      final result = _parseResponse(text);
      if (result == null) return false;

      return await _fetchAndSetResult(result, 'groq', onDone);
    } catch (e) {
      return false;
    }
  }

  Future<void> _identifyWithLocalModel({required File imageFile, bool fallback = false, required VoidCallback onDone}) async {
    if (_interpreter == null) {
      isAnalyzing = false;
      notifyListeners();
      return;
    }
    try {
      final bytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes)!;
      final resized = img.copyResize(decoded, width: 224, height: 224);

      final input = List.generate(1, (_) => List.generate(224, (y) => List.generate(224, (x) => [
        resized.getPixel(x, y).r / 255.0,
        resized.getPixel(x, y).g / 255.0,
        resized.getPixel(x, y).b / 255.0,
      ])));

      final output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);
      _interpreter!.run(input, output);

      final scores = List<double>.from(output[0]);
      final maxScore = scores.reduce((a, b) => a > b ? a : b);

      // Ngưỡng tối thiểu 40%: dưới mức này coi như ảnh không hợp lệ
      if (maxScore < 0.40) {
        debugPrint('⚠️ Local model confidence quá thấp (${(maxScore*100).toStringAsFixed(1)}%) → NOT_ANIMAL');
        isNotAnimal = true;
        isAnalyzing = false;
        notifyListeners();
        onDone(); // ← Fix bug 2: trigger animation "Ảnh không hợp lệ" khi offline
        return;
      }

      final maxIdx = scores.indexOf(maxScore);
      final confidence = (maxScore * 100).toStringAsFixed(1);
      final breed = _labels[maxIdx];

      await _fetchAndSetResult(
        {'breed': breed, 'nameVi': breed, 'confidence': confidence, 'status': 'OK'},
        fallback ? 'local_fallback' : 'local',
        onDone,
        skipNetwork: !fallback, // offline → skip Supabase; fallback (có mạng nhưng API lỗi) → vẫn query Supabase
      );
    } catch (e) {
      isAnalyzing = false;
      notifyListeners();
    }
  }

  // ── Database & AI Remapping ───────────────────────────────────────────────
  static const _dbBreedsByType = {
    'cat': [
      'Abyssinian', 'Aegean', 'American Bobtail', 'American Curl', 'American Shorthair', 'American Wirehair', 'Aphrodite Giant',
      'Arabian Mau', 'Australian Mist', 'Balinese', 'Bambino', 'Bengal', 'Birman', 'Bombay', 'Brazilian Shorthair', 'British Longhair',
      'British Shorthair', 'Burmese', 'Burmilla', 'California Spangled', 'Chantilly-Tiffany', 'Chartreux', 'Chausie', 'Cheetoh',
      'Colorpoint Shorthair', 'Cornish Rex', 'Cymric', 'Cyprus', 'Devon Rex', 'Donskoy', 'Dragon Li', 'Egyptian Mau', 'European Shorthair',
      'Exotic Shorthair', 'German Rex', 'Havana Brown', 'Highlander', 'Himalayan', 'Japanese Bobtail', 'Javanese', 'Kanaani', 'Khao Manee',
      'Kinkalow', 'Korat', 'Kurilian Bobtail', 'LaPerm', 'Lykoi', 'Maine Coon', 'Manx', 'Mekong Bobtail', 'Minskin', 'Minuet',
      'Munchkin', 'Nebelung', 'Norwegian Forest Cat', 'Ocicat', 'Ojos Azules', 'Oregon Rex', 'Oriental Bicolour', 'Oriental Longhair',
      'Oriental Shorthair', 'Persian', 'Peterbald', 'Pixie-bob', 'Ragamuffin', 'Ragdoll', 'Russian Blue', 'Savannah', 'Scottish Fold', 'Selkirk Rex',
      'Serengeti', 'Siamese', 'Siberian', 'Singapura', 'Snowshoe', 'Sokoke', 'Somali', 'Sphynx', 'Thai', 'Tonkinese', 'Toyger', 'Turkish Angora',
      'Turkish Van', 'Ukranian Levkoy', 'York Chocolate',
    ],
  };

  Future<bool> _fetchAndSetResult(
      Map<String, String> parsed,
      String source,
      VoidCallback onDone, {
        bool skipNetwork = false,
      }) async {
    if (parsed['status'] == 'NOT_ANIMAL') {
      // Ảnh không chứa động vật → báo không hợp lệ, KHÔNG fallback tiếp
      isNotAnimal = true;
      isAnalyzing = false;
      notifyListeners();
      onDone(); // trigger animation hiển thị card "Ảnh không hợp lệ"
      return true; // trả true để startSearching dừng ngay
    }

    final breed = parsed['breed']!;
    final nameVi = parsed['nameVi']!;
    Map<String, dynamic>? animal;

    // Chỉ query Supabase khi có mạng
    if (!skipNetwork) {
      try {
        animal = await _querySupabase('name_english=eq.${Uri.encodeComponent(breed)}');
        animal ??= await _querySupabase('name_english=ilike.${Uri.encodeComponent('%${breed.trim()}%')}');
        if (animal == null && nameVi.isNotEmpty) {
          animal ??= await _querySupabase('name_vietnamese=ilike.${Uri.encodeComponent('%${nameVi.trim()}%')}');
        }

        if (animal == null) {
          final remapped = await _remapBreedWithAI(breed, nameVi);
          if (remapped != null) {
            animal = await _querySupabase('name_english=eq.${Uri.encodeComponent(remapped)}');
          }
        }
      } catch (e) {
        debugPrint('❌ Supabase: $e');
      }
    }

    resultNameVi = animal?['name_vietnamese'] ?? nameVi;
    resultNameEn = animal?['name_english'] ?? breed;
    resultImageUrl = animal?['image_url'];
    resultAnimalId = animal != null ? animal['id'].toString() : null;
    resultConfidence = parsed['confidence'];
    aiSource = source;
    isAnalyzing = false;
    notifyListeners();
    onDone();

    // Lưu lịch sử chỉ khi có mạng
    if (!skipNetwork) {
      _saveHistory(
        nameVi: resultNameVi!,
        nameEn: resultNameEn!,
        confidence: resultConfidence,
        aiSource: aiSource,
        animalId: resultAnimalId,
        animalImageUrl: resultImageUrl,
      );
    }
    return true;
  }

  Future<String?> _remapBreedWithAI(String breed, String nameVi) async {
    try {
      final animalType = _detectAnimalType(breed, nameVi);
      final dbList = _dbBreedsByType[animalType];
      if (dbList == null) return null;

      final prompt = 'The image AI identified a cat as: "$breed" ($nameVi).\nThis name is NOT in the database. Pick the SINGLE closest breed from this list:\n${dbList.join(', ')}\n\nReply with ONLY the exact breed name from the list above. Nothing else.';

      final res = await http.post(
        Uri.parse(_groqUrl),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_groqApiKey'},
        body: jsonEncode({'model': 'llama-3.3-70b-versatile', 'messages': [{'role': 'user', 'content': prompt}], 'temperature': 0.1, 'max_tokens': 20}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final text = (jsonDecode(res.body)['choices'][0]['message']['content'] as String).trim().replaceAll('"', '').replaceAll("'", '');
        for (final b in dbList) {
          if (b.toLowerCase() == text.toLowerCase()) return b;
        }
      }
    } catch (_) {}
    return null;
  }

  String _detectAnimalType(String breed, String nameVi) {
    final s = '${breed.toLowerCase()} ${nameVi.toLowerCase()}';
    if (s.contains('dog') || s.contains('chó') || s.contains('puppy')) return 'dog';
    return 'cat';
  }

  Future<Map<String, dynamic>?> _querySupabase(String filter) async {
    final url = '$_supabaseUrl/rest/v1/animals?$filter&select=id,name_vietnamese,name_english,image_url&limit=1';
    try {
      final res = await http.get(Uri.parse(url), headers: {'apikey': _supabaseKey, 'Authorization': 'Bearer $_supabaseKey'}).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        if (data.isNotEmpty) return data[0] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ── Lịch sử tìm kiếm ─────────────────────────────────────────────────────

  /// Lưu một kết quả vào bảng search_history trên Supabase
  Future<void> _saveHistory({
    required String nameVi,
    required String nameEn,
    String? confidence,
    String? aiSource,
    String? animalId,
    String? animalImageUrl,
  }) async {
    try {
      final url = '$_supabaseUrl/rest/v1/search_history';
      final body = jsonEncode({
        'name_vi': nameVi,
        'name_en': nameEn,
        'confidence': confidence,
        'ai_source': aiSource,
        'animal_id': animalId,
        'animal_image_url': animalImageUrl,
      });
      final res = await http.post(
        Uri.parse(url),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: body,
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 201) {
        // Thêm vào đầu danh sách local luôn (không cần fetch lại)
        final inserted = jsonDecode(res.body) as List;
        if (inserted.isNotEmpty) {
          historyItems.insert(0, SearchHistoryItem.fromJson(inserted[0] as Map<String, dynamic>));
          notifyListeners();
        }
        debugPrint('✅ Đã lưu lịch sử');
      } else {
        debugPrint('❌ Lưu lịch sử thất bại: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('❌ _saveHistory: $e');
    }
  }

  /// Load toàn bộ lịch sử từ Supabase (gọi khi mở màn hình lịch sử)
  Future<void> loadHistory() async {
    if (isLoadingHistory) return;
    isLoadingHistory = true;
    notifyListeners();

    try {
      final url = '$_supabaseUrl/rest/v1/search_history?select=*&order=created_at.desc&limit=100';
      final res = await http.get(
        Uri.parse(url),
        headers: {'apikey': _supabaseKey, 'Authorization': 'Bearer $_supabaseKey'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        historyItems = data.map((e) => SearchHistoryItem.fromJson(e as Map<String, dynamic>)).toList();
        debugPrint('✅ Load ${historyItems.length} lịch sử');
      }
    } catch (e) {
      debugPrint('❌ loadHistory: $e');
    } finally {
      isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Xoá một item lịch sử theo id
  Future<void> deleteHistoryItem(int id) async {
    try {
      final url = '$_supabaseUrl/rest/v1/search_history?id=eq.$id';
      final res = await http.delete(
        Uri.parse(url),
        headers: {'apikey': _supabaseKey, 'Authorization': 'Bearer $_supabaseKey'},
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 204 || res.statusCode == 200) {
        historyItems.removeWhere((e) => e.id == id);
        notifyListeners();
        debugPrint('✅ Đã xoá lịch sử id=$id');
      }
    } catch (e) {
      debugPrint('❌ deleteHistoryItem: $e');
    }
  }

  /// Xoá toàn bộ lịch sử
  Future<void> clearAllHistory() async {
    try {
      // Supabase yêu cầu filter khi DELETE, dùng gte để xoá tất cả
      final url = '$_supabaseUrl/rest/v1/search_history?id=gte.0';
      final res = await http.delete(
        Uri.parse(url),
        headers: {'apikey': _supabaseKey, 'Authorization': 'Bearer $_supabaseKey'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 204 || res.statusCode == 200) {
        historyItems.clear();
        notifyListeners();
        debugPrint('✅ Đã xoá toàn bộ lịch sử');
      }
    } catch (e) {
      debugPrint('❌ clearAllHistory: $e');
    }
  }
}