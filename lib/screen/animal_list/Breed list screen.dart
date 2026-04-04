import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../services/animal_home_service.dart';
import '../home/animal_category_model.dart';
import 'Animal detail screen.dart';

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

      // 🔍 DEBUG
      print('═══════════════════════════════════════');
      print('📊 Loaded ${animals.length} ${widget.category.nameVi}');
      if (animals.isNotEmpty) {
        print('📋 Sample check (first 3):');
        for (int i = 0; i < (animals.length > 3 ? 3 : animals.length); i++) {
          final animal = animals[i];
          print('${i + 1}. ${animal['name_vietnamese']}');
          print('   image_url: ${animal['image_url']}');
          print('   has image: ${animal['image_url'] != null && animal['image_url'].toString().isNotEmpty}');
        }
      }
      print('═══════════════════════════════════════\n');

      setState(() {
        _animals = animals;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading animals: $e');
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFE2E8F0),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),

              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF34D399),
                    ),
                  ),
                )
              else if (_filteredAnimals.isEmpty)
                _buildEmptyState()
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      // ✅ ĐÃ SỬA: Chỉ tải lại dữ liệu, KHÔNG xóa cache ảnh
                      await _loadAnimals();
                    },
                    color: widget.category.gradient[0],
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _filteredAnimals.length,
                      itemBuilder: (context, index) {
                        return _buildAnimalCard(_filteredAnimals[index]);
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.arrow_back, size: 24),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: widget.category.gradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.category.icon,
              color: Colors.white,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.category.nameVi,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '${widget.totalCount} loài',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.category.gradient[0],
                  ),
                ),
              ],
            ),
          ),


        ],
      ),
    );
  }

  Widget _buildClearCacheButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Chỉ xóa khi bấm nút này (Thủ công)
            await DefaultCacheManager().emptyCache();
            await _loadAnimals();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('✅ Cache cleared & reloaded'),
                  backgroundColor: widget.category.gradient[0],
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.refresh, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
          decoration: InputDecoration(
            hintText: 'Tìm kiếm ${widget.category.nameVi.toLowerCase()}...',
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: widget.category.gradient[0],
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, color: Color(0xFF94A3B8)),
              onPressed: () {
                setState(() => _searchQuery = '');
              },
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Chưa có dữ liệu'
                  : 'Không tìm thấy kết quả',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalCard(Map<String, dynamic> animal) {
    final nameVi = animal['name_vietnamese'] ?? 'Chưa có tên';
    final nameEn = animal['name_english'] ?? '';

    // 🔥 CRITICAL: Check và force reload nếu cần
    final dynamic imageUrlRaw = animal['image_url'];
    final String imageUrl = (imageUrlRaw != null && imageUrlRaw.toString().isNotEmpty)
        ? imageUrlRaw.toString()
        : '';

    final conservationStatus = animal['conservation_status'] ?? '';
    final isEndangered = animal['is_endangered'] ?? false;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnimalDetailScreen(
              animalId: animal['id'],
              category: widget.category,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.category.gradient[0].withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      // Main image
                      Positioned.fill(
                        child: imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                          imageUrl: imageUrl,

                          // ✅ ĐÃ SỬA: Dùng URL làm key để cache hoạt động đúng
                          cacheKey: imageUrl,

                          fit: BoxFit.cover,

                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              color: widget.category.gradient[0],
                              strokeWidth: 2,
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            print('❌ Image error: $nameEn');
                            print('   URL: $url');
                            print('   Error: $error');
                            return _buildPlaceholderImage();
                          },
                          // User-Agent chính chủ để tránh lỗi 429
                          httpHeaders: const {
                            'User-Agent': 'MyAnimalApp/1.0 (son623200@gmail.com)',
                          },
                          // Tối ưu bộ nhớ
                          maxWidthDiskCache: 600,
                          maxHeightDiskCache: 600,
                          memCacheHeight: 600,
                          memCacheWidth: 600,
                        )
                            : _buildPlaceholderImage(),
                      ),

                      // Gradient overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Endangered badge
                      if (isEndangered)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Nguy cấp',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Info
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          nameVi,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nameEn,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: widget.category.gradient[0],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (conservationStatus.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: widget.category.gradient[0].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              conservationStatus,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: widget.category.gradient[0],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.category.gradient,
        ),
      ),
      child: Center(
        child: Icon(
          widget.category.icon,
          size: 50,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }
}