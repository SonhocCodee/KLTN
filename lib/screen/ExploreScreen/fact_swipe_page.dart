import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'explore_service.dart';
import 'quiz_page.dart';

class FactSwipePage extends StatefulWidget {
  const FactSwipePage({super.key});

  @override
  State<FactSwipePage> createState() => _FactSwipePageState();
}

class _FactSwipePageState extends State<FactSwipePage>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // Màu sắc nhẹ nhàng, tươi sáng phù hợp chủ đề tự nhiên
  final List<Color> _accentColors = [
    const Color(0xFFE8F5E9), // Xanh lá nhạt
    const Color(0xFFE3F2FD), // Xanh dương nhạt
    const Color(0xFFFFF3E0), // Cam nhạt
    const Color(0xFFF3E5F5), // Tím nhạt
    const Color(0xFFE0F2F1), // Teal nhạt
    const Color(0xFFFFFDE7), // Vàng nhạt
    const Color(0xFFEFEBE9), // Nâu nhạt
    const Color(0xFFF1F8E9), // Lime nhạt
    const Color(0xFFE8EAF6), // Indigo nhạt
    const Color(0xFFFCE4EC), // Hồng nhạt
  ];

  @override
  void initState() {
    super.initState();
    final service = context.read<ExploreService>();
    _currentIndex = (service.readCount).clamp(0, 9);
    _pageController = PageController(initialPage: _currentIndex);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    context.read<ExploreService>().markFactRead(index);
  }

  void _nextPage() async {
    if (_currentIndex < 9) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
      );
    } else {
      // Đảm bảo fact cuối (index 9) đã được mark trước khi show sheet.
      // markFactRead có guard nên gọi lại nhiều lần không bị double count.
      final service = context.read<ExploreService>();
      await service.markFactRead(_currentIndex);

      // Nếu quiz questions chưa fetch xong (fetch được trigger bên trong markFactRead),
      // chờ 1 chút để Supabase query trả về kết quả
      if (service.quizQuestions.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 400));
      }

      if (mounted) _showCompletionSheet();
    }
  }

  void _showCompletionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CompletionSheet(
        onQuiz: () {
          // Capture service TRƯỚC khi pop — tránh dùng context sau khi widget bị dispose
          final service = context.read<ExploreService>();
          Navigator.pop(context);  // đóng bottom sheet
          Navigator.pop(context);  // đóng FactSwipePage
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: service,
                child: const QuizPage(),
              ),
            ),
          );
        },
        onBack: () {
          Navigator.pop(context);  // đóng bottom sheet
          Navigator.pop(context);  // đóng FactSwipePage
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ExploreService>();
    final animals = service.dailyAnimals;

    if (animals.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FB),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2D3142))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(service),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const BouncingScrollPhysics(),
                itemCount: animals.length,
                itemBuilder: (_, i) => AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double value = 1.0;
                    if (_pageController.position.haveDimensions) {
                      value = (_pageController.page! - i).abs();
                      value = (1 - (value * 0.1)).clamp(0.0, 1.0);
                    }
                    return Transform.scale(
                      scale: value,
                      child: _buildFactCard(animals[i], i),
                    );
                  },
                ),
              ),
            ),
            _buildBottomControls(service),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ExploreService service) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.black87),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Khám phá loài vật',
                  style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Thẻ số ${_currentIndex + 1} trên ${service.dailyAnimals.length}',
                  style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2D3142),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${((_currentIndex + 1) / 10 * 100).toInt()}%',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactCard(DailyAnimal animal, int index) {
    final accentColor = _accentColors[index % _accentColors.length];

    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  Stack(
                    children: [
                      if (animal.imageUrl != null)
                        Image.network(
                          animal.imageUrl!,
                          height: 280,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        )
                      else
                        _imagePlaceholder(),
                      Positioned(
                        top: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite_border_rounded, size: 20),
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                animal.animalType?.toUpperCase() ?? 'ĐỘNG VẬT',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          animal.nameVietnamese,
                          style: const TextStyle(
                            color: Color(0xFF2D3142),
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        if (animal.nameEnglish != null)
                          Text(
                            animal.nameEnglish!,
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.3),
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),

                        const SizedBox(height: 24),
                        const Text(
                          "Bạn có biết?",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          animal.funFactVietnamese ?? 'Chưa có thông tin.',
                          style: const TextStyle(
                            color: Color(0xFF4F5D75),
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 24),
                        Divider(color: Colors.black.withOpacity(0.05)),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            if (animal.primaryHabitat != null)
                              _infoChip(Icons.location_on_rounded, animal.primaryHabitat!, accentColor),
                            if (animal.conservationStatus != null)
                              _infoChip(Icons.shield_rounded, animal.conservationStatus!, accentColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 280,
      width: double.infinity,
      color: const Color(0xFFF0F2F5),
      child: const Center(child: Icon(Icons.pets_rounded, size: 64, color: Colors.black12)),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(ExploreService service) {
    final isLast = _currentIndex == service.dailyAnimals.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 64,
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLast ? const Color(0xFF4CAF50) : const Color(0xFF2D3142),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLast ? 'KHÁM PHÁ XONG' : 'TIẾP TỤC',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    const SizedBox(width: 8),
                    Icon(isLast ? Icons.check_circle_outline : Icons.arrow_forward_ios, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionSheet extends StatelessWidget {
  final VoidCallback onQuiz;
  final VoidCallback onBack;

  const _CompletionSheet({required this.onQuiz, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: const Center(child: Text('🌿', style: TextStyle(fontSize: 40))),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tuyệt vời!',
            style: TextStyle(color: Color(0xFF2D3142), fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Text(
            'Bạn đã hoàn thành hành trình khám phá 10 loài vật hôm nay.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: onQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D3142),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              child: const Text(
                'Bắt đầu thử thách Quiz',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onBack,
            child: Text(
              'Để sau nhé',
              style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}