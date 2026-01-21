import 'package:flutter/material.dart';
import '../services/mage_extension_service.dart';
import '../utils/image_display_helper.dart';

/// Widget hiển thị ảnh động vật đã được AI extend
///
/// Flow:
/// 1. Nhận originalImageUrl từ Wikipedia
/// 2. Gọi AI để extend (nếu chưa có cache)
/// 3. Hiển thị ảnh extended với alignment đúng
class ExtendedAnimalImage extends StatefulWidget {
  final String originalImageUrl;
  final String animalName;
  final bool useLocalAI;
  final String? localAIEndpoint;

  const ExtendedAnimalImage({
    super.key,
    required this.originalImageUrl,
    required this.animalName,
    this.useLocalAI = false,
    this.localAIEndpoint,
  });

  @override
  State<ExtendedAnimalImage> createState() => _ExtendedAnimalImageState();
}

class _ExtendedAnimalImageState extends State<ExtendedAnimalImage> {
  String? _extendedImageUrl;
  bool _isProcessing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    print('🖼️ Bắt đầu xử lý ảnh cho: ${widget.animalName}');

    // TODO: Check cache trước (lưu trong Supabase Storage hoặc local)
    // final cached = await ImageCache.getExtendedImage(widget.originalImageUrl);
    // if (cached != null) {
    //   setState(() {
    //     _extendedImageUrl = cached;
    //     _isProcessing = false;
    //   });
    //   return;
    // }

    // Gọi AI để extend
    final extendedUrl = await ImageExtensionService.extendImage(
      originalImageUrl: widget.originalImageUrl,
      useLocalAI: widget.useLocalAI,
      localAIEndpoint: widget.localAIEndpoint,
    );

    if (extendedUrl != null) {
      // TODO: Cache lại kết quả
      // await ImageCache.saveExtendedImage(widget.originalImageUrl, extendedUrl);

      setState(() {
        _extendedImageUrl = extendedUrl;
        _isProcessing = false;
      });

      print('✅ Xử lý xong! URL mới: $extendedUrl');
    } else {
      // Fallback: dùng ảnh gốc nếu AI fail
      setState(() {
        _extendedImageUrl = widget.originalImageUrl;
        _isProcessing = false;
        _error = 'AI processing failed, using original image';
      });

      print('⚠️ AI fail, dùng ảnh gốc');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[900]!,
              Colors.grey[800]!,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                'Đang xử lý ảnh với AI...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mở rộng ảnh để full màn hình',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_extendedImageUrl == null) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Icon(Icons.error, size: 64, color: Colors.white54),
        ),
      );
    }

    // Tính alignment dựa vào việc ảnh đã extend hay chưa
    final isExtended = _extendedImageUrl != widget.originalImageUrl;
    final alignment = ImageDisplayHelper.getAnimalAlignment(
      animalName: widget.animalName,
      isExtendedImage: isExtended,
    );

    final screenSize = MediaQuery.of(context).size;
    final boxFit = ImageDisplayHelper.getOptimalFit(
      isExtendedImage: isExtended,
      screenWidth: screenSize.width,
      screenHeight: screenSize.height,
    );

    return Stack(
      children: [
        // Main Image
        Positioned.fill(
          child: Image.network(
            _extendedImageUrl!,
            fit: boxFit,
            alignment: alignment, // ⭐ KEY: Alignment động
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;

              return Container(
                color: Colors.grey[800],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                        : null,
                    color: Colors.white,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[900],
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: Colors.white54,
                  ),
                ),
              );
            },
          ),
        ),

        // Debug overlay (chỉ hiện khi dev)
        if (_error != null)
          Positioned(
            bottom: 80,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}