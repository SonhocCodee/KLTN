import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Fact_quizz/fact_swipe_page.dart';
import '../quizz_page/quiz_page.dart';
import 'explore_service.dart';

import 'widgets/explore_header.dart';
import 'widgets/explore_streak_bar.dart';
import 'widgets/explore_hero_card.dart';
import 'widgets/explore_minigame_row.dart';
import 'widgets/explore_unlock_hint.dart';
import 'widgets/explore_stats.dart';
import 'widgets/explore_section_label.dart';

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
    // 1. Gọi colorScheme ở màn hình tổng
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<ExploreService>(
      builder: (context, service, _) {
        if (service.isLoading) {
          return Scaffold(
            backgroundColor: colorScheme.surface, // Dùng surface thay vì xám cứng
            body: Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
          );
        }
        return Scaffold(
          backgroundColor: colorScheme.surface, // Dùng surface thay vì xám cứng
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: ExploreHeader()),
                SliverToBoxAdapter(child: ExploreStreakBar(service: service)),
                const SliverToBoxAdapter(
                  child: ExploreSectionLabel(text: 'Hành trình hôm nay'),
                ),
                SliverToBoxAdapter(
                  child: ExploreHeroCard(
                    service: service,
                    onTap: () => _goToFacts(service),
                  ),
                ),
                const SliverToBoxAdapter(child: ExploreSectionLabel(text: 'Minigame')),
                SliverToBoxAdapter(
                  child: ExploreMinigameRow(
                    service: service,
                    onQuizTap: () => _goToQuiz(service),
                  ),
                ),
                if (!service.isQuizUnlocked)
                  SliverToBoxAdapter(child: ExploreUnlockHint(service: service)),
                const SliverToBoxAdapter(
                  child: ExploreSectionLabel(text: 'Thống kê của bạn'),
                ),
                SliverToBoxAdapter(child: ExploreStats(service: service)),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        );
      },
    );
  }

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