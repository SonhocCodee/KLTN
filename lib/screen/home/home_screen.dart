import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:lottie/lottie.dart';
import '../../services/animal_home_service.dart';
import '../animal_list/Breed list screen.dart';
import 'animal_category_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final AnimalHomeService _service = AnimalHomeService();
  List<AnimalCategoryData> _categoryData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- GIỮ NGUYÊN LOGIC DATA THEO YÊU CẦU ---
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

  String _getShortDesc(String id) {
    if (id.contains('dog')) return 'Người bạn trung thành và đáng yêu nhất của bé.';
    if (id.contains('cat')) return 'Những người bạn nhỏ thích cuộn tròn và làm nũng.';
    if (id.contains('bird')) return 'Những nhạc sĩ của bầu trời với tiếng hót líu lo.';
    if (id.contains('insect')) return 'Thế giới tí hon đầy những điều kỳ diệu.';
    return 'Cùng khám phá những điều thú vị về bạn này nhé!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: Stack(
        children: [
          // Nền Pattern chấm bi nhẹ
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(painter: _PatternPainter()),
            ),
          ),

          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
                : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Logo App & Search Box
                SliverToBoxAdapter(child: _buildTopBar()),

                // Header Chào bé
                SliverToBoxAdapter(child: _buildWelcomeText()),

                // Quick Access sử dụng Animation Lottie từ Local
                SliverToBoxAdapter(child: _buildAnimatedQuickAccess()),

                // Danh sách các loài
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildAnimalSection(_categoryData[index]),
                      childCount: _categoryData.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 15, 24, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo App
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.pets, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'AniQuest',
                    style: TextStyle(fontSize: 22,  color: Color(0xFF2D4B2A)),
                  ),
                ],
              ),
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person_outline, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Search Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bạn động vật...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
                icon: const Icon(Icons.search, color: Color(0xFF4CAF50)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeText() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chào Bạn! 👋', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF2D4B2A))),
          Text('Hôm nay bạn muốn xem loài nào?', style: TextStyle(fontSize: 16, color: Colors.blueGrey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAnimatedQuickAccess() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categoryData.length,
        itemBuilder: (context, index) {
          final cat = _categoryData[index].category;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Container(
                  width: 75, height: 75,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: cat.gradient[0].withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: ClipOval(
                    child: _getLottieForCategory(cat.id),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                    cat.nameVi,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D4B2A), fontSize: 14)
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Lấy Lottie từ thư mục assets/icons/
  Widget _getLottieForCategory(String id) {
    String fileName = 'default_anim.json';
    if (id.contains('dog')) fileName = 'dog_anim.json';
    if (id.contains('cat')) fileName = 'cat_anim.json';
    if (id.contains('bird')) fileName = 'bird_anim.json';

    return Lottie.asset(
      'assets/icons/$fileName',
      fit: BoxFit.cover,
      repeat: true,
      animate: true,
      // Hiển thị icon mặc định nếu file không tồn tại
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, color: Colors.grey),
    );
  }

  Widget _buildAnimalSection(AnimalCategoryData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                // Sử dụng icon chân thú tĩnh cạnh tên loài
                Icon(Icons.pets, color: data.category.gradient[0].withOpacity(0.6), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          data.category.nameVi,
                          style: const TextStyle(fontSize: 22, color: Color(0xFF1E293B))
                      ),
                      Text(
                          _getShortDesc(data.category.id),
                          style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)
                      ),
                    ],
                  ),
                ),
                _buildBadge(data),
              ],
            ),
          ),
          _InteractiveAnimalCard(data: data),
        ],
      ),
    );
  }

  Widget _buildBadge(AnimalCategoryData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: data.category.gradient[0].withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)
      ),
      child: Text(
          data.displayText,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: data.category.gradient[0])
      ),
    );
  }
}

class _InteractiveAnimalCard extends StatefulWidget {
  final AnimalCategoryData data;
  const _InteractiveAnimalCard({required this.data});

  @override
  State<_InteractiveAnimalCard> createState() => _InteractiveAnimalCardState();
}

class _InteractiveAnimalCardState extends State<_InteractiveAnimalCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasData = widget.data.hasData;
    final category = widget.data.category;

    return GestureDetector(
      onTapDown: (_) => hasData ? _controller.forward() : null,
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        if (hasData) {
          HapticFeedback.lightImpact();
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => BreedListScreen(category: category, totalCount: widget.data.count)
              )
          );
        }
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            image: DecorationImage(
                image: AssetImage(category.imageAssetPath),
                fit: BoxFit.cover
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8)
              )
            ],
          ),
          child: Stack(
            children: [
              // Lớp phủ Gradient giúp text/nút rõ hơn
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.7)]
                  ),
                ),
              ),
              // Nút Khám phá ngay với hiệu ứng Glassmorphism
              Positioned(
                bottom: 20,
                right: 20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hasData ? 'Khám phá ngay' : 'Đang cập nhật',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (!hasData)
                Container(
                  decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(30)
                  ),
                  child: const Center(
                      child: Icon(Icons.lock_clock, color: Colors.white, size: 40)
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.green.withOpacity(0.15);
    for (double i = 0; i < size.width; i += 40) {
      for (double j = 0; j < size.height; j += 40) {
        canvas.drawCircle(Offset(i, j), 1.2, paint);
      }
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}