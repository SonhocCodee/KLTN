import 'package:flutter/material.dart';
import 'smart_animal_image.dart';

class AnimalImageViewer extends StatefulWidget {
  final String imageUrl;
  final bool enablePan;
  final bool enableZoom;

  const AnimalImageViewer({
    super.key,
    required this.imageUrl,
    this.enablePan = true,
    this.enableZoom = false,
  });

  @override
  State<AnimalImageViewer> createState() => _AnimalImageViewerState();
}

class _AnimalImageViewerState extends State<AnimalImageViewer> {
  final TransformationController _transformationController =
  TransformationController();

  Offset _offset = Offset.zero;
  double _scale = 1.0;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enablePan && !widget.enableZoom) {
      // Simple mode - chỉ hiển thị
      return SmartAnimalImage(
        imageUrl: widget.imageUrl,
        fit: BoxFit.cover,
      );
    }

    // Interactive mode
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 1.0,
      maxScale: 3.0,
      panEnabled: widget.enablePan,
      scaleEnabled: widget.enableZoom,
      boundaryMargin: const EdgeInsets.all(20),
      child: SmartAnimalImage(
        imageUrl: widget.imageUrl,
        fit: BoxFit.cover,
      ),
    );
  }
}