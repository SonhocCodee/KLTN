import 'package:flutter/material.dart';
import 'package:kltn_app/screen/Breed_List/widgets/Breed_list_filter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/animal_home_service.dart';
import '../Animal_detail/Animal detail screen.dart';
import '../home/animal_category_model.dart';
import '../profile/favorite_service.dart';

// Import các widgets đã tách
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
  String _searchQuery = '';
  AnimalFilterState _filterState = const AnimalFilterState();

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

  Future<void> _loadAnimals() async {
    setState(() => _isLoading = true);
    try {
      // Select đủ các cột cần cho filter + sort + hiển thị
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
          .order('name_vietnamese');

      if (!mounted) return;
      setState(() {
        _animals = List<Map<String, dynamic>>.from(data as List);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading animals: $e');
      // fallback về service cũ nếu lỗi
      try {
        final animals = await _service.getAnimalsByType(widget.category.id);
        setState(() { _animals = animals; _isLoading = false; });
      } catch (_) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Search trước, rồi filter+sort sau
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

              // ── Bộ lọc inline ──
              BreedListFilterBar(
                category: widget.category,
                filterState: _filterState,
                favoriteIds: _favoriteIds,
                onChanged: (newState) =>
                    setState(() => _filterState = newState),
              ),
              const SizedBox(height: 8),

              // ── Kết quả đếm nhỏ (chỉ hiện khi đang filter/search) ──
              if (_searchQuery.isNotEmpty || _filterState.hasActiveFilters)
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tìm thấy ${_filteredAnimals.length} loài',
                      style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant),
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
                BreedListEmptyState(searchQuery: _searchQuery)
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
                          isFavorite: _favoriteIds
                              .contains(_filteredAnimals[index]['id'].toString()),
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