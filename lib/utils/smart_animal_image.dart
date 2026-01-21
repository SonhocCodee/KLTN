import 'package:flutter/material.dart';
import '../utils/image_processor.dart';

class SmartAnimalImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SmartAnimalImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<SmartAnimalImage> createState() => _SmartAnimalImageState();
}

class _SmartAnimalImageState extends State<SmartAnimalImage> {
  Alignment _alignment = Alignment.center;
  bool _isAnalyzing = true;

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  @override
  void didUpdateWidget(SmartAnimalImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    setState(() => _isAnalyzing = true);

    // Strategy 1: Quick focal point từ URL
    final focalPoint = ImageProcessor.getFocalPoint(widget.imageUrl);

    setState(() {
      _alignment = focalPoint;
      _isAnalyzing = false;
    });

    // Strategy 2: Deep analysis (background task, không block UI)
    // Uncomment dòng dưới nếu muốn phân tích sâu hơn
    // final detectedAlignment = await ImageProcessor.detectAnimalPosition(widget.imageUrl);
    // if (mounted) {
    //   setState(() => _alignment = detectedAlignment);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isAnalyzing
          ? (widget.placeholder ??
          Container(
            color: Colors.grey[800],
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ))
          : Image.network(
        widget.imageUrl,
        fit: widget.fit,
        alignment: _alignment, // ⭐ KEY: Dùng alignment động
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
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
          return widget.errorWidget ??
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
      ),
    );
  }
}