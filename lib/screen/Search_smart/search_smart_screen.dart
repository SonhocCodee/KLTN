import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:kltn_app/screen/Search_smart/widgets/search_smart_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'models/search_smart_models.dart';
import '../Animal_detail/Animal detail screen.dart';
import '../home/animal_category_model.dart';

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
    });
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
    await _fetchResults(_filters);
    setState(() => _isLoading = false);
    await _advanceToNextUsefulQuestion();
  }

  Future<int> _countResultsWithFilter(Map<String, dynamic> baseFilters, QuestionConfig q, dynamic value) async {
    if (_selectedConfig == null) return 0;
    final testFilters = Map<String, dynamic>.from(baseFilters);
    testFilters[q.column] = value;
    try {
      final data = await _buildQuery(testFilters).limit(50);
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
      if (_results.length <= 3) {
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
    var query = _client.from(config.dbTable).select('id, name_vietnamese, name_english, scientific_name, image_url, description_short, animal_type');

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
      final data = await _buildQuery(filters).limit(50);
      setState(() => _results = List<Map<String, dynamic>>.from(data as List));
    } catch (e) {
      setState(() => _results = []);
    }
  }

  void _showDetail(Map<String, dynamic> animal) {
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
                          'Đóng',
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
                        label: const Text('Xem chi tiết',
                            style: TextStyle(fontSize: 16)),
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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      // CHỦ CHỐT: Dùng bottom: false để màu nền Scaffold tràn đáy
      body: SafeArea(bottom: false, child: _buildBody(colorScheme)),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_selectedConfig == null) return _buildTypeSelection(colorScheme);
    if (_isLoading) return const SmartLoadingView();
    if (_showResults || _questionIndex >= _questions.length) return _buildResults(colorScheme);
    return _buildQuestion(colorScheme);
  }

  // 1. Chọn Loài
  Widget _buildTypeSelection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tìm động vật',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: colorScheme.onSurface, letterSpacing: -0.5),
              ).animate().fadeIn(duration: 350.ms),
              const SizedBox(height: 4),
              Text(
                'Chọn loài bạn muốn khám phá',
                style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w400),
              ).animate().fadeIn(delay: 100.ms),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            // CHỦ CHỐT: Padding đáy lớn để nội dung không bị che
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.05,
            ),
            itemCount: allAnimalTypes.length,
            itemBuilder: (context, i) => SmartTypeCard(config: allAnimalTypes[i], index: i, onTap: () => _selectAnimalType(allAnimalTypes[i])),
          ),
        ),
      ],
    );
  }

  // 2. Câu hỏi Quiz
  Widget _buildQuestion(ColorScheme colorScheme) {
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
                Text('Quay lại', style: TextStyle(color: colorScheme.primary, fontSize: 17)),
              ],
            ),
          ),
          title: Text('${_selectedConfig!.nameVi} ${_selectedConfig!.emoji}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
          trailing: _results.isNotEmpty
              ? GestureDetector(onTap: () => setState(() => _showResults = true), child: Text('Xem ${_results.length}', style: TextStyle(color: colorScheme.primary, fontSize: 17)))
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
              Text('${_results.length} kết quả đang khớp', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
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
              Text(q.question, textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: colorScheme.onSurface, letterSpacing: -0.3)).animate().fadeIn(duration: 300.ms).slideY(begin: -0.15),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            // CHỦ CHỐT: Padding đáy lớn
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
                    child: Text('Không chắc, bỏ qua', textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16, fontWeight: FontWeight.w400)),
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
  Widget _buildResults(ColorScheme colorScheme) {
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
                Text('Trang chủ', style: TextStyle(color: colorScheme.primary, fontSize: 17)),
              ],
            ),
          ),
          title: Text(
            _results.isEmpty ? 'Không tìm thấy' : '${_results.length} kết quả',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
          ),
          trailing: _results.isNotEmpty
              ? GestureDetector(onTap: () => _selectAnimalType(_selectedConfig!), child: Text('Tìm lại', style: TextStyle(color: colorScheme.primary, fontSize: 17)))
              : const SizedBox.shrink(),
        ),
        if (_results.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Text('Chọn một con để xem chi tiết', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
              ],
            ),
          ),
        Expanded(
          child: _results.isEmpty
              ? SmartNoResultsView(onRetry: () => _selectAnimalType(_selectedConfig!))
              : GridView.builder(
            // CHỦ CHỐT: Padding đáy lớn
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.72,
            ),
            itemCount: _results.length,
            itemBuilder: (context, i) => SmartResultCard(
              animal: _results[i], index: i, selectedConfig: _selectedConfig, onTap: () => _showDetail(_results[i]),
            ),
          ),
        ),
      ],
    );
  }
}