import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/animal_home_service.dart';
import '../Animal_detail/Animal detail screen.dart';
import '../Breed_List/Breed list screen.dart';
import 'animal_category_model.dart';

// ═══════════════════════════════════════════════════════
// MODEL cho gợi ý tìm kiếm
// ═══════════════════════════════════════════════════════
class AnimalSuggestion {
  final String id;
  final String nameVi;
  final String nameEn;
  final String animalType;
  final String? imageUrl;

  AnimalSuggestion({
    required this.id,
    required this.nameVi,
    required this.nameEn,
    required this.animalType,
    this.imageUrl,
  });

  factory AnimalSuggestion.fromMap(Map<String, dynamic> map) {
    return AnimalSuggestion(
      id: map['id'] ?? '',
      nameVi: map['name_vietnamese'] ?? '',
      nameEn: map['name_english'] ?? '',
      animalType: map['animal_type'] ?? '',
      imageUrl: map['image_url'],
    );
  }

  // Icon emoji theo loài
  String get typeEmoji {
    switch (animalType.toLowerCase()) {
      case 'cat': return '🐱';
      case 'dog': return '🐶';
      case 'bird': return '🦜';
      case 'fish': return '🐟';
      case 'buffalo': return '🐃';
      case 'cattle': return '🐄';
      case 'horse': return '🐴';
      case 'bear': return '🐻';
      case 'lion': return '🦁';
      default: return '🐾';
    }
  }

  String get typeLabel {
    switch (animalType.toLowerCase()) {
      case 'cat': return 'Mèo';
      case 'dog': return 'Chó';
      case 'bird': return 'Chim';
      case 'fish': return 'Cá';
      case 'buffalo': return 'Trâu';
      case 'cattle': return 'Bò';
      case 'horse': return 'Ngựa';
      case 'bear': return 'Gấu';
      case 'lion': return 'Sư tử';
      default: return animalType;
    }
  }
}

// ═══════════════════════════════════════════════════════
// SERVICE tìm kiếm
// ═══════════════════════════════════════════════════════
class AnimalSearchService {
  final _client = Supabase.instance.client;

  Future<List<AnimalSuggestion>> search(String query) async {
    if (query.trim().length < 2) return [];

    final q = query.trim();

    try {
      final data = await _client
          .from('animals')
          .select('id, name_vietnamese, name_english, animal_type, image_url')
          .or('name_vietnamese.ilike.%$q%,name_english.ilike.%$q%')
          .order('name_vietnamese')
          .limit(8);

      final results = (data as List)
          .map((e) => AnimalSuggestion.fromMap(e as Map<String, dynamic>))
          .toList();

      // Ưu tiên kết quả bắt đầu bằng query lên đầu
      final qLower = q.toLowerCase();
      results.sort((a, b) {
        final aScore = a.nameVi.toLowerCase().startsWith(qLower) ? 0
            : a.nameEn.toLowerCase().startsWith(qLower) ? 1 : 2;
        final bScore = b.nameVi.toLowerCase().startsWith(qLower) ? 0
            : b.nameEn.toLowerCase().startsWith(qLower) ? 1 : 2;
        if (aScore != bScore) return aScore - bScore;
        return a.nameVi.compareTo(b.nameVi);
      });

      return results;
    } catch (_) {
      return [];
    }
  }
}

// ═══════════════════════════════════════════════════════
// HOME SCREEN
// ═══════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final AnimalHomeService _service = AnimalHomeService();
  final AnimalSearchService _searchService = AnimalSearchService();

  List<AnimalCategoryData> _categoryData = [];
  bool _isLoading = true;

  // Search state
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<AnimalSuggestion> _suggestions = [];
  bool _showSuggestions = false;
  bool _isSearching = false;
  Timer? _debounce;

  // Overlay dropdown
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _loadData();

    _searchFocus.addListener(() {
      if (!_searchFocus.hasFocus) {
        setState(() => _showSuggestions = false);
        _removeOverlay();
      }
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  OverlayEntry _buildOverlayEntry() {
    final colorScheme = Theme.of(context).colorScheme;

    return OverlayEntry(
      builder: (context) {
        return Positioned(
          width: MediaQuery.of(context).size.width - 48,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 56),
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                constraints: const BoxConstraints(maxHeight: 380),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _suggestions.isEmpty && !_isSearching
                      ? Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 16),
                    child: Row(
                      children: [
                        const Text('😕', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Không tìm thấy "${_searchController.text}"',
                            style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (_, i) => _buildSuggestionItem(
                        _suggestions[i], i, i == _suggestions.length - 1),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final counts = await _service.getAnimalCounts();
      List<AnimalCategoryData> data = [];
      for (var category in AnimalCategory.getEnabledCategories()) {
        final count = counts[category.id] ?? 0;
        data.add(AnimalCategoryData(category: category, count: count));
      }
      setState(() {
        _categoryData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _categoryData = AnimalCategory.getEnabledCategories()
            .map((cat) => AnimalCategoryData(category: cat, count: 0))
            .toList();
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _isSearching = false;
      });
      _removeOverlay();
      return;
    }

    setState(() => _isSearching = true);
    _showOverlay();

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await _searchService.search(value);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _showSuggestions = true;
          _isSearching = false;
        });
        _overlayEntry?.markNeedsBuild();
      }
    });
  }

  void _onSuggestionTap(AnimalSuggestion suggestion) {
    _searchFocus.unfocus();
    _removeOverlay();
    setState(() {
      _showSuggestions = false;
      _searchController.clear();
      _suggestions = [];
    });

    final category = AnimalCategory.getEnabledCategories().firstWhere(
          (c) => c.id.toLowerCase().contains(suggestion.animalType.toLowerCase()),
      orElse: () => AnimalCategory.getEnabledCategories().first,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnimalDetailScreen(
          animalId: suggestion.id,
          category: category,
        ),
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    _removeOverlay();
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
    _searchFocus.unfocus();
  }

  String _getShortDesc(String id) {
    if (id.contains('dog')) return 'Người bạn trung thành và đáng yêu nhất của bé.';
    if (id.contains('cat')) return 'Những người bạn nhỏ thích cuộn tròn và làm nũng.';
    if (id.contains('bird')) return 'Những nhạc sĩ của bầu trời với tiếng hót líu lo.';
    if (id.contains('insect')) return 'Thế giới tí hon đầy những điều kỳ diệu.';
    return 'Cùng khám phá những điều thú vị về bạn này nhé!';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        if (_showSuggestions) {
          _searchFocus.unfocus();
          _removeOverlay();
          setState(() {
            _showSuggestions = false;
          });
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: colorScheme.surface, // Nền tổng vẫn là surface (đen tuyền)
        body: Stack(
          children: [
            // Nền Pattern chấm bi nhẹ
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(painter: _PatternPainter(colorScheme)),
              ),
            ),

            SafeArea(
              child: _isLoading
                  ? Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              )
                  : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildTopBar()),
                  SliverToBoxAdapter(child: _buildWelcomeText()),
                  SliverToBoxAdapter(child: _buildAnimatedQuickAccess()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                            _buildAnimalSection(_categoryData[index]),
                        childCount: _categoryData.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 15, 24, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.asset(
                        'assets/images/appicon.jpg',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'AniQuest',
                    style: TextStyle(fontSize: 22, color: colorScheme.onSurface),
                  ),
                ],
              ),
              CircleAvatar(
                backgroundColor: colorScheme.surfaceContainerHighest,
                child: Icon(Icons.person_outline, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── SEARCH BOX với Autocomplete ──
          _buildSearchBox(),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    final colorScheme = Theme.of(context).colorScheme;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm bạn động vật...',
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
            border: InputBorder.none,
            icon: _isSearching
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            )
                : Icon(Icons.search, color: colorScheme.primary),
            suffixIcon: _searchController.text.isNotEmpty
                ? GestureDetector(
              onTap: _clearSearch,
              child: Icon(Icons.close,
                  color: colorScheme.onSurfaceVariant, size: 18),
            )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(AnimalSuggestion s, int index, bool isLast) {
    final query = _searchController.text.trim();
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _onSuggestionTap(s),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
            bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.8),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: s.imageUrl != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  s.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(s.typeEmoji,
                        style: const TextStyle(fontSize: 20)),
                  ),
                ),
              )
                  : Center(
                child: Text(s.typeEmoji,
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHighlightedText(s.nameVi, query,
                      baseStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface)),
                  const SizedBox(height: 2),
                  _buildHighlightedText(s.nameEn, query,
                      baseStyle: TextStyle(
                          fontSize: 12, color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                s.typeLabel,
                style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedText(
      String text,
      String query, {
        required TextStyle baseStyle,
      }) {
    if (query.isEmpty) return Text(text, style: baseStyle);

    final lower = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final start = lower.indexOf(lowerQuery);

    if (start == -1) return Text(text, style: baseStyle);

    final colorScheme = Theme.of(context).colorScheme;

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          if (start > 0) TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, start + query.length),
            style: baseStyle.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (start + query.length < text.length)
            TextSpan(text: text.substring(start + query.length)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildWelcomeText() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chào Bạn! 👋',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface)),
          Text('Hôm nay bạn muốn xem loài nào?',
              style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAnimatedQuickAccess() {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 120,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categoryData.length,
        itemBuilder: (context, index) {
          final cat = _categoryData[index].category;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest, // <--- ĐÃ SỬA THÀNH NỀN XÁM ĐEN CHO CÁC VÒNG TRÒN
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: cat.gradient[0].withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: ClipOval(child: _getLottieForCategory(cat.id)),
                ),
                const SizedBox(height: 8),
                Text(
                  cat.nameVi,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _getLottieForCategory(String id) {
    String fileName = 'default_anim.json';
    if (id.contains('dog')) fileName = 'dog_anim.json';
    if (id.contains('cat')) fileName = 'cat_anim.json';
    if (id.contains('bird')) fileName = 'bird_anim.json';

    return Lottie.asset(
      'assets/icons/$fileName',
      fit: BoxFit.cover,
      repeat: true,
      animate: true,
      errorBuilder: (ctx, error, stackTrace) =>
          Icon(Icons.pets, color: Theme.of(ctx).colorScheme.onSurfaceVariant),
    );
  }

  Widget _buildAnimalSection(AnimalCategoryData data) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.pets,
                    color: data.category.gradient[0].withOpacity(0.6),
                    size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.category.nameVi,
                          style: TextStyle(
                              fontSize: 22, color: colorScheme.onSurface)),
                      Text(
                        _getShortDesc(data.category.id),
                        style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                _buildBadge(data),
              ],
            ),
          ),
          _InteractiveAnimalCard(data: data),
        ],
      ),
    );
  }

  Widget _buildBadge(AnimalCategoryData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: data.category.gradient[0].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        data.displayText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: data.category.gradient[0],
        ),
      ),
    );
  }
}

// ── GIỮ NGUYÊN _InteractiveAnimalCard ──

class _InteractiveAnimalCard extends StatefulWidget {
  final AnimalCategoryData data;
  const _InteractiveAnimalCard({required this.data});

  @override
  State<_InteractiveAnimalCard> createState() => _InteractiveAnimalCardState();
}

class _InteractiveAnimalCardState extends State<_InteractiveAnimalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation =
        Tween<double>(begin: 1.0, end: 0.98).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasData = widget.data.hasData;
    final category = widget.data.category;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => hasData ? _controller.forward() : null,
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        if (hasData) {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BreedListScreen(
                category: category,
                totalCount: widget.data.count,
              ),
            ),
          );
        }
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            image: DecorationImage(
              image: AssetImage(category.imageAssetPath),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hasData ? 'Khám phá ngay' : 'Đang cập nhật',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.auto_awesome,
                              color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (!hasData)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: Icon(Icons.lock_clock,
                        color: Colors.white, size: 40),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final ColorScheme colorScheme;

  _PatternPainter(this.colorScheme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = colorScheme.primary.withOpacity(0.15);
    for (double i = 0; i < size.width; i += 40) {
      for (double j = 0; j < size.height; j += 40) {
        canvas.drawCircle(Offset(i, j), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}