import 'package:flutter/material.dart';
import 'package:kltn_app/screen/Fact_quizz/widgets/fact_completion_sheet.dart';
import 'package:provider/provider.dart';

import '../ExploreScreen/explore_service.dart';
import '../quizz_page/quiz_page.dart';
import 'widgets/fact_swipe_top_bar.dart';
import 'widgets/fact_swipe_card.dart';
import 'widgets/fact_swipe_controls.dart';

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

  final List<Color> _accentColors = [
    const Color(0xFFE8F5E9),
    const Color(0xFFE3F2FD),
    const Color(0xFFFFF3E0),
    const Color(0xFFF3E5F5),
    const Color(0xFFE0F2F1),
    const Color(0xFFFFFDE7),
    const Color(0xFFEFEBE9),
    const Color(0xFFF1F8E9),
    const Color(0xFFE8EAF6),
    const Color(0xFFFCE4EC),
  ];

  @override
  void initState() {
    super.initState();
    final service = context.read<ExploreService>();

    // Bắt đầu từ fact chưa đọc, không phải readCount
    // readCount là số fact đã đọc -> ta muốn tiếp tục từ đó
    // Nhưng KHÔNG gọi markFactRead ở đây - chỉ gọi khi user thực sự xem card
    _currentIndex = service.readCount.clamp(0, 9);
    _pageController = PageController(initialPage: _currentIndex);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Dùng addPostFrameCallback để đánh dấu card hiện tại SAU khi render
    // Chỉ đánh dấu nếu đây là card chưa từng đọc (service tự check)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // markFactRead tự bỏ qua nếu index đã có trong set
      context.read<ExploreService>().markFactRead(_currentIndex);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    // markFactRead dùng Set nên gọi nhiều lần cùng index không sao
    context.read<ExploreService>().markFactRead(index);
  }

  void _nextPage() async {
    if (_currentIndex < 9) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
      );
    } else {
      final service = context.read<ExploreService>();
      await service.markFactRead(_currentIndex);
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
      builder: (_) => FactCompletionSheet(
        onQuiz: () {
          final service = context.read<ExploreService>();
          Navigator.pop(context);
          Navigator.pop(context);
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
    final colorScheme = Theme.of(context).colorScheme;

    if (animals.isEmpty) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            FactSwipeTopBar(
              currentIndex: _currentIndex,
              totalCount: service.dailyAnimals.length,
              onClose: () => Navigator.pop(context),
            ),
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
                      child: FactSwipeCard(
                        animal: animals[i],
                        accentColor: _accentColors[i % _accentColors.length],
                        fadeAnim: _fadeAnim,
                      ),
                    );
                  },
                ),
              ),
            ),
            FactSwipeControls(
              isLast: _currentIndex == service.dailyAnimals.length - 1,
              onNextPage: _nextPage,
            ),
          ],
        ),
      ),
    );
  }
}
