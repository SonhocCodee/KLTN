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
  // SharedPreferences keys
  static const _keyDate           = 'explore_date';
  static const _keyAnimalIds      = 'explore_animal_ids';
  static const _keyReadCount      = 'explore_read_count';
  static const _keyReadIndices    = 'explore_read_indices';
  static const _keyStreak         = 'explore_streak';
  static const _keyLastQuizDate   = 'explore_last_quiz_date'; // ngày làm quiz gần nhất
  static const _keyQuizDoneToday  = 'explore_quiz_done_today'; // ngày đã tính streak
  static const _keyTotalFacts     = 'explore_total_facts';
  static const _keyTotalSpecies   = 'explore_total_species';
  static const _keyAllReadSpecies = 'explore_all_read_species';
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
  bool quizDoneToday      = false;

  String? _lastQuizDate; // cache in-memory

  final Set<int> _readIndicesThisSession = {};

  bool _isInitialized        = false;
  String _initializedForDate = '';

  List<DailyAnimal>  dailyAnimals  = [];
  List<QuizQuestion> quizQuestions = [];

  bool get isQuizUnlocked    => readCount >= 10;
  bool get hasCompletedToday => readCount >= 10;
  int  get remainingFacts    => (10 - readCount).clamp(0, 10);

  // ── Init ─────────────────────────────────────────────────────
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

  // ── Load stats từ local + server ────────────────────────────
  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();

    totalFactsRead = prefs.getInt(_keyTotalFacts)   ?? 0;
    totalSpecies   = prefs.getInt(_keyTotalSpecies) ?? 0;
    streakDays     = prefs.getInt(_keyStreak)       ?? 0;
    _lastQuizDate  = prefs.getString(_keyLastQuizDate);

    await _mergeStatsFromSupabase(prefs);
    await _loadQuizPctFromSupabase(prefs);

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

  Future<void> _mergeStatsFromSupabase(SharedPreferences prefs) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final row = await _supabase
          .from('user_stats')
          .select('streak_days, total_facts, total_species, last_played')
          .eq('user_id', userId)
          .maybeSingle();

      if (row == null) return;

      final serverFacts      = (row['total_facts']   as int?) ?? 0;
      final serverSpecies    = (row['total_species']  as int?) ?? 0;
      final serverStreak     = (row['streak_days']    as int?) ?? 0;
      final serverLastPlayed = row['last_played']     as String?;

      // Streak server chỉ hợp lệ nếu last_played <= hôm qua (tức quiz gần đây)
      final serverStreakValid =
          serverLastPlayed == _todayString() ||
              serverLastPlayed == _yesterdayString();

      if (serverStreakValid && serverStreak > streakDays) {
        streakDays = serverStreak;
        await prefs.setInt(_keyStreak, streakDays);
      }

      if (serverFacts > totalFactsRead) {
        totalFactsRead = serverFacts;
        await prefs.setInt(_keyTotalFacts, totalFactsRead);
      }
      if (serverSpecies > totalSpecies) {
        totalSpecies = serverSpecies;
        await prefs.setInt(_keyTotalSpecies, totalSpecies);
      }
    } catch (e) {
      debugPrint('[ExploreService] Merge stats error: $e');
    }
  }

  Future<void> _loadQuizPctFromSupabase(SharedPreferences prefs) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      final a = prefs.getInt('quiz_total_answered') ?? 0;
      final c = prefs.getInt('quiz_total_correct')  ?? 0;
      quizCorrectPct = a > 0 ? ((c / a) * 100).round() : 0;
      return;
    }
    try {
      final rows = await _supabase
          .from('quiz_progress')
          .select('score, total')
          .eq('user_id', userId)
          .eq('completed', true);

      if (rows == null || (rows as List).isEmpty) {
        quizCorrectPct = 0;
        return;
      }
      int sumScore = 0, sumTotal = 0;
      for (final r in rows) {
        sumScore += (r['score'] as int? ?? 0);
        sumTotal += (r['total'] as int? ?? 0);
      }
      quizCorrectPct = sumTotal > 0 ? ((sumScore / sumTotal) * 100).round() : 0;
      await prefs.setInt('quiz_total_answered', sumTotal);
      await prefs.setInt('quiz_total_correct',  sumScore);
    } catch (e) {
      debugPrint('[ExploreService] Load quiz pct error: $e');
      final a = prefs.getInt('quiz_total_answered') ?? 0;
      final c = prefs.getInt('quiz_total_correct')  ?? 0;
      quizCorrectPct = a > 0 ? ((c / a) * 100).round() : 0;
    }
  }

  // ── Sync toàn bộ stats lên Supabase ─────────────────────────
  void _syncAllStats() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    _supabase.from('user_stats').upsert({
      'user_id'      : userId,
      'streak_days'  : streakDays,
      'last_played'  : _lastQuizDate ?? _todayString(),
      'total_facts'  : totalFactsRead,
      'total_species': totalSpecies,
      'updated_at'   : DateTime.now().toIso8601String(),
    }, onConflict: 'user_id').catchError((e) {
      debugPrint('[ExploreService] Sync all stats error: $e');
    });
  }

  // Chỉ sync facts/species (không đụng streak/last_played)
  void _syncFactsOnly() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    _supabase.from('user_stats').upsert({
      'user_id'      : userId,
      'total_facts'  : totalFactsRead,
      'total_species': totalSpecies,
      'updated_at'   : DateTime.now().toIso8601String(),
    }, onConflict: 'user_id').catchError((e) {
      debugPrint('[ExploreService] Sync facts error: $e');
    });
  }

  // ── Check & refresh daily — KHÔNG đụng streak ───────────────
  Future<void> _checkAndRefreshDaily() async {
    final prefs     = await SharedPreferences.getInstance();
    final today     = _todayString();
    final savedDate = prefs.getString(_keyDate);

    // Kiểm tra hôm nay đã làm quiz chưa
    final quizDoneDate = prefs.getString(_keyQuizDoneToday) ?? '';
    quizDoneToday = quizDoneDate == today;

    if (savedDate != today) {
      // Sang ngày mới → reset daily progress
      _isInitialized = false;
      await prefs.setString(_keyDate, today);
      await prefs.setInt(_keyReadCount, 0);
      await prefs.remove(_keyReadIndices);
      await prefs.remove(_keyAnimalIds);
      readCount     = 0;
      quizDoneToday = false;
      _readIndicesThisSession.clear();
      dailyAnimals  = [];

      // FIX: Streak reset nếu bỏ ngày quiz (không reset khi chỉ bỏ đọc fact)
      await _checkStreakOnNewDay(prefs);
    } else {
      readCount = prefs.getInt(_keyReadCount) ?? 0;
      final saved = prefs.getStringList(_keyReadIndices) ?? [];
      for (final s in saved) {
        final i = int.tryParse(s);
        if (i != null) _readIndicesThisSession.add(i);
      }
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

  // ── FIX CORE: Streak chỉ reset nếu không làm quiz hôm qua ──
  Future<void> _checkStreakOnNewDay(SharedPreferences prefs) async {
    final lastQuizDate = prefs.getString(_keyLastQuizDate);
    final yesterday    = _yesterdayString();

    if (lastQuizDate == null || lastQuizDate.isEmpty) {
      // Chưa từng làm quiz → streak = 0, không làm gì
      debugPrint('[Streak] Chưa có quiz → giữ 0');
      return;
    }

    if (lastQuizDate == yesterday) {
      // Làm quiz đúng hôm qua → streak còn sống, chờ làm quiz hôm nay mới tăng
      debugPrint('[Streak] Quiz hôm qua ok → streak còn = $streakDays');
    } else {
      // Bỏ ít nhất 1 ngày không làm quiz → mất chuỗi
      streakDays = 0;
      await prefs.setInt(_keyStreak, streakDays);
      debugPrint('[Streak] Bỏ ngày (last: $lastQuizDate) → reset = 0');
      _syncAllStats();
    }
    notifyListeners();
  }

  // ── FIX CORE: submitQuizResult — streak +1 tại đây ─────────
  Future<void> submitQuizResult({
    required int correctCount,
    required List<String> answeredQuestionIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final total = answeredQuestionIds.length;

    // Cập nhật quiz correct %
    final totalAnswered = (prefs.getInt('quiz_total_answered') ?? 0) + total;
    final totalCorrect  = (prefs.getInt('quiz_total_correct')  ?? 0) + correctCount;
    await prefs.setInt('quiz_total_answered', totalAnswered);
    await prefs.setInt('quiz_total_correct',  totalCorrect);
    quizCorrectPct = totalAnswered > 0
        ? ((totalCorrect / totalAnswered) * 100).round()
        : 0;

    // FIX: Tăng streak — chỉ 1 lần/ngày
    if (!quizDoneToday) {
      final lastQuizDate = prefs.getString(_keyLastQuizDate) ?? '';
      final yesterday    = _yesterdayString();

      if (lastQuizDate.isEmpty) {
        // Lần đầu tiên làm quiz
        streakDays = 1;
      } else if (lastQuizDate == yesterday) {
        // Liên tục ngày hôm qua → tăng
        streakDays++;
      } else {
        // Đã bỏ ngày → bắt đầu lại từ 1
        streakDays = 1;
      }

      quizDoneToday  = true;
      _lastQuizDate  = today;
      await prefs.setString(_keyQuizDoneToday, today);
      await prefs.setString(_keyLastQuizDate,  today);
      await prefs.setInt(_keyStreak, streakDays);
      debugPrint('[Streak] Quiz submit → streakDays = $streakDays');
    }

    // Ghi session vào Supabase
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      _supabase.from('quiz_progress').insert({
        'user_id'     : userId,
        'quiz_date'   : today,
        'score'       : correctCount,
        'total'       : total,
        'completed'   : true,
        'completed_at': DateTime.now().toIso8601String(),
      }).catchError((e) => debugPrint('[ExploreService] Insert quiz_progress error: $e'));
    }

    _updateQuizStats(answeredQuestionIds, correctCount);
    _syncAllStats();
    notifyListeners();
  }

  Future<void> _updateQuizStats(List<String> questionIds, int correctCount) async {
    for (final qid in questionIds) {
      try {
        await _supabase.rpc('increment_quiz_stats', params: {
          'question_id': qid,
          'was_correct': correctCount > 0,
        });
      } catch (_) {}
    }
  }

  // ── FIX: recoverStreak ───────────────────────────────────────
  Future<bool> recoverStreak() async {
    if (streakRecoveryLeft <= 0) return false;

    final prefs      = await SharedPreferences.getInstance();
    final usedBefore = prefs.getInt(_keyRecoveryUsed) ?? 0;
    final newUsed    = usedBefore + 1;

    await prefs.setInt(_keyRecoveryUsed, newUsed);
    streakRecoveryLeft = (2 - newUsed).clamp(0, 2);
    streakDays++;
    await prefs.setInt(_keyStreak, streakDays);

    // Recovery = user muốn giữ chuỗi, coi như đã làm quiz hôm qua
    // để sáng mai _checkStreakOnNewDay không reset
    final yesterday = _yesterdayString();
    await prefs.setString(_keyLastQuizDate, yesterday);
    _lastQuizDate = yesterday;

    _syncAllStats();
    notifyListeners();
    debugPrint('[Streak] Recovery → streakDays = $streakDays, left = $streakRecoveryLeft');
    return true;
  }

  // ── FIX: markFactRead — Set-based, không nhảy index ─────────
  Future<void> markFactRead(int index) async {
    if (index < 0 || index > 9) return;
    if (_readIndicesThisSession.contains(index)) return;

    _readIndicesThisSession.add(index);

    final prefs = await SharedPreferences.getInstance();

    readCount = _readIndicesThisSession.length;
    await prefs.setInt(_keyReadCount, readCount);
    await prefs.setStringList(
      _keyReadIndices,
      _readIndicesThisSession.map((i) => i.toString()).toList(),
    );

    totalFactsRead++;
    await prefs.setInt(_keyTotalFacts, totalFactsRead);

    if (index < dailyAnimals.length) {
      final animalId      = dailyAnimals[index].id;
      final allSpeciesSet = (prefs.getStringList(_keyAllReadSpecies) ?? []).toSet();
      if (!allSpeciesSet.contains(animalId)) {
        allSpeciesSet.add(animalId);
        totalSpecies = allSpeciesSet.length;
        await prefs.setStringList(_keyAllReadSpecies, allSpeciesSet.toList());
        await prefs.setInt(_keyTotalSpecies, totalSpecies);
      }
    }

    if (isQuizUnlocked && quizQuestions.isEmpty) {
      await _fetchQuizQuestions();
    }

    notifyListeners();
    _syncFactsOnly(); // Streak không đổi, không sync streak
  }

  // ── Fetch animals ────────────────────────────────────────────
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
      debugPrint('[ExploreService] Fetch animals error: $e');
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
      dailyAnimals = ids.map((id) => map[id]).whereType<DailyAnimal>().toList();
    } catch (e) {
      debugPrint('[ExploreService] Fetch by ids error: $e');
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
      debugPrint('[ExploreService] Fetch quiz error: $e');
    }
  }

  Future<void> ensureQuizLoaded() async {
    if (quizQuestions.isEmpty && isQuizUnlocked) {
      await _fetchQuizQuestions();
      notifyListeners();
    }
  }

  // ── Helpers ──────────────────────────────────────────────────
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