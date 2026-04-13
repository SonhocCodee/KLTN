
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

  // Màu gradient cho từng card — xoay vòng
  final List<List<Color>> _cardGradients = [
    [const Color(0xFF1a1a2e), const Color(0xFF0f3460)],
    [const Color(0xFF0d2117), const Color(0xFF0a3020)],
    [const Color(0xFF1a0d2e), const Color(0xFF2d1f3d)],
    [const Color(0xFF1a1200), const Color(0xFF2a1f00)],
    [const Color(0xFF001a1a), const Color(0xFF002a2a)],
    [const Color(0xFF1a0011), const Color(0xFF2d001e)],
    [const Color(0xFF00111a), const Color(0xFF001e2d)],
    [const Color(0xFF1a1a00), const Color(0xFF2a2a00)],
    [const Color(0xFF0d001a), const Color(0xFF1a002d)],
    [const Color(0xFF001a0d), const Color(0xFF002d1a)],
  ];

  @override
  void initState() {
    super.initState();
    final service = context.read<ExploreService>();
    // Bắt đầu từ fact chưa đọc
    _currentIndex = (service.readCount).clamp(0, 9);

    _pageController = PageController(initialPage: _currentIndex);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
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
    // Mark fact as read khi người dùng đến trang đó
    context.read<ExploreService>().markFactRead(index);
  }

  void _nextPage() {
    if (_currentIndex < 9) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _showCompletionSheet();
    }
  }

  void _showCompletionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CompletionSheet(
        onQuiz: () {
          Navigator.pop(context); // đóng sheet
          Navigator.pop(context); // về explore page
          // Navigate to quiz
          final service = context.read<ExploreService>();
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
          Navigator.pop(context);
          Navigator.pop(context);
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
        backgroundColor: Color(0xFF0A0A0F),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF7C6FFF))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
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
                itemBuilder: (_, i) => _buildFactCard(animals[i], i),
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
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF16161F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A3A)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sự thật thú vị',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${_currentIndex + 1} / ${service.dailyAnimals.length}',
                  style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
                ),
              ],
            ),
          ),
          // Progress dots
          Row(
            children: List.generate(
              service.dailyAnimals.length,
                  (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(left: 4),
                width: i == _currentIndex ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i <= service.readCount - 1
                      ? const Color(0xFF7C6FFF)
                      : const Color(0xFF2A2A3A),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactCard(DailyAnimal animal, int index) {
    final gradColors = _cardGradients[index % _cardGradients.length];

    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Animal image
                if (animal.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      animal.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  _imagePlaceholder(),
                  const SizedBox(height: 24),
                ],

                // Type badge
                if (animal.animalType != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      animal.animalType!.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),

                // Animal name
                Text(
                  animal.nameVietnamese,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                if (animal.nameEnglish != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    animal.nameEnglish!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Fun fact
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('✨', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            'Sự thật thú vị',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        animal.funFactVietnamese ?? 'Chưa có thông tin.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.6,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Extra info chips
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    if (animal.primaryHabitat != null)
                      _infoChip('📍 ${animal.primaryHabitat!}'),
                    if (animal.conservationStatus != null)
                      _infoChip('🌿 ${animal.conservationStatus!}'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Text('🐾', style: TextStyle(fontSize: 48)),
      ),
    );
  }

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
      ),
    );
  }

  Widget _buildBottomControls(ExploreService service) {
    final isLast = _currentIndex == service.dailyAnimals.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Row(
        children: [
          if (_currentIndex > 0)
            GestureDetector(
              onTap: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              ),
              child: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF16161F),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2A2A3A)),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
          if (_currentIndex > 0) const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLast
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF7C6FFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isLast ? '🎉  Hoàn thành!' : 'Tiếp theo  →',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Completion bottom sheet ────────────────────────────────────
class _CompletionSheet extends StatelessWidget {
  final VoidCallback onQuiz;
  final VoidCallback onBack;

  const _CompletionSheet({required this.onQuiz, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF16161F),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF2A2A3A)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          const Text(
            'Khám phá hoàn tất!',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bạn đã đọc xong 10 sự thật thú vị hôm nay.\nSẵn sàng kiểm tra kiến thức chưa?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF888888), fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C6FFF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                '🧠  Làm Quiz ngay!',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onBack,
            child: const Text(
              'Để sau',
              style: TextStyle(color: Color(0xFF666666), fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}