import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'image_processor.dart';

class ImageAlignmentPresets {
  static const Map<String, Alignment> animalPresets = {
    // Birds - thường ở trên
    'eagle': Alignment(0, -0.2),
    'penguin': Alignment(0, 0),

    // Big cats - thường center hoặc hơi lên
    'lion': Alignment(0, -0.1),
    'tiger': Alignment(0, -0.1),
    'cheetah': Alignment(0, 0),
    'leopard': Alignment(0, -0.1),
    'jaguar': Alignment(0, -0.1),

    // Large animals - thường center
    'elephant': Alignment(0, 0),
    'giraffe': Alignment(0, -0.15), // Cao, nên lên trên
    'rhino': Alignment(0, 0.1),
    'hippo': Alignment(0, 0.1),

    // Medium animals
    'bear': Alignment(0, 0),
    'wolf': Alignment(0, -0.1),
    'gorilla': Alignment(0, -0.1),

    // Small/unique animals
    'kangaroo': Alignment(0, 0),
    'koala': Alignment(0, -0.2),
    'panda': Alignment(0, 0),

    // Marine animals - thường center
    'dolphin': Alignment(0, 0),
    'shark': Alignment(0, 0),

    // Others
    'zebra': Alignment(0, 0),
  };

  static Alignment getAlignment(String animalName) {
    final normalized = animalName.toLowerCase().trim();
    return animalPresets[normalized] ?? Alignment.center;
  }
}

// ==========================================
// UPDATED: SmartAnimalImage với Presets
// ==========================================
class SmartAnimalImageWithPresets extends StatefulWidget {
  final String imageUrl;
  final String? animalName; // Thêm tên động vật
  final BoxFit fit;

  const SmartAnimalImageWithPresets({
    super.key,
    required this.imageUrl,
    this.animalName,
    this.fit = BoxFit.cover,
  });

  @override
  State<SmartAnimalImageWithPresets> createState() =>
      _SmartAnimalImageWithPresetsState();
}

class _SmartAnimalImageWithPresetsState
    extends State<SmartAnimalImageWithPresets> {

  late Alignment _alignment;

  @override
  void initState() {
    super.initState();
    _determineAlignment();
  }

  void _determineAlignment() {
    // Priority 1: Preset từ tên động vật
    if (widget.animalName != null) {
      _alignment = ImageAlignmentPresets.getAlignment(widget.animalName!);
      return;
    }

    // Priority 2: Phân tích URL
    _alignment = ImageProcessor.getFocalPoint(widget.imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Image.network(
      widget.imageUrl,
      fit: widget.fit,
      alignment: _alignment,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[800],
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[800],
          child: const Center(
            child: Icon(Icons.image_not_supported, size: 64, color: Colors.white54),
          ),
        );
      },
    );
  }
}

// USAGE trong Daily Fact Screen:

/*
Positioned.fill(
  child: SmartAnimalImageWithPresets(
    imageUrl: _todayFact!.imageUrl,
    animalName: _todayFact!.englishName, // Pass tên tiếng Anh
    fit: BoxFit.cover,
  ),
),
*/