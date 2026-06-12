import 'package:flutter/material.dart';
import 'package:kltn_app/screen/Animal_detail/widgets/animal_detail_header.dart';
import '../../services/animal_home_service.dart';
import '../Animal_detail/widgets/animal_detail_characteristics.dart';
import '../Animal_detail/widgets/animal_detail_conservation.dart';
import '../Animal_detail/widgets/animal_detail_description.dart';
import '../Animal_detail/widgets/animal_detail_habitat.dart';
import '../Animal_detail/widgets/animal_detail_physical.dart';
import '../Animal_detail/widgets/animal_detail_quick_stats.dart';
import '../Animal_detail/widgets/animal_detail_taxonomy.dart';
import '../Animal_detail/widgets/animal_detail_title.dart';
import '../Animal_detail/widgets/animal_detail_utils.dart';
import '../home/animal_category_model.dart';

class AnimalDetailScreen extends StatefulWidget {
  final String animalId;
  final AnimalCategory category;

  const AnimalDetailScreen({
    super.key,
    required this.animalId,
    required this.category,
  });

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen>
    with TickerProviderStateMixin {
  final AnimalHomeService _service = AnimalHomeService();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? _animal;
  bool _isLoading = true;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _loadAnimalDetails();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadAnimalDetails() async {
    setState(() => _isLoading = true);
    try {
      final animal = await _service.getAnimalById(widget.animalId);
      setState(() {
        _animal = animal;
        _isLoading = false;
      });
      if (animal != null) {
        _fadeController.forward();
        _slideController.forward();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return AnimalDetailLoading(category: widget.category);
    if (_animal == null) return const AnimalDetailError();

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              AnimalDetailImageHeader(
                imageUrl: _animal!['image_url'] ?? '',
                category: widget.category,
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimalDetailTitle(
                            animal: _animal!,
                            category: widget.category,
                          ),
                          AnimalDetailQuickStats(animal: _animal!),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 24,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 2,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: colorScheme.outlineVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimalDetailDescription(animal: _animal!),
                                AnimalDetailUtils.buildSectionGap(colorScheme),
                                AnimalDetailCharacteristics(animal: _animal!),
                                AnimalDetailUtils.buildSectionGap(colorScheme),
                                AnimalDetailPhysical(animal: _animal!),
                                AnimalDetailUtils.buildSectionGap(colorScheme),
                                AnimalDetailHabitat(animal: _animal!),
                                AnimalDetailUtils.buildSectionGap(colorScheme),
                                AnimalDetailConservation(animal: _animal!),
                                AnimalDetailUtils.buildSectionGap(colorScheme),
                                AnimalDetailTaxonomy(animal: _animal!),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Floating Buttons (Back + Report)
          AnimalDetailFloatingButtons(
            animalId: widget.animalId,
            animal: _animal!,
          ),
        ],
      ),
    );
  }
}
