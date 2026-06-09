import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../language/Locale_provider.dart';
import 'animal_detail_utils.dart';

class AnimalDetailVideo extends StatefulWidget {
  final Map<String, dynamic> animal;

  const AnimalDetailVideo({super.key, required this.animal});

  static String videoUrlOf(Map<String, dynamic> animal) {
    final raw = animal['video'] ?? animal['video_url'];
    if (raw == null) return '';
    return raw.toString().trim();
  }

  static bool hasVideo(Map<String, dynamic> animal) =>
      videoUrlOf(animal).isNotEmpty;

  @override
  State<AnimalDetailVideo> createState() => _AnimalDetailVideoState();
}

class _AnimalDetailVideoState extends State<AnimalDetailVideo> {
  VideoPlayerController? _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant AnimalDetailVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (AnimalDetailVideo.videoUrlOf(oldWidget.animal) !=
        AnimalDetailVideo.videoUrlOf(widget.animal)) {
      _disposeController();
      _hasError = false;
      _initVideo();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  Future<void> _initVideo() async {
    final videoUrl = AnimalDetailVideo.videoUrlOf(widget.animal);
    if (videoUrl.isEmpty) return;

    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    _controller = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (mounted) setState(() {});
    } catch (_) {
      await controller.dispose();
      if (mounted) {
        setState(() {
          _controller = null;
          _hasError = true;
        });
      }
    }
  }

  void _disposeController() {
    final controller = _controller;
    _controller = null;
    controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoUrl = AnimalDetailVideo.videoUrlOf(widget.animal);
    final controller = _controller;

    if (videoUrl.isEmpty || _hasError) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();
    final initialized = controller?.value.isInitialized == true;
    final aspectRatio = initialized ? controller!.value.aspectRatio : 16 / 9;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimalDetailUtils.buildSectionTitle(
          t.tr('Video 360 độ'),
          '🎥',
          colorScheme,
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            color: Colors.black,
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: initialized
                  ? VideoPlayer(controller!)
                  : Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                        strokeWidth: 2.5,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
