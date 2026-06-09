import 'package:flutter/material.dart';
import 'package:kltn_app/screen/IDENTIFY%20SCREEN/service/Identify_service.dart';
import 'package:provider/provider.dart';

import '../Animal_detail/Animal detail screen.dart';

import '../language/Locale_provider.dart';
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

  /// Callback sau khi phân tích xong (cả thành công lẫn NOT_ANIMAL đều cần animate)
  void _onSearchDone() {
    _cardAnimCtrl.forward(from: 0);
  }

  void _openDetail(String? resultAnimalId, LocaleProvider t) {
    if (resultAnimalId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnimalDetailScreen(
          animalId: resultAnimalId,
          category: _buildCatCategory(t),
        ),
      ),
    );
  }

  AnimalCategory _buildCatCategory(LocaleProvider t) {
    return AnimalCategory.getById('cat') ??
        AnimalCategory(
          id: 'cat', nameVi: t.tr('Mèo'), nameEn: 'Cat',
          icon: Icons.pets, gradient: [const Color(0xFFEC4899), const Color(0xFFDB2777)],
          imageAssetPath: 'assets/animals/cat.jpg', totalExpected: 73, animalType: 'cat',
        );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<IdentifyService>();
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IdentifyHeader(service: service),
                Expanded(
                  child: SingleChildScrollView(
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
                          // Truyền _onSearchDone để animate cả khi NOT_ANIMAL
                          onSearch: () => service.startSearching(_onSearchDone),
                        ),
                        const SizedBox(height: 24),
                        IdentifyResultSection(
                          service: service,
                          fadeAnim: _cardFadeAnim,
                          slideAnim: _cardSlideAnim,
                          onOpenDetail: () => _openDetail(service.resultAnimalId, t),
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