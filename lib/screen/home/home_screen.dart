import 'dart:async';
import 'package:flutter/material.dart' hide debugPrint;
import 'package:kltn_app/screen/home/widgets/home_animal_section.dart';
import 'package:kltn_app/screen/home/widgets/home_quick_access.dart';
import 'package:kltn_app/screen/home/widgets/home_search_box.dart';
import 'package:kltn_app/screen/home/widgets/home_top_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../../services/animal_home_service.dart';
import '../Animal_detail/Animal detail screen.dart';
import '../language/Locale_provider.dart';
import '../update/update_screen.dart';
import 'animal_category_model.dart';
import 'models/animal_suggestion.dart';

enum _HomeCategoryFilter { all, fourLegs, fish, twoLegs }

// Service tìm kiếm
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
        final aScore = a.nameVi.toLowerCase().startsWith(qLower)
            ? 0
            : a.nameEn.toLowerCase().startsWith(qLower)
            ? 1
            : 2;
        final bScore = b.nameVi.toLowerCase().startsWith(qLower)
            ? 0
            : b.nameEn.toLowerCase().startsWith(qLower)
            ? 1
            : 2;
        if (aScore != bScore) return aScore - bScore;
        return a.nameVi.compareTo(b.nameVi);
      });

      return results;
    } catch (_) {
      return [];
    }
  }
}

// Home screen
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
  bool _sortAZ = false; // false = mặc định, true = A-Z
  _HomeCategoryFilter _categoryFilter = _HomeCategoryFilter.all;

  // Search State
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

  // Logic Cập nhật OTA
  Future<void> _checkForUpdate() async {
    try {
      final updater = ShorebirdUpdater();
      final prefs = await SharedPreferences.getInstance();

      final currentPatch = await updater.readCurrentPatch();
      final currentPatchNumber = currentPatch?.number ?? 0;
      final lastSeenPatch = prefs.getInt('last_seen_patch') ?? 0;

      if (currentPatchNumber > lastSeenPatch && currentPatchNumber > 0) {
        await prefs.setInt('last_seen_patch', currentPatchNumber);
        if (mounted) {
          final t = context.read<LocaleProvider>();
          _showJustUpdatedDialog(t);
        }
      }
    } catch (e) {}
  }

  void _showJustUpdatedDialog(LocaleProvider t) {
    final latest = kChangelog.first;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.tr('Đã cập nhật thành công! ✨'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${t.tr('Phiên bản')} ${latest.version} • ${latest.date}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Divider(color: colorScheme.outlineVariant),
              const SizedBox(height: 10),

              Text(
                t.tr('Có gì mới?'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),

              // Danh sách thay đổi
              ...latest.items.map((item) => _ChangelogItemInline(item: item)),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    t.tr('Tuyệt vời! 🎉'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadData() async {
    final fallbackData = AnimalCategory.getEnabledCategories()
        .map(
          (cat) => AnimalCategoryData(
            category: cat,

            // Offline vẫn mở được card.
            // Dùng totalExpected vì đây là số hardcode sẵn trong AnimalCategory.
            count: cat.totalExpected,
          ),
        )
        .toList();

    // Hiện danh mục cứng ngay lập tức, không chờ mạng.
    if (mounted) {
      setState(() {
        _categoryData = fallbackData;
        _isLoading = false;
      });
    }

    // Sau đó nếu có mạng thì cập nhật count thật từ Supabase.
    try {
      final counts = await _service.getAnimalCounts().timeout(
        const Duration(seconds: 4),
      );

      final data = AnimalCategory.getEnabledCategories().map((category) {
        final dbCount = counts[category.id];

        return AnimalCategoryData(
          category: category,
          count: dbCount != null && dbCount > 0
              ? dbCount
              : category.totalExpected,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _categoryData = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('⚠️ [Home] Offline/fallback categories: $e');

      if (!mounted) return;
      setState(() {
        _categoryData = fallbackData;
        _isLoading = false;
      });
    }
  }

  // Logic Search
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
        builder: (_) =>
            AnimalDetailScreen(animalId: suggestion.id, category: category),
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
    var list = _categoryData.where((item) {
      final id = item.category.id.toLowerCase();
      final animalType = item.category.animalType.toLowerCase();
      final key = '$id $animalType';

      switch (_categoryFilter) {
        case _HomeCategoryFilter.all:
          return true;

        // Nhóm 4 chân: các category thú nuôi/thú hoang phổ biến.
        // Vì Home chỉ có dữ liệu category, ta lọc theo id/animalType.
        // Nếu sau này có category mới 4 chân, thêm keyword vào đây.
        case _HomeCategoryFilter.fourLegs:
          return _containsAny(key, const [
            'dog',
            'cat',
            'cattle',
            'cow',
            'buffalo',
            'horse',
            'lion',
            'tiger',
            'bear',
            'goat',
            'sheep',
            'pig',
            'rabbit',
            'deer',
            'elephant',
            'mammal',
          ]);

        case _HomeCategoryFilter.fish:
          return key.contains('fish');

        // Nhóm 2 chân hiện tại chủ yếu là chim.
        // Nếu có poultry/chicken/duck sau này thì vẫn bắt được.
        case _HomeCategoryFilter.twoLegs:
          return _containsAny(key, const [
            'bird',
            'aves',
            'chicken',
            'duck',
            'goose',
            'poultry',
            'penguin',
            'ostrich',
          ]);
      }
    }).toList();

    if (_sortAZ) {
      list.sort((a, b) => a.category.nameVi.compareTo(b.category.nameVi));
    }

    return list;
  }

  bool _containsAny(String source, List<String> keywords) {
    for (final keyword in keywords) {
      if (source.contains(keyword)) return true;
    }
    return false;
  }

  String _getShortDesc(String id, LocaleProvider t) {
    if (id.contains('fish'))
      return t.tr('Thế giới dưới nước huyền bí với muôn loài kỳ thú.');
    if (id.contains('dog '))
      return t.tr('Người bạn trung thành và đáng yêu nhất của bé.');
    if (id.contains('cat'))
      return t.tr('Những người bạn nhỏ thích cuộn tròn và làm nũng.');
    if (id.contains('bird'))
      return t.tr('Những nhạc sĩ của bầu trời với tiếng hót líu lo.');
    if (id.contains('insect'))
      return t.tr('Thế giới tí hon đầy những điều kỳ diệu.');
    return t.tr('Cùng khám phá những điều thú vị về bạn này nhé!');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

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
                  ? Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    )
                  : CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // Top bar & search box
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

                        // Lời chào
                        SliverToBoxAdapter(
                          child: _buildWelcomeText(colorScheme, t),
                        ),

                        // QUICK ACCESS (Vòng tròn Lottie)
                        SliverToBoxAdapter(
                          child: HomeQuickAccess(categoryData: _categoryData),
                        ),

                        // Bộ lọc
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.tr('Danh sách loài'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    children: [
                                      _FilterChip(
                                        label: t.tr('Mặc định'),
                                        icon: Icons.dashboard_rounded,
                                        selected:
                                            !_sortAZ &&
                                            _categoryFilter ==
                                                _HomeCategoryFilter.all,
                                        onTap: () => setState(() {
                                          _sortAZ = false;
                                          _categoryFilter =
                                              _HomeCategoryFilter.all;
                                        }),
                                      ),
                                      const SizedBox(width: 8),
                                      _FilterChip(
                                        label: 'A - Z',
                                        icon: Icons.sort_by_alpha_rounded,
                                        selected: _sortAZ,
                                        onTap: () =>
                                            setState(() => _sortAZ = !_sortAZ),
                                      ),
                                      const SizedBox(width: 8),
                                      _FilterChip(
                                        label: t.tr('4 chân'),
                                        icon: Icons.pets_rounded,
                                        selected:
                                            _categoryFilter ==
                                            _HomeCategoryFilter.fourLegs,
                                        onTap: () => setState(() {
                                          _categoryFilter =
                                              _categoryFilter ==
                                                  _HomeCategoryFilter.fourLegs
                                              ? _HomeCategoryFilter.all
                                              : _HomeCategoryFilter.fourLegs;
                                        }),
                                      ),
                                      const SizedBox(width: 8),
                                      _FilterChip(
                                        label: t.tr('Cá'),
                                        icon: Icons.water_rounded,
                                        selected:
                                            _categoryFilter ==
                                            _HomeCategoryFilter.fish,
                                        onTap: () => setState(() {
                                          _categoryFilter =
                                              _categoryFilter ==
                                                  _HomeCategoryFilter.fish
                                              ? _HomeCategoryFilter.all
                                              : _HomeCategoryFilter.fish;
                                        }),
                                      ),
                                      const SizedBox(width: 8),
                                      _FilterChip(
                                        label: t.tr('2 chân'),
                                        icon: Icons.flutter_dash_rounded,
                                        selected:
                                            _categoryFilter ==
                                            _HomeCategoryFilter.twoLegs,
                                        onTap: () => setState(() {
                                          _categoryFilter =
                                              _categoryFilter ==
                                                  _HomeCategoryFilter.twoLegs
                                              ? _HomeCategoryFilter.all
                                              : _HomeCategoryFilter.twoLegs;
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Danh sách thẻ động vật
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => HomeAnimalSection(
                                data: _displayedCategoryData[index],
                                getShortDesc: (id) => _getShortDesc(id, t),
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

  Widget _buildWelcomeText(ColorScheme colorScheme, LocaleProvider t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.tr('Xin chào'),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            t.tr('Hôm nay bạn muốn xem loài nào?'),
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Filter chip widget
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
          color: selected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
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
              Icon(
                icon,
                size: 14,
                color: selected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 1 dòng changelog dùng trong dialog home
class _ChangelogItemInline extends StatelessWidget {
  final ChangelogItem item;
  const _ChangelogItemInline({required this.item});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleProvider>();
    Color color;
    IconData icon;
    String tag;
    switch (item.type) {
      case ChangelogType.newFeature:
        color = Colors.green;
        icon = Icons.add_circle_rounded;
        tag = t.tr('Mới');
        break;
      case ChangelogType.fix:
        color = Colors.red;
        icon = Icons.bug_report_rounded;
        tag = t.tr('Fix');
        break;
      case ChangelogType.improve:
        color = Colors.blue;
        icon = Icons.trending_up_rounded;
        tag = t.tr('Cải thiện');
        break;
      case ChangelogType.remove:
        color = Colors.grey;
        icon = Icons.remove_circle_rounded;
        tag = t.tr('Xóa');
        break;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              t.tr(item.text),
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter vẽ nền
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
