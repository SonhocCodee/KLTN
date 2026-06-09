import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import '../language/Locale_provider.dart';

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

import '../auth/auth_service.dart';
import '../auth/auth_screen.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  StreamSubscription<AuthState>? _authSub;

  bool get _canUseFeature {
    return AuthService.isAuthenticatedUser;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAfterAuthChanged();
    });

    _authSub = AuthService.authStateStream.listen((_) {
      _refreshAfterAuthChanged();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void _refreshAfterAuthChanged() {
    if (!mounted) return;

    setState(() {});

    // Nếu chưa đăng nhập hoặc đang ở guest mode thì không gọi service,
    // tránh ExploreService load dữ liệu user rồi bị xoay/loading mãi.
    if (!_canUseFeature) return;

    context.read<ExploreService>().init();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    if (!_canUseFeature) {
      return _buildLoginRequired(context, colorScheme, t);
    }

    return Consumer<ExploreService>(
      builder: (context, service, _) {
        if (service.isLoading) {
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
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: ExploreHeader()),
                SliverToBoxAdapter(child: ExploreStreakBar(service: service)),
                SliverToBoxAdapter(
                  child: ExploreSectionLabel(
                    text: t.tr('Hành trình hôm nay'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ExploreHeroCard(
                    service: service,
                    onTap: () => _goToFacts(service),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ExploreSectionLabel(text: t.tr('Minigame')),
                ),
                SliverToBoxAdapter(
                  child: ExploreMinigameRow(
                    service: service,
                    onQuizTap: () => _goToQuiz(service),
                  ),
                ),
                if (!service.isQuizUnlocked)
                  SliverToBoxAdapter(child: ExploreUnlockHint(service: service)),
                SliverToBoxAdapter(
                  child: ExploreSectionLabel(
                    text: t.tr('Thống kê của bạn'),
                  ),
                ),
                SliverToBoxAdapter(child: ExploreStats(service: service)),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginRequired(
    BuildContext context,
    ColorScheme colorScheme,
    LocaleProvider t,
  ) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 42,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  t.tr('Vui lòng đăng nhập'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.tr('Đăng nhập để sử dụng tính năng khám phá, fact hằng ngày, quiz và thống kê của bạn.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: () async {
                    final ok = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        settings: const RouteSettings(arguments: {'popAfterLogin': true}),
                        builder: (_) => const AuthScreen(),
                      ),
                    );
                    if (!mounted) return;
                    if (ok == true) _refreshAfterAuthChanged();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 34,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      t.tr('Đăng nhập ngay'),
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
