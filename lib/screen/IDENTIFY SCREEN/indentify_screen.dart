import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import file service và các widgets con
import '../Animal_detail/Animal detail screen.dart';
import 'identify_service.dart';
import 'widgets/identify_header.dart';
import 'widgets/identify_image_frame.dart';
import 'widgets/identify_action_buttons.dart';
import 'widgets/identify_result_section.dart';
import 'widgets/identify_loading_overlay.dart';
import '../home/animal_category_model.dart';

class IdentifyScreen extends StatelessWidget {
  const IdentifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => IdentifyService()..loadModel(),
      child: const IdentifyView(),
    );
  }
}

class IdentifyView extends StatefulWidget {
  const IdentifyView({super.key});

  @override
  State<IdentifyView> createState() => _IdentifyViewState();
}

class _IdentifyViewState extends State<IdentifyView> with SingleTickerProviderStateMixin {
  late AnimationController _cardAnimCtrl;
  late Animation<double> _cardFadeAnim;
  late Animation<Offset> _cardSlideAnim;

  @override
  void initState() {
    super.initState();
    _cardAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardFadeAnim = CurvedAnimation(parent: _cardAnimCtrl, curve: Curves.easeOut);
    _cardSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardAnimCtrl, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _cardAnimCtrl.dispose();
    super.dispose();
  }

  void _openDetail(String? resultAnimalId) {
    if (resultAnimalId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnimalDetailScreen(
          animalId: resultAnimalId,
          category: _buildCatCategory(),
        ),
      ),
    );
  }

  AnimalCategory _buildCatCategory() {
    return AnimalCategory.getById('cat') ??
        AnimalCategory(
          id: 'cat', nameVi: 'Mèo', nameEn: 'Cat',
          icon: Icons.pets, gradient: [const Color(0xFFEC4899), const Color(0xFFDB2777)],
          imageAssetPath: 'assets/animals/cat.jpg', totalExpected: 73,
        );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<IdentifyService>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          SafeArea(
            // CHỦ CHỐT: bottom: false để tránh vệt trắng và cho phép màu nền tràn xuống đáy
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IdentifyHeader(service: service),
                Expanded(
                  child: SingleChildScrollView(
                    // CHỦ CHỐT: padding bottom 120 để nội dung kết quả luôn nằm trên Navbar
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        IdentifyImageFrame(
                          selectedImage: service.selectedImage,
                          onClear: () {
                            service.clearImage();
                            _cardAnimCtrl.reset();
                          },
                        ),
                        const SizedBox(height: 24),
                        IdentifyActionButtons(
                          service: service,
                          onSearch: () => service.startSearching(() => _cardAnimCtrl.forward()),
                        ),
                        const SizedBox(height: 24),
                        IdentifyResultSection(
                          service: service,
                          fadeAnim: _cardFadeAnim,
                          slideAnim: _cardSlideAnim,
                          onOpenDetail: () => _openDetail(service.resultAnimalId),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          IdentifyLoadingOverlay(service: service),
        ],
      ),
    );
  }
}