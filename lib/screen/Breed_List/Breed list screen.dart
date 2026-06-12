import 'package:flutter/material.dart' hide debugPrint;
import 'package:kltn_app/screen/Breed_List/widgets/Breed_list_filter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/animal_home_service.dart';
import '../Animal_detail/Animal detail screen.dart';
import '../home/animal_category_model.dart';
import '../language/Locale_provider.dart';
import '../profile/favorite_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/breed_list_header.dart';
import 'widgets/breed_list_search_bar.dart';
import 'widgets/breed_list_empty_state.dart';
import 'widgets/breed_list_animal_card.dart';

class BreedListScreen extends StatefulWidget {
  final AnimalCategory category;
  final int totalCount;

  const BreedListScreen({
    super.key,
    required this.category,
    required this.totalCount,
  });

  @override
  State<BreedListScreen> createState() => _BreedListScreenState();
}

class _BreedListScreenState extends State<BreedListScreen> {
  final AnimalHomeService _service = AnimalHomeService();
  final FavoriteService _favoriteService = FavoriteService();

  List<Map<String, dynamic>> _animals = [];
  Set<String> _favoriteIds = {};
  bool _isLoading = true;
  bool _isOfflineError = false;
  bool _isUsingCache = false;
  String _searchQuery = '';
  AnimalFilterState _filterState = const AnimalFilterState();

  String get _cacheKey => 'breed_list_cache_${widget.category.id}';
  @override
  void initState() {
    super.initState();
    _loadAnimals();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final ids = await _favoriteService.getFavoriteIds();
    if (mounted) setState(() => _favoriteIds = ids);
  }

  Future<void> _saveAnimalsCache(List<Map<String, dynamic>> animals) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(animals));
    } catch (e) {
      debugPrint('⚠️ Save animals cache error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _readAnimalsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      debugPrint('⚠️ Read animals cache error: $e');
      return [];
    }
  }

  Future<void> _loadAnimals() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _isOfflineError = false;
        _isUsingCache = false;
      });
    }

    // 1. Đọc cache trước để nếu mất mạng vẫn có gì đó hiển thị.
    final cachedAnimals = await _readAnimalsCache();

    if (cachedAnimals.isNotEmpty && mounted) {
      setState(() {
        _animals = cachedAnimals;
        _isLoading = false;
        _isOfflineError = false;
        _isUsingCache = true;
      });
    }

    try {
      // 2. Gọi Supabase nhưng có timeout, tránh xoay mãi khi mất mạng.
      final data = await Supabase.instance.client
          .from('animals')
          .select('''
          id, name_vietnamese, name_english, scientific_name,
          image_url, animal_type,
          relative_size, diet_type, conservation_status,
          weight_avg_kg, lifespan_avg_years,
          is_endangered, domestication_status, temperament
        ''')
          .eq('animal_type', widget.category.id)
          .order('name_vietnamese')
          .timeout(const Duration(seconds: 5));

      final list = List<Map<String, dynamic>>.from(data as List);

      // 3. Có mạng + có dữ liệu mới thì lưu cache.
      await _saveAnimalsCache(list);

      if (!mounted) return;
      setState(() {
        _animals = list;
        _isLoading = false;
        _isOfflineError = false;
        _isUsingCache = false;
      });
    } on TimeoutException catch (e) {
      debugPrint('⚠️ Timeout loading animals: $e');

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isOfflineError = cachedAnimals.isEmpty;
        _isUsingCache = cachedAnimals.isNotEmpty;
        _animals = cachedAnimals;
      });
    } catch (e) {
      debugPrint('❌ Error loading animals: $e');

      // 4. Dự phòng service cũ nếu có thể.
      try {
        final animals = await _service
            .getAnimalsByType(widget.category.id)
            .timeout(const Duration(seconds: 5));

        await _saveAnimalsCache(animals);

        if (!mounted) return;
        setState(() {
          _animals = animals;
          _isLoading = false;
          _isOfflineError = false;
          _isUsingCache = false;
        });
      } catch (e2) {
        debugPrint('❌ Fallback loading animals error: $e2');

        if (!mounted) return;
        setState(() {
          _animals = cachedAnimals;
          _isLoading = false;
          _isOfflineError = cachedAnimals.isEmpty;
          _isUsingCache = cachedAnimals.isNotEmpty;
        });
      }
    }
  }

  // Search trước, rồi filter+sort sau
  List<Map<String, dynamic>> get _filteredAnimals {
    // 1. Search
    var list = _animals;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((a) {
        final nameVi = (a['name_vietnamese'] ?? '').toString().toLowerCase();
        final nameEn = (a['name_english'] ?? '').toString().toLowerCase();
        return nameVi.contains(q) || nameEn.contains(q);
      }).toList();
    }

    // 2. Filter + sort
    return _filterState.apply(list, favoriteIds: _favoriteIds);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = context.watch<LocaleProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [colorScheme.surface, colorScheme.surface]
                : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              BreedListHeader(
                category: widget.category,
                totalCount: widget.totalCount,
              ),
              BreedListSearchBar(
                category: widget.category,
                searchQuery: _searchQuery,
                onChanged: (v) => setState(() => _searchQuery = v),
                onClear: () => setState(() => _searchQuery = ''),
              ),
              const SizedBox(height: 8),

              if (_isUsingCache)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.offline_bolt_rounded,
                          size: 18,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.tr(
                              'Đang hiển thị dữ liệu đã lưu do không có mạng',
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Bộ lọc inline
              BreedListFilterBar(
                category: widget.category,
                filterState: _filterState,
                favoriteIds: _favoriteIds,
                onChanged: (newState) =>
                    setState(() => _filterState = newState),
              ),
              const SizedBox(height: 8),

              // Kết quả đếm nhỏ (chỉ hiện khi đang filter/search)
              if (_searchQuery.isNotEmpty || _filterState.hasActiveFilters)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 2,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${t.tr('Tìm thấy')} ${_filteredAnimals.length} ${t.tr('loài')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),

              if (_isLoading)
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: widget.category.gradient[0],
                    ),
                  ),
                )
              else if (_filteredAnimals.isEmpty)
                BreedListEmptyState(
                  searchQuery: _searchQuery,
                  isOfflineError: _isOfflineError,
                  onRetry: _loadAnimals,
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadAnimals,
                    color: widget.category.gradient[0],
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: _filteredAnimals.length,
                      itemBuilder: (context, index) {
                        return BreedListAnimalCard(
                          animal: _filteredAnimals[index],
                          category: widget.category,
                          isFavorite: _favoriteIds.contains(
                            _filteredAnimals[index]['id'].toString(),
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AnimalDetailScreen(
                                  animalId: _filteredAnimals[index]['id'],
                                  category: widget.category,
                                ),
                              ),
                            );
                            // Reload favorites khi quay lại để badge đồng bộ
                            await _loadFavorites();
                          },
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
