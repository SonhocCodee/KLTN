import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kltn_app/screen/home/widgets/home_animal_section.dart';
import 'package:kltn_app/screen/home/widgets/home_quick_access.dart';
import 'package:kltn_app/screen/home/widgets/home_search_box.dart';
import 'package:kltn_app/screen/home/widgets/home_top_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Import các file Service và Model ---
import '../../services/animal_home_service.dart';
import '../Animal_detail/Animal detail screen.dart';
import 'animal_category_model.dart';
import 'models/animal_suggestion.dart';

// ═══════════════════════════════════════════════════════
// SERVICE TÌM KIẾM (Có thể tách ra file riêng nếu muốn)
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
// HOME SCREEN (Đã được dọn dẹp sạch sẽ)
// ═══════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AnimalHomeService _service = AnimalHomeService();
  final AnimalSearchService _searchService = AnimalSearchService();

  List<AnimalCategoryData> _categoryData = [];
  bool _isLoading = true;

  // --- Search State ---
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<AnimalSuggestion> _suggestions = [];
  bool _showSuggestions = false;
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Ẩn suggestion khi bấm ra ngoài vùng search
    _searchFocus.addListener(() {
      if (!_searchFocus.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
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

  // --- Logic Search ---
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSuggestions = true;
    });

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await _searchService.search(value);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isSearching = false;
        });
      }
    });
  }

  void _onSuggestionTap(AnimalSuggestion suggestion) {
    _searchFocus.unfocus();
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
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
    _searchFocus.unfocus();
  }

  // Truyền hàm này vào HomeAnimalSection
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
          setState(() => _showSuggestions = false);
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: Stack(
          children: [
            // 1. Hình nền Pattern chấm bi
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(painter: _PatternPainter(colorScheme)),
              ),
            ),

            // 2. Nội dung chính
            SafeArea(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                  : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // --- TOP BAR & SEARCH BOX ---
                  SliverToBoxAdapter(
                    child: HomeTopBar(
                      searchBox: HomeSearchBox(
                        searchController: _searchController,
                        searchFocus: _searchFocus,
                        suggestions: _suggestions,
                        showSuggestions: _showSuggestions,
                        isSearching: _isSearching,
                        onSearchChanged: _onSearchChanged,
                        onSuggestionTap: _onSuggestionTap,
                        onClearSearch: _clearSearch,
                      ),
                    ),
                  ),

                  // --- LỜI CHÀO ---
                  SliverToBoxAdapter(
                    child: _buildWelcomeText(colorScheme),
                  ),

                  // --- QUICK ACCESS (Vòng tròn Lottie) ---
                  SliverToBoxAdapter(
                    child: HomeQuickAccess(categoryData: _categoryData),
                  ),

                  // --- DANH SÁCH THẺ ĐỘNG VẬT ---
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) => HomeAnimalSection(
                          data: _categoryData[index],
                          getShortDesc: _getShortDesc,
                        ),
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

  Widget _buildWelcomeText(ColorScheme colorScheme) {
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
}

// ═══════════════════════════════════════════════════════
// PAINTER VẼ NỀN (Giữ nguyên)
// ═══════════════════════════════════════════════════════
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