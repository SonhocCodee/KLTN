import 'package:flutter/material.dart';

class SmartAnimalImage extends StatelessWidget {
  final String imageUrl;
  final String? animalName;
  final bool isExtendedImage;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SmartAnimalImage({
    super.key,
    required this.imageUrl,
    this.animalName,
    this.isExtendedImage = false,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = _getAlignment();

    return Image.network(
      imageUrl,
      fit: fit,
      alignment: alignment,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return placeholder ??
            Container(
              color: Colors.grey[800],
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ??
            Container(
              color: Colors.grey[800],
              child: const Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 64,
                  color: Colors.white54,
                ),
              ),
            );
      },
    );
  }

  /// Tính alignment dựa vào tên động vật và loại ảnh
  Alignment _getAlignment() {
    // Ảnh đã extend bởi AI → Con vật đã ở center-bottom
    if (isExtendedImage) {
      return const Alignment(0, 0.3);
    }

    // Ảnh gốc → Dùng preset theo tên động vật
    if (animalName != null) {
      return _getPresetAlignment(animalName!);
    }

    // Fallback
    return const Alignment(0, 0.2);
  }

  /// Preset alignment cho từng loại động vật
  Alignment _getPresetAlignment(String animalName) {
    final normalized = animalName.toLowerCase().trim();

    final presets = {
      // Birds - thường ở trên
      'eagle': const Alignment(0, -0.2),
      'penguin': Alignment.center,

      // Big cats - center hoặc hơi lên
      'lion': const Alignment(0, 0.1),
      'tiger': const Alignment(0, 0.1),
      'cheetah': Alignment.center,
      'leopard': const Alignment(0, 0.1),
      'jaguar': const Alignment(0, 0.1),

      // Large animals
      'elephant': Alignment.center,
      'giraffe': const Alignment(0, -0.15), // Cao nên lên trên
      'rhino': const Alignment(0, 0.1),
      'hippo': const Alignment(0, 0.1),
      'zebra': Alignment.center,

      // Medium animals
      'bear': Alignment.center,
      'wolf': const Alignment(0, 0.1),
      'gorilla': const Alignment(0, 0.1),

      // Small/unique animals
      'kangaroo': Alignment.center,
      'koala': const Alignment(0, -0.1),
      'panda': Alignment.center,

      // Marine animals
      'dolphin': Alignment.center,
      'shark': Alignment.center,
    };

    return presets[normalized] ?? const Alignment(0, 0.2);
  }
}