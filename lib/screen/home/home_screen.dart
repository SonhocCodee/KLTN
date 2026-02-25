import 'package:flutter/material.dart';
import 'dart:ui';
import '../../services/animal_home_service.dart';
import '../animal_list/Breed list screen.dart';
import '../models/animal_category_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final AnimalHomeService _service = AnimalHomeService();

  List<AnimalCategoryData> _categoryData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Lấy số lượng động vật theo loại từ database
      final counts = await _service.getAnimalCounts();

      // Tạo data CHỈ cho các categories đã ENABLED
      List<AnimalCategoryData> data = [];

      for (var category in AnimalCategory.getEnabledCategories()) {
        final count = counts[category.id] ?? 0;

        data.add(AnimalCategoryData(
          category: category,
          count: count,
        ));
      }

      setState(() {
        _categoryData = data;
        _isLoading = false;
      });

      // Debug
      print('═══════════════════════════════════════');
      print('📊 LOADED DATA:');
      for (var d in data) {
        print('   ${d.category.nameVi}: ${d.displayText} (${d.completionPercentage.toStringAsFixed(1)}%)');
      }
      print('═══════════════════════════════════════');
    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() {
        _isLoading = false;
        // Fallback: hiển thị với count = 0
        _categoryData = AnimalCategory.getEnabledCategories().map((cat) {
          return AnimalCategoryData(
            category: cat,
            count: 0,
          );
        }).toList();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
          bottom: false,
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Content
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF34D399),
                    ),
                  ),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    color: const Color(0xFF34D399),
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categoryData.length,
                      itemBuilder: (context, index) {
                        return _buildCategorySection(_categoryData[index], index);
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOut,
        )),
        child: Row(
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF34D399), Color(0xFF14B8A6)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF34D399).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.pets, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AniQuest',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Khám phá thế giới động vật',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Search Button
            _buildSearchButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mở tìm kiếm thám tử...'),
                backgroundColor: Color(0xFF34D399),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(Icons.search, color: Color(0xFF1E293B), size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(AnimalCategoryData data, int sectionIndex) {
    final hasData = data.hasData;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (sectionIndex * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: data.category.gradient),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    data.category.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  data.category.nameVi,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(width: 8),

                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                // 🎯 BADGE: Hiển thị số thực tế / tổng
                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasData
                        ? const Color(0xFF34D399).withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    data.displayText, // 👈 "75 giống" hoặc "100/10000 loài"
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: hasData ? const Color(0xFF059669) : Colors.grey.shade600,
                    ),
                  ),
                ),

                // Progress indicator (nếu chưa đầy đủ)
                if (hasData && data.completionPercentage < 80)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: SizedBox(
                      width: 50,
                      height: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: data.completionPercentage / 100,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            data.category.gradient[0],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Card
            _buildAnimalCard(data),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalCard(AnimalCategoryData data) {
    final hasData = data.hasData;

    return GestureDetector(
      onTap: () {
        if (hasData) {
          // Navigate to breed list screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BreedListScreen(
                category: data.category,
                totalCount: data.count,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dữ liệu đang được cập nhật...'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: data.category.gradient[0].withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Image.asset(
                  data.category.imageAssetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback gradient nếu không có ảnh
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: data.category.gradient,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          data.category.icon,
                          size: 80,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
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

              // Lock overlay nếu chưa có data
              if (!hasData)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.6),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_clock,
                            color: Colors.white.withOpacity(0.9),
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Sắp ra mắt',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Glass button
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            hasData ? 'Xem tất cả' : 'Khóa',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            hasData ? Icons.arrow_forward : Icons.lock,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
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
}