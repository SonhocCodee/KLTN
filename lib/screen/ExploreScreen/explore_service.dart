// lib/services/explore_service.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyAnimal {
  final String id;
  final String nameVietnamese;
  final String? nameEnglish;
  final String? funFactVietnamese;
  final String? imageUrl;
  final String? animalType;
  final String? primaryHabitat;
  final String? conservationStatus;

  DailyAnimal({
    required this.id,
    required this.nameVietnamese,
    this.nameEnglish,
    this.funFactVietnamese,
    this.imageUrl,
    this.animalType,
    this.primaryHabitat,
    this.conservationStatus,
  });

  factory DailyAnimal.fromJson(Map<String, dynamic> json) => DailyAnimal(
    id: json['id'],
    nameVietnamese: json['name_vietnamese'] ?? '',
    nameEnglish: json['name_english'],
    funFactVietnamese: json['fun_fact_vietnamese'],
    imageUrl: json['image_url'],
    animalType: json['animal_type'],
    primaryHabitat: json['primary_habitat'],
    conservationStatus: json['conservation_status'],
  );
}

class QuizQuestion {
  final String id;
  final String animalId;
  final String question;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctAnswer;
  final String? explanation;

  QuizQuestion({
    required this.id,
    required this.animalId,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctAnswer,
    this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
    id: json['id'],
    animalId: json['animal_id'],
    question: json['question'],
    optionA: json['option_a'],
    optionB: json['option_b'],
    optionC: json['option_c'],
    optionD: json['option_d'],
    correctAnswer: json['correct_answer'],
    explanation: json['explanation'],
  );

  Map<String, String> get options => {
    'option_a': optionA,
    'option_b': optionB,
    'option_c': optionC,
    'option_d': optionD,
  };
}

class ExploreService extends ChangeNotifier {
  static const _keyDate           = 'explore_date';
  static const _keyAnimalIds      = 'explore_animal_ids';
  static const _keyReadCount      = 'explore_read_count';
  static const _keyStreak         = 'explore_streak';
  static const _keyLastPlayed     = 'explore_last_played';
  static const _keyTotalFacts     = 'explore_total_facts';
  static const _keyTotalSpecies   = 'explore_total_species';
  static const _keyDailySpecies   = 'explore_daily_species';
  static const _keyRecoveryMonth  = 'streak_recovery_month';
  static const _keyRecoveryUsed   = 'streak_recovery_used';

  final _supabase = Supabase.instance.client;

  bool isLoading          = true;
  int  readCount          = 0;
  int  streakDays         = 0;
  int  totalFactsRead     = 0;
  int  totalSpecies       = 0;
  int  quizCorrectPct     = 0;
  int  streakRecoveryLeft = 0;

  int  _dailySpeciesInMemory = 0;
  bool _isInitialized        = false;
  String _initializedForDate = '';

  List<DailyAnimal>  dailyAnimals  = [];
  List<QuizQuestion> quizQuestions = [];

  bool get isQuizUnlocked    => readCount >= 10;
  bool get hasCompletedToday => readCount >= 10;
  int  get remainingFacts    => 10 - readCount;

  // ── Init ────────────────────────────────────────────────────
  Future<void> init() async {
    final today = _todayString();
    if (_isInitialized && _initializedForDate == today && dailyAnimals.isNotEmpty) {
      return;
    }

    isLoading = true;
    notifyListeners();

    await _loadStats();
    await _checkAndRefreshDaily();

    _isInitialized = true;
    _initializedForDate = today;

    isLoading = false;
    notifyListeners();
  }

  // ── Load stats: local trước, sau đó merge với server ────────
  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();

    // Đọc local làm baseline (nhanh, không chờ mạng)
    totalFactsRead = prefs.getInt(_keyTotalFacts) ?? 0;
    totalSpecies   = prefs.getInt(_keyTotalSpecies) ?? 0;
    streakDays     = prefs.getInt(_keyStreak) ?? 0;

    // Merge với Supabase — lấy giá trị MAX để không bao giờ bị lùi về 0
    await _mergeStatsFromSupabase(prefs);

    // Quiz correct % — tính từ quiz_progress trên server (chính xác nhất)
    await _loadQuizPctFromSupabase(prefs);

    // Streak recovery quota
    final thisMonth  = _monthString();
    final savedMonth = prefs.getString(_keyRecoveryMonth) ?? '';
    if (savedMonth != thisMonth) {
      await prefs.setString(_keyRecoveryMonth, thisMonth);
      await prefs.setInt(_keyRecoveryUsed, 0);
      streakRecoveryLeft = 2;
    } else {
      final used = prefs.getInt(_keyRecoveryUsed) ?? 0;
      streakRecoveryLeft = (2 - used).clamp(0, 2);
    }
  }

  // ── Lấy totalFacts + totalSpecies + streak từ user_stats ────
  Future<void> _mergeStatsFromSupabase(SharedPreferences prefs) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final row = await _supabase
          .from('user_stats')
          .select('streak_days, total_facts, total_species')
          .eq('user_id', userId)
          .maybeSingle();

      if (row == null) return;

      // Luôn lấy giá trị lớn hơn giữa local và server
      final serverFacts   = (row['total_facts']   as int?) ?? 0;
      final serverSpecies = (row['total_species']  as int?) ?? 0;
      final serverStreak  = (row['streak_days']    as int?) ?? 0;

      totalFactsRead = totalFactsRead > serverFacts   ? totalFactsRead : serverFacts;
      totalSpecies   = totalSpecies   > serverSpecies ? totalSpecies   : serverSpecies;
      streakDays     = streakDays     > serverStreak  ? streakDays     : serverStreak;

      // Ghi lại local để đồng bộ
      await prefs.setInt(_keyTotalFacts,   totalFactsRead);
      await prefs.setInt(_keyTotalSpecies, totalSpecies);
      await prefs.setInt(_keyStreak,       streakDays);
    } catch (e) {
      debugPrint('Merge stats from Supabase error: $e');
    }
  }

  // ── Tính quizCorrectPct từ quiz_progress (chính xác nhất) ───
  Future<void> _loadQuizPctFromSupabase(SharedPreferences prefs) async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      // Offline fallback: dùng local
      final answered = prefs.getInt('quiz_total_answered') ?? 0;
      final correct  = prefs.getInt('quiz_total_correct')  ?? 0;
      quizCorrectPct = answered > 0 ? ((correct / answered) * 100).round() : 0;
      return;
    }

    try {
      // Lấy tất cả session đã completed của user
      final rows = await _supabase
          .from('quiz_progress')
          .select('score, total')
          .eq('user_id', userId)
          .eq('completed', true);

      if (rows == null || (rows as List).isEmpty) {
        quizCorrectPct = 0;
        return;
      }

      int sumScore = 0;
      int sumTotal = 0;
      for (final r in rows) {
        sumScore += (r['score'] as int? ?? 0);
        sumTotal += (r['total'] as int? ?? 0);
      }

      quizCorrectPct = sumTotal > 0 ? ((sumScore / sumTotal) * 100).round() : 0;

      // Cập nhật local cache để dùng khi offline
      await prefs.setInt('quiz_total_answered', sumTotal);
      await prefs.setInt('quiz_total_correct',  sumScore);
    } catch (e) {
      debugPrint('Load quiz pct error: $e');
      // Fallback local
      final answered = prefs.getInt('quiz_total_answered') ?? 0;
      final correct  = prefs.getInt('quiz_total_correct')  ?? 0;
      quizCorrectPct = answered > 0 ? ((correct / answered) * 100).round() : 0;
    }
  }

  // ── Upsert user_stats lên Supabase (background, không block UI) ─
  void _syncUserStats() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _supabase.from('user_stats').upsert({
      'user_id'      : userId,
      'streak_days'  : streakDays,
      'last_played'  : _todayString(),
      'total_facts'  : totalFactsRead,
      'total_species': totalSpecies,
      'updated_at'   : DateTime.now().toIso8601String(),
    }, onConflict: 'user_id').then((_) {
      debugPrint('user_stats synced');
    }).catchError((e) {
      debugPrint('Sync user_stats error: $e');
    });
  }

  // ── Ghi quiz session vào quiz_progress ──────────────────────
  Future<void> submitQuizResult({
    required int correctCount,
    required List<String> answeredQuestionIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final total = answeredQuestionIds.length;

    // Cập nhật local cache
    final totalAnswered = (prefs.getInt('quiz_total_answered') ?? 0) + total;
    final totalCorrect  = (prefs.getInt('quiz_total_correct')  ?? 0) + correctCount;
    await prefs.setInt('quiz_total_answered', totalAnswered);
    await prefs.setInt('quiz_total_correct',  totalCorrect);

    quizCorrectPct = totalAnswered > 0
        ? ((totalCorrect / totalAnswered) * 100).round()
        : 0;

    // Ghi session vào quiz_progress trên Supabase
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      _supabase.from('quiz_progress').insert({
        'user_id'     : userId,
        'quiz_date'   : _todayString(),
        'score'       : correctCount,
        'total'       : total,
        'completed'   : true,
        'completed_at': DateTime.now().toIso8601String(),
      }).catchError((e) {
        debugPrint('Insert quiz_progress error: $e');
      });
    }

    // Cập nhật quiz_questions stats (giữ nguyên logic cũ)
    _updateQuizStats(answeredQuestionIds, correctCount);

    notifyListeners();
  }

  Future<void> _updateQuizStats(
      List<String> questionIds,
      int correctCount,
      ) async {
    for (final qid in questionIds) {
      try {
        await _supabase.rpc('increment_quiz_stats', params: {
          'question_id': qid,
          'was_correct': correctCount > 0,
        });
      } catch (_) {}
    }
  }

  // ── Kiểm tra ngày — reset nếu qua ngày mới ─────────────────
  Future<void> _checkAndRefreshDaily() async {
    final prefs     = await SharedPreferences.getInstance();
    final today     = _todayString();
    final savedDate = prefs.getString(_keyDate);

    if (savedDate != today) {
      _isInitialized = false;
      await _updateStreak(prefs, savedDate);
      await prefs.setString(_keyDate, today);
      await prefs.setInt(_keyReadCount, 0);
      await prefs.setInt(_keyDailySpecies, 0);
      await prefs.remove(_keyAnimalIds);
      readCount             = 0;
      _dailySpeciesInMemory = 0;
      dailyAnimals          = [];
    } else {
      readCount             = prefs.getInt(_keyReadCount) ?? 0;
      _dailySpeciesInMemory = prefs.getInt(_keyDailySpecies) ?? 0;
    }

    final savedIds = prefs.getStringList(_keyAnimalIds);
    if (savedIds != null && savedIds.length == 10) {
      await _fetchAnimalsByIds(savedIds);
    } else {
      await _fetchRandom10Animals(prefs);
    }

    if (isQuizUnlocked && quizQuestions.isEmpty) {
      await _fetchQuizQuestions();
    }
  }

  // ── Streak ──────────────────────────────────────────────────
  Future<void> _updateStreak(SharedPreferences prefs, String? lastDate) async {
    final yesterday = _yesterdayString();

    if (lastDate == yesterday) {
      streakDays++;
    } else if (lastDate != null && lastDate != yesterday) {
      streakDays = 0;
    }

    await prefs.setInt(_keyStreak, streakDays);
    await prefs.setString(_keyLastPlayed, _todayString());

    _syncUserStats(); // Sync streak lên Supabase
  }

  Future<bool> recoverStreak() async {
    if (streakRecoveryLeft <= 0) return false;

    final prefs = await SharedPreferences.getInstance();
    streakDays = (prefs.getInt(_keyStreak) ?? 0) + 1;
    streakRecoveryLeft--;

    await prefs.setInt(_keyStreak, streakDays);
    await prefs.setInt(_keyRecoveryUsed,
        2 - streakRecoveryLeft + (prefs.getInt(_keyRecoveryUsed) ?? 0));

    _syncUserStats();
    notifyListeners();
    return true;
  }

  // ── Đánh dấu đã đọc fact ───────────────────────────────────
  Future<void> markFactRead(int index) async {
    if (index + 1 <= readCount) return;

    final prefs = await SharedPreferences.getInstance();
    final prevReadCount = readCount;
    readCount = index + 1;
    await prefs.setInt(_keyReadCount, readCount);

    final newFactsThisCall = readCount - prevReadCount;
    totalFactsRead += newFactsThisCall;
    await prefs.setInt(_keyTotalFacts, totalFactsRead);

    if (readCount > _dailySpeciesInMemory) {
      final gained = readCount - _dailySpeciesInMemory;
      totalSpecies += gained;
      _dailySpeciesInMemory = readCount;
      await prefs.setInt(_keyTotalSpecies, totalSpecies);
      await prefs.setInt(_keyDailySpecies, _dailySpeciesInMemory);
    }

    if (isQuizUnlocked && quizQuestions.isEmpty) {
      await _fetchQuizQuestions();
    }

    notifyListeners();
    _syncUserStats(); // Sync facts + species lên Supabase
  }

  // ── Fetch animals ───────────────────────────────────────────
  Future<void> _fetchRandom10Animals(SharedPreferences prefs) async {
    try {
      final data = await _supabase
          .from('animals')
          .select(
        'id, name_vietnamese, name_english, fun_fact_vietnamese, '
            'image_url, animal_type, primary_habitat, conservation_status',
      )
          .not('fun_fact_vietnamese', 'is', null)
          .limit(500);

      final all = (data as List).map((e) => DailyAnimal.fromJson(e)).toList();
      all.shuffle();
      dailyAnimals = all.take(10).toList();

      await prefs.setStringList(
        _keyAnimalIds,
        dailyAnimals.map((a) => a.id).toList(),
      );
    } catch (e) {
      debugPrint('Fetch animals error: $e');
    }
  }

  Future<void> _fetchAnimalsByIds(List<String> ids) async {
    try {
      final data = await _supabase
          .from('animals')
          .select(
        'id, name_vietnamese, name_english, fun_fact_vietnamese, '
            'image_url, animal_type, primary_habitat, conservation_status',
      )
          .inFilter('id', ids);

      final map = {
        for (var e in data as List) e['id'] as String: DailyAnimal.fromJson(e)
      };
      dailyAnimals = ids
          .map((id) => map[id])
          .whereType<DailyAnimal>()
          .toList();
    } catch (e) {
      debugPrint('Fetch by ids error: $e');
    }
  }

  Future<void> _fetchQuizQuestions() async {
    if (dailyAnimals.isEmpty) return;
    try {
      final animalIds = dailyAnimals.map((a) => a.id).toList();

      final data = await _supabase
          .from('quiz_questions')
          .select()
          .inFilter('animal_id', animalIds)
          .eq('is_hidden', false)
          .or('last_shown_date.is.null,last_shown_date.lt.${_sevenDaysAgo()}')
          .limit(10);

      final allQ = (data as List).map((e) => QuizQuestion.fromJson(e)).toList();
      allQ.shuffle();
      quizQuestions = allQ.take(10).toList();
    } catch (e) {
      debugPrint('Fetch quiz error: $e');
    }
  }

  Future<void> ensureQuizLoaded() async {
    if (quizQuestions.isEmpty && isQuizUnlocked) {
      await _fetchQuizQuestions();
      notifyListeners();
    }
  }

  // ── Helpers ─────────────────────────────────────────────────
  String _todayString() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  String _yesterdayString() {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return '${y.year}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
  }

  String _monthString() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}';
  }

  String _sevenDaysAgo() {
    final d = DateTime.now().subtract(const Duration(days: 7));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}