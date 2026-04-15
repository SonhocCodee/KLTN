import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'explore_service.dart';
import 'fact_swipe_page.dart';
import 'quiz_page.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExploreService>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreService>(
      builder: (context, service, _) {
        if (service.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFF2F2F7), // Apple System Grouped Background
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF7C6FFF)),
            ),
          );
        }
        return Scaffold(
          backgroundColor: const Color(0xFFF2F2F7), // Nền xám nhạt Apple style tạo độ tương phản cho card
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildStreakBar(service)),
                SliverToBoxAdapter(
                  child: _sectionLabel('Hành trình hôm nay'),
                ),
                SliverToBoxAdapter(child: _buildHeroCard(service)),
                SliverToBoxAdapter(child: _sectionLabel('Minigame')),
                SliverToBoxAdapter(child: _buildMinigameRow(service)),
                if (!service.isQuizUnlocked)
                  SliverToBoxAdapter(child: _buildUnlockHint(service)),
                SliverToBoxAdapter(
                  child: _sectionLabel('Thống kê của bạn'),
                ),
                SliverToBoxAdapter(child: _buildStats(service)),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────
  Widget _buildHeader() {
    final now = DateTime.now();
    final weekdays = ['', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
    final months   = ['', 'Tháng 1','Tháng 2','Tháng 3','Tháng 4','Tháng 5','Tháng 6','Tháng 7','Tháng 8','Tháng 9','Tháng 10','Tháng 11','Tháng 12'];
    final dateStr  = '${weekdays[now.weekday]}, ${now.day} ${months[now.month]}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateStr.toUpperCase(),
            style: const TextStyle(
              fontSize: 12, color: Color(0xFF8E8E93), // Apple System Gray
              letterSpacing: 1.0, fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2),
              children: [
                TextSpan(text: 'Khám phá\n', style: TextStyle(color: Color(0xFF1C1C1E))), // Apple Primary Text
                TextSpan(text: 'hôm nay ', style: TextStyle(color: Color(0xFF7C6FFF))),
                TextSpan(text: '🌿', style: TextStyle(fontSize: 24)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Streak bar ─────────────────────────────────────────────
  Widget _buildStreakBar(ExploreService service) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white, // Card trắng tinh nổi bật trên nền xám
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA)), // Viền cực mảnh và nhạt
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF4757)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('🔥', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${service.streakDays} ngày liên tiếp',
                  style: const TextStyle(
                    color: Color(0xFF1C1C1E), fontSize: 15, fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  service.streakDays > 0
                      ? 'Đừng để mất chuỗi nhé!'
                      : 'Bắt đầu chuỗi ngày hôm nay!',
                  style: const TextStyle(color: Color(0xFF3C3C43), fontSize: 12), // Text phụ rõ ràng nhưng không gắt
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEECEE),
              border: Border.all(color: const Color(0xFFFCD6D9)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+${service.streakDays}',
              style: const TextStyle(
                color: Color(0xFFFF3B30), fontSize: 12, fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero card — 10 Facts ────────────────────────────────────
  Widget _buildHeroCard(ExploreService service) {
    final isDone = service.hasCompletedToday;
    final btnLabel = service.readCount == 0
        ? 'Bắt đầu khám phá'
        : isDone
        ? 'Xem lại facts hôm nay'
        : 'Tiếp tục khám phá';

    return GestureDetector(
      onTap: () => _goToFacts(service),
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF8F8FC)], // Gradient rất nhẹ cho cảm giác premium
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5E5EA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EEFF),
                border: Border.all(color: const Color(0xFFE5E0FF)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF7C6FFF), shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Mới mỗi ngày',
                    style: TextStyle(
                      color: Color(0xFF7C6FFF), fontSize: 12, fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '10 Sự thật thú vị',
              style: TextStyle(
                color: Color(0xFF1C1C1E), fontSize: 20, fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isDone
                  ? 'Bạn đã hoàn thành hôm nay! Quay lại ngày mai để khám phá thêm.'
                  : 'Khám phá những điều bí ẩn về thế giới động vật — mỗi ngày một bộ mới hoàn toàn.',
              style: const TextStyle(
                color: Color(0xFF3C3C43), fontSize: 14, height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            // Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tiến độ hôm nay',
                  style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
                ),
                Text(
                  '${service.readCount} / 10',
                  style: const TextStyle(
                    color: Color(0xFF7C6FFF), fontSize: 13, fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: service.readCount / 10,
                minHeight: 4,
                backgroundColor: const Color(0xFFE5E5EA),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF7C6FFF)),
              ),
            ),
            const SizedBox(height: 16),
            // CTA button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _goToFacts(service),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF7C6FFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  btnLabel,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Minigame row ────────────────────────────────────────────
  Widget _buildMinigameRow(ExploreService service) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(child: _buildQuizCard(service)),
          const SizedBox(width: 12),
          Expanded(child: _buildGuessCard()),
          const SizedBox(width: 12),
          Expanded(child: _buildSoonCard()),
        ],
      ),
    );
  }

  Widget _buildQuizCard(ExploreService service) {
    final locked = !service.isQuizUnlocked;
    return GestureDetector(
      onTap: locked ? null : () => _goToQuiz(service),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: locked ? const Color(0xFFF2F2F7) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: locked ? const Color(0xFFE5E5EA) : const Color(0xFFE5E5EA),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: locked
                        ? const Color(0xFFE5E5EA)
                        : const Color(0xFFF0EEFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('🧠', style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(height: 10),
                Text(
                  'Đố vui',
                  style: TextStyle(
                    color: locked ? const Color(0xFF8E8E93) : const Color(0xFF1C1C1E),
                    fontSize: 14, fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quiz từ facts hôm nay',
                  style: TextStyle(
                    color: locked
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF3C3C43),
                    fontSize: 11, height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Lock overlay
          if (locked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xD9F2F2F7), // Mờ ảo theo style iOS
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE5E5EA)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text('🔒', style: TextStyle(fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Đọc đủ\n10 facts',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10, color: Color(0xFF3C3C43), fontWeight: FontWeight.w600, height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGuessCard() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đoán ảnh — sắp ra mắt!')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF4FBF7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E5EA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('🔍', style: TextStyle(fontSize: 20))),
            ),
            const SizedBox(height: 10),
            const Text(
              'Đoán ảnh',
              style: TextStyle(color: Color(0xFF1C1C1E), fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Nhận diện qua hình',
              style: TextStyle(color: Color(0xFF3C3C43), fontSize: 11, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoonCard() {
    return Opacity(
      opacity: 0.5,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E5EA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('🎯', style: TextStyle(fontSize: 20))),
                ),
                Positioned(
                  top: -4, right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D1D6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Sắp ra',
                      style: TextStyle(fontSize: 8, color: Color(0xFF3C3C43), fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Phân loại',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Loại nào đúng?',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  // ── Unlock hint ─────────────────────────────────────────────
  Widget _buildUnlockHint(ExploreService service) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E5EA)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Dots progress
          Wrap(
            spacing: 5,
            children: List.generate(10, (i) {
              return Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: i < service.readCount
                      ? const Color(0xFF7C6FFF)
                      : const Color(0xFFE5E5EA),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Color(0xFF3C3C43)),
                children: [
                  const TextSpan(text: 'Đọc thêm '),
                  TextSpan(
                    text: '${service.remainingFacts} facts nữa ',
                    style: const TextStyle(
                      color: Color(0xFF7C6FFF), fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: 'để mở khoá Đố vui!'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats ───────────────────────────────────────────────────
  Widget _buildStats(ExploreService service) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _statCard('${service.totalFactsRead}', 'Facts đã đọc', const Color(0xFF7C6FFF)),
          const SizedBox(width: 10),
          _statCard('${service.quizCorrectPct}%', 'Quiz đúng', const Color(0xFF22C55E)),
          const SizedBox(width: 10),
          _statCard('${service.totalSpecies}', 'Loài khám phá', const Color(0xFFF97316)),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E5EA)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF3C3C43), fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Section label ────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: Color(0xFF8E8E93), letterSpacing: 1.0,
        ),
      ),
    );
  }

  // ── Navigation ───────────────────────────────────────────────
  void _goToFacts(ExploreService service) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: service,
          child: const FactSwipePage(),
        ),
      ),
    );
  }

  void _goToQuiz(ExploreService service) async {
    // Nếu quiz chưa được fetch (vd: vào lại app sau khi đã đọc đủ facts),
    // gọi fetch trước rồi mới navigate để tránh màn hình đen
    if (service.quizQuestions.isEmpty) {
      await service.ensureQuizLoaded();
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: service,
          child: const QuizPage(),
        ),
      ),
    );
  }
}