import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'dart:io';

class IdentifyScreen extends StatefulWidget {
  const IdentifyScreen({super.key});

  @override
  State<IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends State<IdentifyScreen> {
  static const _primaryGreen = Color(0xFF34D399);

  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  File? _selectedImage;
  String _resultText = "";

  Interpreter? _interpreter;
  List<String> _labels = [];

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    debugPrint("🔄 Bắt đầu load model...");
    try {
      debugPrint("📂 Đang load tflite...");
      _interpreter = await Interpreter.fromAsset('assets/cat_classifier.tflite');
      debugPrint("✅ Interpreter OK");
      final raw = await rootBundle.loadString('assets/labels.txt');
      _labels = raw.trim().split('\n');
      debugPrint("✅ Model loaded, ${_labels.length} loài");
    } catch (e, stackTrace) {
      debugPrint("❌ Lỗi chi tiết: $e");
      debugPrint("❌ Stack: $stackTrace");
    }
  }
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _resultText = "";
        });
      }
    } catch (e) {
      debugPrint("Lỗi chọn ảnh: $e");
    }
  }

  Future<void> _startSearching() async {
    if (_selectedImage == null) {
      debugPrint("❌ Chưa chọn ảnh");
      return;
    }
    if (_interpreter == null) {
      debugPrint("❌ Model chưa load xong");
      setState(() { _resultText = "Lỗi: Model chưa sẵn sàng, thử lại!"; });
      return;
    }

    try {
      // Đọc và resize ảnh về 224x224
      final bytes = await _selectedImage!.readAsBytes();
      final decoded = img.decodeImage(bytes)!;
      final resized = img.copyResize(decoded, width: 224, height: 224);

      // Tạo input tensor [1, 224, 224, 3]
      final input = List.generate(1, (_) =>
          List.generate(224, (y) =>
              List.generate(224, (x) => [
                resized.getPixel(x, y).r / 255.0,
                resized.getPixel(x, y).g / 255.0,
                resized.getPixel(x, y).b / 255.0,
              ])
          )
      );

      // Tạo output tensor
      final output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);
      _interpreter!.run(input, output);

      // Lấy loài có xác suất cao nhất
      final scores = List<double>.from(output[0]);
      final maxIdx = scores.indexOf(scores.reduce((a, b) => a > b ? a : b));
      final confidence = (scores[maxIdx] * 100).toStringAsFixed(1);
      final result = "${_labels[maxIdx]} ($confidence%)";

      // Gọi Supabase nếu cần
      await _fetchAnimalFromSupabase(_labels[maxIdx]);

      setState(() {
        _resultText = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _resultText = "Lỗi nhận diện: $e";
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _fetchAnimalFromSupabase(String animalName) async {
    debugPrint("Tìm thấy: $animalName. Chuẩn bị chuyển trang...");
    // TODO: gọi Supabase ở đây
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Giữ nguyên toàn bộ UI của bạn
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Nhận Diện',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                  const Text('Chụp hoặc tải ảnh để nhận diện động vật',
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                  const SizedBox(height: 24),
                  Expanded(child: _buildImageFrame()),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildOptionCard(
                        icon: CupertinoIcons.camera_fill, label: 'Chụp ảnh',
                        gradient: const [Color(0xFF818CF8), Color(0xFF6366F1)],
                        onTap: () => _pickImage(ImageSource.camera),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _buildOptionCard(
                        icon: CupertinoIcons.photo_on_rectangle, label: 'Thư viện',
                        gradient: const [Color(0xFF818CF8), Color(0xFF6366F1)],
                        onTap: () => _pickImage(ImageSource.gallery),
                      )),
                    ],
                  ),
                  if (_selectedImage != null) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _startSearching,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.search, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Tìm kiếm loài vật',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isAnalyzing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _primaryGreen),
                    SizedBox(height: 16),
                    Text('Đang phân tích hình ảnh...',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageFrame() {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _primaryGreen.withOpacity(0.3), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: _selectedImage != null
          ? Stack(fit: StackFit.expand, children: [
        Image.file(_selectedImage!, fit: BoxFit.cover),
        Positioned(top: 12, right: 12,
          child: GestureDetector(
            onTap: () => setState(() { _selectedImage = null; _resultText = ""; }),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.clear, color: Colors.white, size: 20),
            ),
          ),
        ),
        if (!_isAnalyzing && _resultText.isNotEmpty)
          Positioned(bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                ),
              ),
              child: Text("Kết quả: $_resultText", textAlign: TextAlign.center,
                  style: const TextStyle(color: _primaryGreen, fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ),
      ])
          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(CupertinoIcons.photo, color: _primaryGreen, size: 40),
        ),
        const SizedBox(height: 16),
        const Text('Chưa có ảnh nào', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        const Text('Vui lòng chụp hoặc tải ảnh từ thư viện', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
      ]),
    );
  }

  Widget _buildOptionCard({required IconData icon, required String label, required List<Color> gradient, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: gradient[0].withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

