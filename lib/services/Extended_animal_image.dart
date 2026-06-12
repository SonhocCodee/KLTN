// Widget hiển thị ảnh động vật với flow:
// 1. Kiểm tra SharedImageCacheService (Supabase Storage) -> dùng nếu có
// 2. Tải ảnh gốc -> gọi ClipDrop extend
// 3. Upload kết quả lên Supabase Storage (SharedImageCacheService)
// 4. Người dùng tiếp theo đọc thẳng từ Supabase -> không cần gọi ClipDrop nữa
// Lưu ý: Base64 từ ClipDrop KHÔNG được lưu SharedPreferences (quá lớn).
// Thay vào đó upload lên Supabase Storage và lưu public URL.

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'Clipdrop image service.dart';
import 'shared_image_cache_service.dart';

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
  String? _displayImageUrl; // URL hoặc 'data:image/...' base64
  bool _isProcessing = true;
  bool _isExtended = false;
  String? _usedService;

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

  // Luồng xử lý chính
  Future<void> _loadImage() async {
    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _usedService = null;
      _isExtended = false;
    });

    print('🖼️ [ExtImage] Loading: ${widget.animalName}');

    try {
      // Kiểm tra Supabase shared cache (URL công khai)
      final sharedUrl = await SharedImageCacheService.getSharedCachedImage(
        widget.originalImageUrl,
      );

      if (sharedUrl != null && sharedUrl.isNotEmpty) {
        print('✅ [ExtImage] Dùng Supabase shared cache');
        _setDisplay(sharedUrl, 'supabase_cache', extended: true);
        return;
      }

      // Nếu URL là data URI (đã extended trước đó)
      if (widget.originalImageUrl.startsWith('data:image')) {
        _setDisplay(widget.originalImageUrl, 'local_base64', extended: true);
        return;
      }

      // Gọi ClipDrop
      print('🚀 [ExtImage] Gọi ClipDrop API...');
      final clipDropResult = await ClipDropImageService.extendAnimalImage(
        originalImageUrl: widget.originalImageUrl,
      );

      if (clipDropResult != null && clipDropResult.isNotEmpty) {
        print('✅ [ExtImage] ClipDrop thành công');

        // Upload kết quả lên Supabase Storage để share cho mọi người
        if (clipDropResult.startsWith('data:image')) {
          final base64Str = clipDropResult.split(',').last;
          final bytes = base64Decode(base64Str);
          await _uploadToSharedCache(bytes);
        }

        _setDisplay(clipDropResult, 'clipdrop', extended: true);
        return;
      }

      // Dự phòng ảnh gốc
      print('⚠️ [ExtImage] Fallback về ảnh gốc');
      _setDisplay(widget.originalImageUrl, 'original', extended: false);
    } catch (e) {
      print('❌ [ExtImage] Error: $e');
      _setDisplay(widget.originalImageUrl, 'original', extended: false);
    }
  }

  // Upload ảnh lên Supabase Storage và lưu URL vào shared cache
  Future<void> _uploadToSharedCache(Uint8List bytes) async {
    try {
      final publicUrl = await SharedImageCacheService.uploadAndSaveSharedCache(
        originalImageUrl: widget.originalImageUrl,
        imageBytes: bytes,
        animalName: widget.animalName,
      );
      if (publicUrl != null) {
        print('☁️ [ExtImage] Đã upload lên Supabase: $publicUrl');
        // Cập nhật display sang URL public luôn (thay thế base64)
        if (mounted) {
          setState(() {
            _displayImageUrl = publicUrl;
          });
        }
      }
    } catch (e) {
      print('⚠️ [ExtImage] Upload Supabase thất bại: $e');
    }
  }

  void _setDisplay(String url, String service, {required bool extended}) {
    if (!mounted) return;
    setState(() {
      _displayImageUrl = url;
      _usedService = service;
      _isExtended = extended;
      _isProcessing = false;
    });
  }

  // Dựng giao diện
  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return widget.loadingWidget ?? _buildLoading();
    }

    if (_displayImageUrl == null) {
      return widget.errorWidget ?? _buildError();
    }

    // Chọn ImageProvider phù hợp
    final ImageProvider imgProvider;
    if (_displayImageUrl!.startsWith('data:image')) {
      final b64 = _displayImageUrl!.split(',').last;
      imgProvider = MemoryImage(base64Decode(b64));
    } else {
      imgProvider = NetworkImage(_displayImageUrl!);
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Image(
            image: imgProvider,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildError(),
          ),
        ),

        // Overlay nhẹ khi ảnh đã được extend
        if (_isExtended)
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.05)),
          ),
      ],
    );
  }

  Widget _buildLoading() {
    return Container(
      color: const Color(0xFF0F172A),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 12),
            Text(
              'Đang xử lý ảnh...',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, color: Colors.white38, size: 56),
            const SizedBox(height: 12),
            const Text(
              'Không tải được ảnh',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _loadImage,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Thử lại',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
