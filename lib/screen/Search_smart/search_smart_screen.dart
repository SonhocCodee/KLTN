import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:kltn_app/screen/Search_smart/widgets/search_smart_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../language/Locale_provider.dart';

import 'models/search_smart_models.dart';
import '../Animal_detail/Animal detail screen.dart';
import '../home/animal_category_model.dart';

enum _AnimalTypeFilter { all, fourLegs, fish, twoLegs }

class SmartQuizPage extends StatefulWidget {
  const SmartQuizPage({super.key});

  @override
  State<SmartQuizPage> createState() => _SmartQuizPageState();
}

class _SmartQuizPageState extends State<SmartQuizPage> {
  AnimalTypeConfig? _selectedConfig;
  int _questionIndex = 0;
  bool _isLoading = false;
  bool _showResults = false;

  // ── Search & Sort trên màn hình chọn loài ──
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _sortAZ = false;
  _AnimalTypeFilter _typeFilter = _AnimalTypeFilter.all;

  final Map<String, dynamic> _filters = {};
  List<Map<String, dynamic>> _results = [];
  final List<int> _askedQuestionIndices = [];

  final _client = Supabase.instance.client;

  List<QuestionConfig> get _questions => _selectedConfig?.questions ?? [];
  List<OptionConfig> _currentValidOptions = [];

  // ── LOGIC ─────────────────────────────────────────────────────────────────
  void _reset() {
    setState(() {
      _selectedConfig = null;
      _questionIndex = 0;
      _filters.clear();
      _results.clear();
      _askedQuestionIndices.clear();
      _isLoading = false;
      _showResults = false;
      // reset search/sort khi quay về màn hình chọn loài
      _searchQuery = '';
      _searchController.clear();
      _sortAZ = false;
      _typeFilter = _AnimalTypeFilter.all;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectAnimalType(AnimalTypeConfig config) async {
    setState(() {
      _selectedConfig = config;
      _questionIndex = 0;
      _filters.clear();
      _results.clear();
      _askedQuestionIndices.clear();
      _showResults = false;
      _isLoading = true;
    });
    // Fetch toàn bộ trước để _results có dữ liệu, logic advance mới hoạt động đúng
    await _fetchResults({});
    setState(() => _isLoading = false);
    await _advanceToNextUsefulQuestion();
  }

  Future<int> _countResultsWithFilter(Map<String, dynamic> baseFilters, QuestionConfig q, dynamic value) async {
    if (_selectedConfig == null) return 0;
    final testFilters = Map<String, dynamic>.from(baseFilters);
    testFilters[q.column] = value;
    try {
      final data = await _buildQuery(testFilters);
      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }

  Future<List<OptionConfig>> _getValidOptions(QuestionConfig q) async {
    final validOpts = <OptionConfig>[];
    for (final opt in q.options) {
      final count = await _countResultsWithFilter(_filters, q, opt.value);
      if (count > 0) validOpts.add(opt);
    }
    return validOpts;
  }

  Future<void> _advanceToNextUsefulQuestion() async {
    if (_selectedConfig == null) return;

    while (_questionIndex < _questions.length) {
      // Chỉ dừng hỏi khi đã lọc ít nhất 1 bộ lọc VÀ kết quả đủ nhỏ
      if (_filters.isNotEmpty && _results.length <= 3) {
        setState(() => _showResults = true);
        return;
      }

      final q = _questions[_questionIndex];
      final validOpts = await _getValidOptions(q);

      if (validOpts.isEmpty) {
        setState(() => _questionIndex++);
        continue;
      }

      if (validOpts.length == 1) {
        setState(() {
          _filters[q.column] = validOpts.first.value;
          _questionIndex++;
          _isLoading = true;
        });
        await _fetchResults(_filters);
        setState(() => _isLoading = false);
        continue;
      }

      _currentValidOptions = validOpts;
      setState(() {});
      return;
    }

    setState(() => _showResults = true);
  }

  Future<void> _answer(QuestionConfig q, dynamic value) async {
    HapticFeedback.lightImpact();
    setState(() {
      _filters[q.column] = value;
      _questionIndex++;
      _currentValidOptions = [];
      _isLoading = true;
    });

    await _fetchResults(_filters);
    setState(() => _isLoading = false);
    await _advanceToNextUsefulQuestion();
  }

  Future<void> _skip() async {
    HapticFeedback.selectionClick();
    setState(() {
      _questionIndex++;
      _currentValidOptions = [];
    });
    await _advanceToNextUsefulQuestion();
  }

  dynamic _buildQuery(Map<String, dynamic> filters) {
    final config = _selectedConfig!;

    // Bảng *_traits (dog_traits, cat_traits) không có id riêng:
    // Dùng foreign key animal_id để JOIN với bảng animals lấy tên/ảnh
    final isTraitsTable = config.dbTable.endsWith('_traits');
    if (isTraitsTable) {
      // SELECT từ dog_traits/cat_traits JOIN animals qua foreign key animal_id
      // Dùng animals(...) không có !inner để tránh lỗi khi FK chưa được đặt tên explicit
      var query = _client
          .from(config.dbTable)
          .select('animal_id, animals(id, name_vietnamese, name_english, scientific_name, image_url, description_short, animal_type)');
      for (final entry in filters.entries) {
        final col = entry.key;
        final val = entry.value;
        final qConfig = _questions.firstWhere((q) => q.column == col, orElse: () => _questions.first);
        if (qConfig.isBool || val is bool) {
          query = query.eq(col, val) as dynamic;
        } else if (qConfig.isArray) {
          query = query.contains(col, [val]) as dynamic;
        } else {
          query = query.eq(col, val) as dynamic;
        }
      }
      return query;
    }

    // Bảng animals thông thường
    var query = _client.from(config.dbTable).select(
      'id, name_vietnamese, name_english, scientific_name, image_url, description_short, animal_type',
    );

    if (config.dbTable == 'animals') {
      query = query.eq('animal_type', config.animalType) as dynamic;
    }

    for (final entry in filters.entries) {
      final col = entry.key;
      final val = entry.value;
      final qConfig = _questions.firstWhere((q) => q.column == col, orElse: () => _questions.first);

      if (qConfig.isArray) {
        query = query.contains(col, [val]) as dynamic;
      } else if (qConfig.isBool || val is bool) {
        query = query.eq(col, val) as dynamic;
      } else if (qConfig.isRange && val is int) {
        query = query.gte(col, val - 1).lte(col, val + 1) as dynamic;
      } else {
        query = query.eq(col, val) as dynamic;
      }
    }
    return query;
  }

  Future<void> _fetchResults(Map<String, dynamic> filters) async {
    if (_selectedConfig == null) return;
    try {
      final data = await _buildQuery(filters);
      final list = data as List;
      final isTraitsTable = _selectedConfig!.dbTable.endsWith('_traits');
      setState(() {
        if (isTraitsTable) {
          // Flatten nested animals object lên top-level
          // animals có thể là Map (1-1 FK) hoặc List (nếu Supabase trả array)
          _results = list.map((row) {
            final raw = row['animals'];
            final Map<String, dynamic> animalData;
            if (raw is Map<String, dynamic>) {
              animalData = raw;
            } else if (raw is List && raw.isNotEmpty) {
              animalData = Map<String, dynamic>.from(raw.first as Map);
            } else {
              animalData = {};
            }
            return animalData;
          }).where((a) => a.isNotEmpty).toList();
        } else {
          _results = List<Map<String, dynamic>>.from(list);
        }
      });
    } catch (e) {
      debugPrint('[SmartSearch] fetchResults error: $e');
      setState(() => _results = []);
    }
  }

  void _showDetail(Map<String, dynamic> animal, LocaleProvider t) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (animal['image_url'] != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      animal['image_url'],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: colorScheme.surfaceContainer,
                        child: Center(
                          child: Text(
                            _selectedConfig?.emoji ?? '🐾',
                            style: const TextStyle(fontSize: 64),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animal['name_vietnamese'] ?? animal['name_english'] ?? '—',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (animal['scientific_name'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        animal['scientific_name'],
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (animal['name_english'] != null &&
                        animal['name_english'] != animal['name_vietnamese']) ...[
                      const SizedBox(height: 2),
                      Text(
                        animal['name_english'],
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (animal['description_short'] != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        animal['description_short'],
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                          height: 1.5,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    16, 20, 16, MediaQuery.of(ctx).padding.bottom + 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          side: BorderSide(color: colorScheme.outline),
                        ),
                        child: Text(
                          t.tr('Đóng'),
                          style: TextStyle(
                              fontSize: 16, color: colorScheme.onSurface),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          final animalType =
                          (animal['animal_type'] ?? '').toString();
                          final category = AnimalCategory
                              .getEnabledCategories()
                              .firstWhere(
                                (c) => c.id
                                .toLowerCase()
                                .contains(animalType.toLowerCase()),
                            orElse: () =>
                            AnimalCategory.getEnabledCategories().first,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AnimalDetailScreen(
                                animalId: animal['id'],
                                category: category,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: Text(t.tr('Xem chi tiết'),
                            style: const TextStyle(fontSize: 16)),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── BUILD UI ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(bottom: false, child: _buildBody(colorScheme, t)),
    );
  }

  Widget _buildBody(ColorScheme colorScheme, LocaleProvider t) {
    if (_selectedConfig == null) return _buildTypeSelection(colorScheme, t);
    if (_isLoading) return const SmartLoadingView();
    if (_showResults || _questionIndex >= _questions.length) return _buildResults(colorScheme, t);
    return _buildQuestion(colorScheme, t);
  }

  // ── Getter: search + lọc nhóm + sắp xếp danh sách loài ──
  List<AnimalTypeConfig> get _displayedAnimalTypes {
    var list = allAnimalTypes.where((c) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchSearch = c.nameVi.toLowerCase().contains(q) ||
            c.nameEn.toLowerCase().contains(q) ||
            c.key.toLowerCase().contains(q) ||
            c.animalType.toLowerCase().contains(q);
        if (!matchSearch) return false;
      }

      return _matchTypeFilter(c);
    }).toList();

    if (_sortAZ) {
      list = List<AnimalTypeConfig>.from(list)
        ..sort((a, b) => a.nameVi.compareTo(b.nameVi));
    }
    return list;
  }

  bool _matchTypeFilter(AnimalTypeConfig c) {
    final key = '${c.key} ${c.animalType} ${c.nameVi} ${c.nameEn}'.toLowerCase();

    switch (_typeFilter) {
      case _AnimalTypeFilter.all:
        return true;
      case _AnimalTypeFilter.fish:
        return key.contains('fish') || key.contains('cá');
      case _AnimalTypeFilter.twoLegs:
        return _containsAny(key, const [
          'bird',
          'aves',
          'chim',
          'chicken',
          'duck',
          'goose',
          'penguin',
        ]);
      case _AnimalTypeFilter.fourLegs:
        return _containsAny(key, const [
          'dog',
          'cat',
          'buffalo',
          'cattle',
          'cow',
          'horse',
          'bear',
          'lion',
          'tiger',
          'goat',
          'sheep',
          'pig',
          'rabbit',
          'deer',
          'elephant',
          'mammal',
        ]);
    }
  }

  bool _containsAny(String text, List<String> keywords) {
    for (final k in keywords) {
      if (text.contains(k)) return true;
    }
    return false;
  }

  // 1. Chọn Loài
  Widget _buildTypeSelection(ColorScheme colorScheme, LocaleProvider t) {
    final displayed = _displayedAnimalTypes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Tiêu đề ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.tr('Tìm động vật'),
                style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5),
              ).animate().fadeIn(duration: 350.ms),
              const SizedBox(height: 4),
              Text(
                t.tr('Chọn loài bạn muốn khám phá'),
                style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400),
              ).animate().fadeIn(delay: 100.ms),
            ],
          ),
        ),

        // ── Search bar ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: t.tr('Tìm loài... (chó, mèo, hổ...)'),
                hintStyle:
                TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15),
                prefixIcon: Icon(CupertinoIcons.search,
                    color: colorScheme.onSurfaceVariant, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                  onTap: () =>
                      setState(() { _searchQuery = ''; _searchController.clear(); }),
                  child: Icon(CupertinoIcons.xmark_circle_fill,
                      color: colorScheme.onSurfaceVariant, size: 18),
                )
                    : null,
                border: InputBorder.none,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 150.ms),

        const SizedBox(height: 10),

        // ── Filter + Sort chips ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayed.isEmpty
                    ? t.tr('Không tìm thấy loài nào')
                    : '${displayed.length} ${t.tr('loài')}',
                style: TextStyle(
                    fontSize: 13, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _SortChip(
                      label: t.tr('Mặc định'),
                      icon: CupertinoIcons.square_grid_2x2,
                      selected: _typeFilter == _AnimalTypeFilter.all && !_sortAZ,
                      onTap: () => setState(() {
                        _typeFilter = _AnimalTypeFilter.all;
                        _sortAZ = false;
                      }),
                    ),
                    const SizedBox(width: 8),
                    _SortChip(
                      label: 'A - Z',
                      icon: CupertinoIcons.sort_down,
                      selected: _sortAZ,
                      onTap: () => setState(() => _sortAZ = !_sortAZ),
                    ),
                    const SizedBox(width: 8),
                    _SortChip(
                      label: t.tr('4 chân'),
                      icon: Icons.pets_rounded,
                      selected: _typeFilter == _AnimalTypeFilter.fourLegs,
                      onTap: () => setState(() =>
                      _typeFilter = _AnimalTypeFilter.fourLegs),
                    ),
                    const SizedBox(width: 8),
                    _SortChip(
                      label: t.tr('Cá'),
                      icon: Icons.water_rounded,
                      selected: _typeFilter == _AnimalTypeFilter.fish,
                      onTap: () => setState(() =>
                      _typeFilter = _AnimalTypeFilter.fish),
                    ),
                    const SizedBox(width: 8),
                    _SortChip(
                      label: t.tr('2 chân'),
                      icon: Icons.flutter_dash_rounded,
                      selected: _typeFilter == _AnimalTypeFilter.twoLegs,
                      onTap: () => setState(() =>
                      _typeFilter = _AnimalTypeFilter.twoLegs),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 10),

        // ── Grid loài ──
        Expanded(
          child: displayed.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔍', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(t.tr('Không tìm thấy loài nào'),
                    style: TextStyle(
                        fontSize: 17,
                        color: colorScheme.onSurfaceVariant)),
              ],
            ),
          )
              : GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            physics: const BouncingScrollPhysics(),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemCount: displayed.length,
            itemBuilder: (context, i) => SmartTypeCard(
              config: displayed[i],
              index: i,
              onTap: () => _selectAnimalType(displayed[i]),
            ),
          ),
        ),
      ],
    );
  }

  // 2. Câu hỏi Quiz
  Widget _buildQuestion(ColorScheme colorScheme, LocaleProvider t) {
    final q = _questions[_questionIndex];
    final displayOptions = _currentValidOptions.isNotEmpty ? _currentValidOptions : q.options;
    final progress = (_filters.length) / _questions.length.toDouble();

    return Column(
      children: [
        SmartNavBar(
          leading: GestureDetector(
            onTap: () {
              if (_filters.isNotEmpty) {
                final lastKey = _filters.keys.last;
                setState(() {
                  _filters.remove(lastKey);
                  _currentValidOptions = [];
                  final prevIdx = _questions.indexWhere((q) => q.column == lastKey);
                  if (prevIdx >= 0) _questionIndex = prevIdx;
                });
                _fetchResults(_filters).then((_) => _advanceToNextUsefulQuestion());
              } else {
                _reset();
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.back, color: colorScheme.primary, size: 22),
                Text(t.tr('Quay lại'), style: TextStyle(color: colorScheme.primary, fontSize: 17)),
              ],
            ),
          ),
          title: Text('${t.tr(_selectedConfig!.nameVi)} ${_selectedConfig!.emoji}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
          trailing: (_results.isNotEmpty && _filters.isNotEmpty)
              ? GestureDetector(onTap: () => setState(() => _showResults = true), child: Text('${t.tr('Xem')} ${_results.length}', style: TextStyle(color: colorScheme.primary, fontSize: 17)))
              : const SizedBox.shrink(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: colorScheme.surfaceContainer,
                  valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _filters.isEmpty
                    ? t.tr('Trả lời để tìm loài phù hợp')
                    : '${_results.length} ${t.tr('kết quả đang khớp')}',
                style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Text(q.emoji, style: const TextStyle(fontSize: 44)).animate().scale(begin: const Offset(0.7, 0.7), duration: 300.ms),
              const SizedBox(height: 12),
              Text(t.tr(q.question), textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: colorScheme.onSurface, letterSpacing: -0.3)).animate().fadeIn(duration: 300.ms).slideY(begin: -0.15),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: colorScheme.shadow.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    children: displayOptions.asMap().entries.map((entry) {
                      return SmartOptionRow(
                        question: q, option: entry.value, isLast: entry.key == displayOptions.length - 1, index: entry.key, onTap: () => _answer(q, entry.value.value),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _skip,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: colorScheme.shadow.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Text(t.tr('Không chắc, bỏ qua'), textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16, fontWeight: FontWeight.w400)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 3. Màn hình Kết quả
  Widget _buildResults(ColorScheme colorScheme, LocaleProvider t) {
    return Column(
      children: [
        SmartNavBar(
          leading: GestureDetector(
            onTap: _reset,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.house, color: colorScheme.primary, size: 20),
                const SizedBox(width: 4),
                Text(t.tr('Trang chủ'), style: TextStyle(color: colorScheme.primary, fontSize: 17)),
              ],
            ),
          ),
          title: Text(
            _results.isEmpty ? t.tr('Không tìm thấy') : '${_results.length} ${t.tr('kết quả')}',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
          ),
          trailing: _results.isNotEmpty
              ? GestureDetector(onTap: () => _selectAnimalType(_selectedConfig!), child: Text(t.tr('Tìm lại'), style: TextStyle(color: colorScheme.primary, fontSize: 17)))
              : const SizedBox.shrink(),
        ),
        if (_results.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Text(t.tr('Chọn một con để xem chi tiết'), style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
              ],
            ),
          ),
        Expanded(
          child: _results.isEmpty
              ? SmartNoResultsView(onRetry: () => _selectAnimalType(_selectedConfig!))
              : GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.72,
            ),
            itemCount: _results.length,
            itemBuilder: (context, i) => SmartResultCard(
              animal: _results[i], index: i, selectedConfig: _selectedConfig, onTap: () => _showDetail(_results[i], t),
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// WIDGET: Sort chip
// ════════════════════════════════════════════════════════════
class _SortChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13,
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