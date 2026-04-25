import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kltn_app/screen/home/widgets/home_animal_section.dart';
import 'package:kltn_app/screen/home/widgets/home_quick_access.dart';
import 'package:kltn_app/screen/home/widgets/home_search_box.dart';
import 'package:kltn_app/screen/home/widgets/home_top_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart'; // Import package Shorebird

// --- Import các file Service và Model ---
import '../../services/animal_home_service.dart';
import '../Animal_detail/Animal detail screen.dart';
import '../profile/Profile page.dart';
import 'animal_category_model.dart';
import 'models/animal_suggestion.dart';

// ═══════════════════════════════════════════════════════
// SERVICE TÌM KIẾM
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
// HOME SCREEN
// ═══════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AnimalHomeService _service = AnimalHomeService();
  final AnimalSearchService _searchService = AnimalSearchService();

  // Khởi tạo đối tượng Shorebird Code Push (API v2.0+)
  final _updater = ShorebirdUpdater();

  List<AnimalCategoryData> _categoryData = [];
  bool _isLoading = true;
  bool _sortAZ = false; // false = mặc định, true = A-Z

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

    // Chạy kiểm tra bản cập nhật sau khi giao diện đã vẽ xong khung đầu tiên
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // --- Logic Cập nhật OTA Shorebird (API v2.0+) ---
  // --- Logic Cập nhật OTA Shorebird (API v2.0+) ---
  Future<void> _checkForUpdate() async {
    try {
      debugPrint('🔄 [Shorebird] Bắt đầu kiểm tra bản cập nhật...');

      // Hàm checkForUpdate trả về trạng thái UpdateStatus
      final status = await _updater.checkForUpdate();

      debugPrint('📊 [Shorebird] Trạng thái trả về: ${status.name}');

      if (status == UpdateStatus.upToDate) {
        debugPrint('✅ [Shorebird] App đang chạy bản mới nhất, không có Patch mới.');
      }
      else if (status == UpdateStatus.outdated && mounted) {
        debugPrint('⚠️ [Shorebird] Phát hiện bản vá mới (Outdated)! Hiển thị Popup...');

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Có bản cập nhật mới! 🎉'),
            content: const Text('Ứng dụng vừa có phiên bản giao diện mới mượt mà hơn. Bạn có muốn tải về và áp dụng ngay không?'),
            actions: [
              TextButton(
                onPressed: () {
                  debugPrint('⏭️ [Shorebird] Người dùng chọn Bỏ qua cập nhật.');
                  Navigator.pop(ctx);
                },
                child: const Text('Để sau'),
              ),
              FilledButton(
                onPressed: () async {
                  debugPrint('⬇️ [Shorebird] Người dùng đồng ý tải. Đang tiến hành tải Patch...');
                  Navigator.pop(ctx);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đang tải bản cập nhật...'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }

                  // Gọi lệnh tải Patch về máy (API v2.0)
                  await _updater.update();

                  debugPrint('🚀 [Shorebird] Tải Patch thành công! Yêu cầu Restart app.');

                  if (mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (innerCtx) => AlertDialog(
                        title: const Text('Tải hoàn tất! ✅'),
                        content: const Text('Vui lòng thoát hẳn (kill app) và mở lại ứng dụng để trải nghiệm phiên bản mới nhé.'),
                        actions: [
                          FilledButton(
                            onPressed: () => Navigator.pop(innerCtx),
                            child: const Text('Đã hiểu'),
                          )
                        ],
                      ),
                    );
                  }
                },
                child: const Text('Cập nhật ngay'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [Shorebird] Lỗi Crash khi kiểm tra cập nhật: $e');
    }
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

  List<AnimalCategoryData> get _displayedCategoryData {
    if (!_sortAZ) return _categoryData;
    final sorted = List<AnimalCategoryData>.from(_categoryData);
    sorted.sort((a, b) => a.category.nameVi.compareTo(b.category.nameVi));
    return sorted;
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
              bottom: false,
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                  : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // --- TOP BAR & SEARCH BOX ---
                  SliverToBoxAdapter(
                    child: HomeTopBar(
                      // 1. Thêm sự kiện nhấn vào Profile ở đây
                      onProfileTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(), // Hoặc ProfilePage của Sơn
                          ),
                        );
                      },
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

                  // --- BỘ LỌC ---
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          Text(
                            'Danh sách loài',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          // Chip: Mặc định
                          _FilterChip(
                            label: 'Mặc định',
                            selected: !_sortAZ,
                            onTap: () => setState(() => _sortAZ = false),
                          ),
                          const SizedBox(width: 8),
                          // Chip: A-Z
                          _FilterChip(
                            label: 'A - Z',
                            icon: Icons.sort_by_alpha_rounded,
                            selected: _sortAZ,
                            onTap: () => setState(() => _sortAZ = true),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- DANH SÁCH THẺ ĐỘNG VẬT ---
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) => HomeAnimalSection(
                          data: _displayedCategoryData[index],
                          getShortDesc: _getShortDesc,
                        ),
                        childCount: _displayedCategoryData.length,
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
// FILTER CHIP WIDGET
// ═══════════════════════════════════════════════════════
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14,
                  color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// PAINTER VẼ NỀN
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