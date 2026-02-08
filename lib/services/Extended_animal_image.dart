// File: services/extended_animal_image.dart
import 'package:flutter/material.dart';
import 'dart:convert'; // Import để decode base64 nếu cần
import '../services/extended_image_cache.dart';
import '../utils/smart_animal_image.dart';
import 'Clipdrop image service.dart';

class ExtendedAnimalImage extends StatefulWidget {
  final String originalImageUrl;
  final String animalName;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const ExtendedAnimalImage({
    super.key,
    required this.originalImageUrl,
    required this.animalName,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  State<ExtendedAnimalImage> createState() => _ExtendedAnimalImageState();
}

class _ExtendedAnimalImageState extends State<ExtendedAnimalImage> {
  String? _displayImageUrl;
  bool _isProcessing = true;
  bool _isExtended = false;
  String? _error;
  String? _usedService;

  // ❌ ĐÃ XÓA DÒNG GÂY LỖI: get ClipDropImageService => null;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(ExtendedAnimalImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.originalImageUrl != widget.originalImageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _error = null;
      _isExtended = false;
      _usedService = null;
    });

    print('🎨 Loading image for: ${widget.animalName}');

    try {
      // BƯỚC 1: Check cache
      final cachedUrl = await ExtendedImageCache.getExtendedImage(
        widget.originalImageUrl,
      );

      if (cachedUrl != null) {
        print('💾 Using cached extended image');
        if (mounted) {
          setState(() {
            _displayImageUrl = cachedUrl;
            _isExtended = true;
            _isProcessing = false;
            _usedService = 'cache';
          });
        }
        return;
      }

      // BƯỚC 2: Thử ClipDrop trước (Vì Replicate đang hết tiền)
      print('🚀 Trying ClipDrop API...');
      final clipDropUrl = await ClipDropImageService.extendAnimalImage(
        originalImageUrl: widget.originalImageUrl,
      );

      if (clipDropUrl != null && clipDropUrl.isNotEmpty) {
        print('✅ ClipDrop succeeded!');
        await _saveAndDisplay(clipDropUrl, 'clipdrop');
        return;
      }





      // BƯỚC 4: Fallback về ảnh gốc
      print('⚠️ All AI services failed, using original image');
      if (mounted) {
        setState(() {
          _displayImageUrl = widget.originalImageUrl;
          _isExtended = false;
          _isProcessing = false;
          _usedService = 'original';
          _error = 'AI processing unavailable';
        });
      }

    } catch (e, stackTrace) {
      print('❌ Error loading image: $e');
      print('   Stack: $stackTrace');

      if (mounted) {
        setState(() {
          _displayImageUrl = widget.originalImageUrl;
          _isExtended = false;
          _isProcessing = false;
          _usedService = 'original';
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _saveAndDisplay(String url, String service) async {
    // Lưu cache (Lưu ý: DataURI khá dài, SharedPreferences có thể bị đầy nếu lưu nhiều)
    // Với ClipDrop trả về Base64 dài, bạn nên cân nhắc lưu file local thay vì lưu chuỗi vào SharedPref
    // Nhưng để test nhanh thì cứ lưu tạm.

    if (url.length < 1000000) { // Chỉ cache nếu chuỗi không quá lớn (<1MB)
      await ExtendedImageCache.saveExtendedImage(
        originalUrl: widget.originalImageUrl,
        extendedUrl: url,
      );
    }

    if (mounted) {
      setState(() {
        _displayImageUrl = url;
        _isExtended = true;
        _isProcessing = false;
        _usedService = service;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return widget.loadingWidget ?? _buildLoadingWidget();
    }

    if (_displayImageUrl == null) {
      return widget.errorWidget ?? _buildErrorWidget();
    }

    // Xử lý hiển thị ảnh Base64 hoặc URL thường
    ImageProvider imageProvider;
    if (_displayImageUrl!.startsWith('data:image')) {
      // Xử lý Base64 Data URI
      final base64String = _displayImageUrl!.split(',').last;
      imageProvider = MemoryImage(base64Decode(base64String));
    } else {
      // URL thường
      imageProvider = NetworkImage(_displayImageUrl!);
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Image(
            image: imageProvider,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => _buildErrorWidget(),
          ),
        ),

        // Gradient che mờ nếu cần thiết để text dễ đọc
        if (_isExtended)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.1), // Overlay nhẹ
            ),
          ),

        // Badge Service
        if (_usedService != null && _usedService != 'cache')
          Positioned(
            top: 60,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getBadgeColor(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getBadgeIcon(), size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    _getBadgeText(),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ... (Giữ nguyên các hàm _getBadgeColor, _getBadgeIcon, _buildLoadingWidget...)

  Color _getBadgeColor() {
    switch (_usedService) {
      case 'replicate': return Colors.green.withOpacity(0.9);
      case 'clipdrop': return Colors.blue.withOpacity(0.9);
      case 'original': return Colors.orange.withOpacity(0.9);
      default: return Colors.grey.withOpacity(0.9);
    }
  }

  IconData _getBadgeIcon() {
    switch (_usedService) {
      case 'replicate': return Icons.auto_awesome;
      case 'clipdrop': return Icons.crop_free;
      case 'original': return Icons.info_outline;
      default: return Icons.image;
    }
  }

  String _getBadgeText() {
    switch (_usedService) {
      case 'replicate': return 'Replicate AI';
      case 'clipdrop': return 'ClipDrop AI';
      case 'original': return 'Original image';
      default: return 'Unknown';
    }
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: const Color(0xFF1a1a2e),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            const Text('Đang xử lý ảnh (ClipDrop)...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, color: Colors.white54, size: 50),
            TextButton(onPressed: _loadImage, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}