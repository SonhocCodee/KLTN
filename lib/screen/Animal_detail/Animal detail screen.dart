import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kltn_app/screen/Animal_detail/service/groq_translation_service.dart';
import 'package:provider/provider.dart';
import 'package:kltn_app/screen/Animal_detail/widgets/animal_detail_external_links.dart';
import 'package:kltn_app/screen/Animal_detail/widgets/animal_detail_header.dart';
import '../../services/animal_home_service.dart';
import '../Auth/auth_screen.dart';
import '../Auth/auth_service.dart';
import '../home/animal_category_model.dart';

import '../language/Locale_provider.dart';
import '../profile/favorite_service.dart';
import '../report/Animal report sheet.dart';
import 'widgets/animal_detail_utils.dart';
import 'widgets/animal_detail_title.dart';
import 'widgets/animal_detail_quick_stats.dart';
import 'widgets/animal_detail_description.dart';
import 'widgets/animal_detail_characteristics.dart';
import 'widgets/animal_detail_physical.dart';
import 'widgets/animal_detail_habitat.dart';
import 'widgets/animal_detail_conservation.dart';
import 'widgets/animal_detail_taxonomy.dart';
import 'widgets/animal_detail_video.dart';

import 'widgets/animal_detail_sound.dart';
import 'widgets/animal_distribution_map.dart';

class AnimalDetailScreen extends StatefulWidget {
  final String animalId;
  final AnimalCategory category;

  // Dùng khi user bấm tim lúc chưa đăng nhập.
  // Sau khi đăng nhập xong sẽ quay lại đúng loài này và tự thêm yêu thích.
  final bool autoFavoriteAfterLogin;

  // Dùng khi user bấm báo cáo lúc chưa đăng nhập.
  // Sau khi đăng nhập xong sẽ quay lại đúng loài này và tự mở form báo cáo.
  final bool autoReportAfterLogin;

  const AnimalDetailScreen({
    super.key,
    required this.animalId,
    required this.category,
    this.autoFavoriteAfterLogin = false,
    this.autoReportAfterLogin = false,
  });

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen>
    with TickerProviderStateMixin {
  final AnimalHomeService _service = AnimalHomeService();
  final FavoriteService _favoriteService = FavoriteService();
  final GroqTranslationService _translator =
      GroqTranslationService(); // 👈 thêm
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? _animal;
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _isTogglingFavorite = false;
  bool _didRunAutoAction = false;

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
      final results = await Future.wait([
        _service.getAnimalById(widget.animalId),
        _favoriteService.isFavorite(widget.animalId),
      ]);

      final animal = results[0] as Map<String, dynamic>?;
      final isFav = results[1] as bool;

      setState(() {
        _animal = animal;
        _isFavorite = isFav;
        _isLoading = false;
      });

      if (animal != null) {
        _fadeController.forward();
        _slideController.forward();

        // Trigger dịch ngầm nếu đang xem tiếng Anh
        _maybeTranslate(animal);

        // Nếu user vừa đăng nhập từ popup tim/báo cáo thì chạy tiếp hành động cũ.
        _runAutoActionAfterLogin();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Dịch ngầm (không block UI). Nếu dịch thành công -> setState để
  // AnimalDetailDescription hiển thị bản dịch mới ngay.
  void _maybeTranslate(Map<String, dynamic> animal) {
    final isEnglish = context.read<LocaleProvider>().isEnglish;
    if (!isEnglish) return; // Đang tiếng Việt -> không cần dịch

    final missingFunFact = (animal['fun_fact_english'] as String? ?? '')
        .trim()
        .isEmpty;
    final missingDesc = (animal['description_english'] as String? ?? '')
        .trim()
        .isEmpty;
    if (!missingFunFact && !missingDesc) return; // Đã có đủ bản dịch

    // Fire-and-forget: dịch ngầm, cập nhật UI khi xong
    _translator.translateAndSave(animal).then((translated) {
      if (translated && mounted) setState(() {});
    });
  }

  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite) return;

    if (!AuthService.isAuthenticatedUser) {
      _showLoginRequiredDialog(_ProtectedAction.favorite);
      return;
    }

    setState(() => _isTogglingFavorite = true);
    try {
      final newState = await _favoriteService.toggleFavorite(widget.animalId);
      if (!mounted) return;
      setState(() => _isFavorite = newState);

      final t = context.read<LocaleProvider>();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newState
                ? t.tr('❤️ Đã thêm vào loài yêu thích')
                : t.tr('💔 Đã xoá khỏi loài yêu thích'),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isTogglingFavorite = false);
    }
  }

  Future<void> _addFavoriteAfterLogin() async {
    if (_isTogglingFavorite || _isFavorite) return;
    if (!AuthService.isAuthenticatedUser) return;

    setState(() => _isTogglingFavorite = true);
    try {
      final success = await _favoriteService.addFavorite(widget.animalId);
      if (!mounted) return;

      if (success) {
        setState(() => _isFavorite = true);
        final t = context.read<LocaleProvider>();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.tr('❤️ Đã thêm vào loài yêu thích')),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingFavorite = false);
    }
  }

  void _handleReportTap() {
    HapticFeedback.lightImpact();

    if (!AuthService.isAuthenticatedUser) {
      _showLoginRequiredDialog(_ProtectedAction.report);
      return;
    }

    _openReportSheet();
  }

  void _openReportSheet() {
    if (!mounted || _animal == null) return;
    showAnimalReportSheet(context, animalId: widget.animalId, animal: _animal!);
  }

  void _runAutoActionAfterLogin() {
    if (_didRunAutoAction) return;
    if (!AuthService.isAuthenticatedUser) return;
    if (!widget.autoFavoriteAfterLogin && !widget.autoReportAfterLogin) return;

    _didRunAutoAction = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      if (widget.autoFavoriteAfterLogin) {
        await _addFavoriteAfterLogin();
      }

      if (!mounted) return;

      if (widget.autoReportAfterLogin) {
        _openReportSheet();
      }
    });
  }

  void _showLoginRequiredDialog(_ProtectedAction action) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFavoriteAction = action == _ProtectedAction.favorite;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFavoriteAction
                      ? Icons.favorite_rounded
                      : Icons.flag_rounded,
                  color: isFavoriteAction
                      ? Colors.redAccent
                      : colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cần đăng nhập',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            isFavoriteAction
                ? 'Vui lòng đăng nhập để thêm loài này vào danh sách yêu thích.'
                : 'Vui lòng đăng nhập để gửi báo cáo sửa thông tin loài này.',
            style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.45),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Để sau'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                final ok = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    settings: const RouteSettings(
                      arguments: {'popAfterLogin': true},
                    ),
                    builder: (_) => const AuthScreen(),
                  ),
                );

                if (!mounted ||
                    ok != true ||
                    !AuthService.isAuthenticatedUser) {
                  return;
                }

                if (action == _ProtectedAction.favorite) {
                  await _addFavoriteAfterLogin();
                } else {
                  _openReportSheet();
                }
              },
              child: const Text('Đăng nhập'),
            ),
          ],
        );
      },
    );
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
                          AnimalExternalLinks(animal: _animal!),

                          // Divider
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
                                if (AnimalDetailVideo.hasVideo(_animal!)) ...[
                                  AnimalDetailUtils.buildSectionGap(
                                    colorScheme,
                                  ),
                                  AnimalDetailVideo(animal: _animal!),
                                ],
                                AnimalDetailUtils.buildSectionGap(colorScheme),
                                AnimalDetailCharacteristics(animal: _animal!),
                                AnimalDetailUtils.buildSectionGap(colorScheme),
                                AnimalDetailPhysical(animal: _animal!),
                                AnimalDetailUtils.buildSectionGap(colorScheme),
                                AnimalDetailHabitat(animal: _animal!),
                                AnimalDetailUtils.buildSectionGap(colorScheme),

                                // 🔊 Âm thanh loài
                                AnimalDetailSound(animal: _animal!),
                                AnimalDetailUtils.buildSectionGap(colorScheme),

                                // 🗺️ Bản đồ phân bố
                                AnimalDistributionMap(animal: _animal!),
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

          // Floating buttons (back + share/...)
          AnimalDetailFloatingButtons(
            animalId: widget.animalId,
            animal: _animal!,
            onReportTap: _handleReportTap,
          ),

          // Nút yêu thích
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            right: 24,
            child: _FavoriteButton(
              isFavorite: _isFavorite,
              isLoading: _isTogglingFavorite,
              onTap: _toggleFavorite,
            ),
          ),
        ],
      ),
    );
  }
}

enum _ProtectedAction { favorite, report }

// Widget nút yêu thích

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final bool isLoading;
  final VoidCallback onTap;

  const _FavoriteButton({
    required this.isFavorite,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isFavorite
              ? Colors.red.withOpacity(0.92)
              : colorScheme.surface.withOpacity(0.88),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isLoading
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isFavorite ? Colors.white : colorScheme.onSurface,
                ),
              )
            : Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.white : colorScheme.onSurface,
                size: 22,
              ),
      ),
    );
  }
}
