import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../services/animal_home_service.dart';
import '../Animal_detail/Animal detail screen.dart';
import '../home/animal_category_model.dart';

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

  List<Map<String, dynamic>> _animals = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAnimals();
  }

  Future<void> _loadAnimals() async {
    setState(() => _isLoading = true);

    try {
      final animals = await _service.getAnimalsByType(widget.category.id);
      setState(() {
        _animals = animals;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading animals: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredAnimals {
    if (_searchQuery.isEmpty) return _animals;

    return _animals.where((animal) {
      final nameVi = (animal['name_vietnamese'] ?? '').toString().toLowerCase();
      final nameEn = (animal['name_english'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      return nameVi.contains(query) || nameEn.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // Giữ gradient xanh xám ở Light Mode, đổi thành nền Dark trơn ở Dark Mode
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [colorScheme.surface, colorScheme.surface]
                : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              BreedListHeader(
                category: widget.category,
                totalCount: widget.totalCount,
              ),
              BreedListSearchBar(
                category: widget.category,
                searchQuery: _searchQuery,
                onChanged: (value) => setState(() => _searchQuery = value),
                onClear: () => setState(() => _searchQuery = ''),
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
                    onRefresh: () async {
                      await _loadAnimals();
                    },
                    color: widget.category.gradient[0],
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AnimalDetailScreen(
                                  animalId: _filteredAnimals[index]['id'],
                                  category: widget.category,
                                ),
                              ),
                            );
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

  // Nút clear cache dự phòng (Nếu ông vẫn cần dùng thì gọi nó ở đâu đó, hiện tại tôi vẫn giữ code gốc)
  Widget _buildClearCacheButton() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await DefaultCacheManager().emptyCache();
            await _loadAnimals();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('✅ Cache cleared & reloaded'), backgroundColor: widget.category.gradient[0]),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(Icons.refresh, size: 24, color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}