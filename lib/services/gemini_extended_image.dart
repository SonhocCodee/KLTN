import 'dart:convert';

import 'package:flutter/material.dart';
import '../services/gemini_image_service.dart';

/// Widget chuyên dụng để hiển thị ảnh động vật đã extend bởi Gemini
class GeminiExtendedImage extends StatefulWidget {
  final String originalImageUrl;
  final String animalName;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const GeminiExtendedImage({
    super.key,
    required this.originalImageUrl,
    required this.animalName,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  State<GeminiExtendedImage> createState() => _GeminiExtendedImageState();
}

class _GeminiExtendedImageState extends State<GeminiExtendedImage> {
  String? _extendedImageUrl;
  bool _isProcessing = true;
  String? _error;
  bool _useOriginalAsFallback = false;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  @override
  void didUpdateWidget(GeminiExtendedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.originalImageUrl != widget.originalImageUrl) {
      _processImage();
    }
  }

  Future<void> _processImage() async {
    setState(() {
      _isProcessing = true;
      _error = null;
      _useOriginalAsFallback = false;
    });

    print('🖼️ Processing image for: ${widget.animalName}');

    // TODO: Check cache trước
    // final cached = await ImageCache.getExtendedImage(widget.originalImageUrl);
    // if (cached != null) { ... }

    // Gọi Gemini để extend
    final extendedUrl = await GeminiImageService.extendAnimalImage(
      originalImageUrl: widget.originalImageUrl,
      animalName: widget.animalName,
    );

    if (mounted) {
      if (extendedUrl != null) {
        setState(() {
          _extendedImageUrl = extendedUrl;
          _isProcessing = false;
        });
        print('✅ Extended image ready!');
      } else {
        // Fallback: dùng ảnh gốc
        setState(() {
          _extendedImageUrl = widget.originalImageUrl;
          _isProcessing = false;
          _useOriginalAsFallback = true;
          _error = 'Gemini processing failed';
        });
        print('⚠️ Using original image as fallback');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return widget.loadingWidget ?? _buildLoadingWidget();
    }

    if (_extendedImageUrl == null) {
      return widget.errorWidget ?? _buildErrorWidget();
    }

    return Stack(
      children: [
        // Main image
        Positioned.fill(
          child: _extendedImageUrl!.startsWith('data:image')
              ? _buildBase64Image(_extendedImageUrl!)
              : _buildNetworkImage(_extendedImageUrl!),
        ),

        // Warning badge nếu dùng ảnh gốc
        if (_useOriginalAsFallback)
          Positioned(
            top: 60,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'Original Image',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1a1a2e),
            const Color(0xFF16213e),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Đang xử lý ảnh với AI...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gemini đang mở rộng ảnh ${widget.animalName}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            // Progress dots animation
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.3 + (value * 0.7)),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: const Color(0xFF1a1a2e),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Không thể xử lý ảnh',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _processImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBase64Image(String dataUrl) {
    // Parse data:image/jpeg;base64,/9j/4AAQ...
    final base64Data = dataUrl.split(',')[1];
    final bytes = base64Decode(base64Data);

    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      alignment: const Alignment(0, 0.3), // Con vật ở giữa-dưới
    );
  }

  Widget _buildNetworkImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      alignment: const Alignment(0, 0.3), // Con vật ở giữa-dưới
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingWidget();
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorWidget();
      },
    );
  }
}

// ==========================================
// File: lib/screens/home/daily_fact_screen.dart (UPDATED)
// ==========================================
/*
CẬP NHẬT daily_fact_screen.dart:

1. Import widget:
import '../../widgets/gemini_extended_image.dart';

2. Thay thế phần background image:

TỪ:
Positioned.fill(
  child: Image.network(
    _todayFact!.imageUrl,
    fit: BoxFit.cover,
    ...
  ),
),

SANG:
Positioned.fill(
  child: GeminiExtendedImage(
    originalImageUrl: _todayFact!.imageUrl,
    animalName: _todayFact!.englishName,
  ),
),

3. Test API key trong initState (optional):
@override
void initState() {
  super.initState();
  _controller = AnimationController(...);

  // Validate Gemini API key
  GeminiImageService.validateApiKey().then((isValid) {
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Gemini API key chưa được cấu hình!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  });

  _loadTodayAnimal();
}
*/

// ==========================================
// CHECKLIST SETUP
// ==========================================
/*
☐ 1. Lấy Gemini API key:
   - Vào https://aistudio.google.com/app/apikey
   - Create API key
   - Copy key

☐ 2. Paste API key vào code:
   - Mở file: lib/services/gemini_image_service.dart
   - Tìm dòng: static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';
   - Thay 'YOUR_GEMINI_API_KEY_HERE' bằng key của bạn

☐ 3. Tạo file mới:
   - lib/services/gemini_image_service.dart
   - lib/widgets/gemini_extended_image.dart

☐ 4. Update daily_fact_screen.dart:
   - Import GeminiExtendedImage
   - Thay Image.network → GeminiExtendedImage

☐ 5. Test:
   - flutter run
   - Mở Daily Fact
   - Chờ AI processing (~5-10s)
   - Xem ảnh extended full screen

☐ 6. (Optional) Setup cache:
   - Lưu ảnh extended để không phải xử lý lại
   - Dùng Supabase Storage hoặc SharedPreferences
*/