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
  static const _keyDate              = 'explore_date';
  static const _keyAnimalIds         = 'explore_animal_ids';
  static const _keyReadCount         = 'explore_read_count';
  static const _keyStreak            = 'explore_streak';
  static const _keyLastPlayed        = 'explore_last_played';
  static const _keyTotalFacts        = 'explore_total_facts';
  static const _keyTotalSpecies      = 'explore_total_species';
  static const _keyDailySpecies      = 'explore_daily_species';
  // Streak recovery: lưu số lần đã dùng trong tháng hiện tại
  static const _keyRecoveryMonth     = 'streak_recovery_month';
  static const _keyRecoveryUsed      = 'streak_recovery_used';

  final _supabase = Supabase.instance.client;

  bool  isLoading        = true;
  int   readCount        = 0;
  int   streakDays       = 0;
  int   totalFactsRead   = 0;
  int   totalSpecies     = 0;
  int   quizCorrectPct   = 0;
  // Số lần khôi phục chuỗi còn lại trong tháng (tối đa 2)
  int   streakRecoveryLeft = 0;

  // Cache daily species trong memory để tránh race condition khi đọc prefs
  int _dailySpeciesInMemory = 0;

  // Guard: tránh init() chạy lại nhiều lần trong cùng 1 phiên
  bool _isInitialized = false;
  String _initializedForDate = '';

  List<DailyAnimal>  dailyAnimals  = [];
  List<QuizQuestion> quizQuestions = [];

  bool get isQuizUnlocked    => readCount >= 10;
  bool get hasCompletedToday => readCount >= 10;
  int  get remainingFacts    => 10 - readCount;

  // ── Init ────────────────────────────────────────────────────
  // Guard: nếu đã init trong cùng 1 ngày và đã có data, không init lại.
  // Tránh trường hợp ExplorePage re-mount gọi init() lại và set isLoading = true
  // khiến UI flicker + đọc lại prefs đè lên giá trị đang đúng trong memory.
  Future<void> init() async {
    final today = _todayString();

    // Nếu đã init hôm nay và có data → chỉ notify lại UI, không fetch lại
    if (_isInitialized && _initializedForDate == today && dailyAnimals.isNotEmpty) {
      return;
    }

    isLoading = true;
    notifyListeners();

    await _loadStats();            // load tất cả stats tích lũy vào memory trước
    await _checkAndRefreshDaily(); // chỉ update readCount + dailyAnimals, không đụng totalFacts/totalSpecies

    _isInitialized = true;
    _initializedForDate = today;

    isLoading = false;
    notifyListeners();
  }

  // ── Kiểm tra ngày — reset nếu qua ngày mới ─────────────────
  Future<void> _checkAndRefreshDaily() async {
    final prefs     = await SharedPreferences.getInstance();
    final today     = _todayString();
    final savedDate = prefs.getString(_keyDate);

    if (savedDate != today) {
      // Ngày mới: reset guard để init() chạy đầy đủ
      _isInitialized = false;
      // Ngày mới: CHỈ reset tiến độ ngày (readCount, dailySpecies)
      // KHÔNG đụng totalFactsRead / totalSpecies — đó là tổng tích lũy toàn thời gian
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
      // Đọc dailySpecies vào memory để markFactRead không cần đọc prefs mỗi lần
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

  // ── Fetch 10 con vật random ─────────────────────────────────
  Future<void> _fetchRandom10Animals(SharedPreferences prefs) async {
    try {
      // Supabase v2: await trực tiếp, không dùng .execute()
      final data = await _supabase
          .from('animals')
          .select(
        'id, name_vietnamese, name_english, fun_fact_vietnamese, '
            'image_url, animal_type, primary_habitat, conservation_status',
      )
          .not('fun_fact_vietnamese', 'is', null)
          .limit(500);

      final all = (data as List)
          .map((e) => DailyAnimal.fromJson(e))
          .toList();

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

  // ── Fetch theo ids đã cache ─────────────────────────────────
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
        for (var e in data as List)
          e['id'] as String: DailyAnimal.fromJson(e)
      };
      dailyAnimals = ids
          .map((id) => map[id])
          .whereType<DailyAnimal>()
          .toList();
    } catch (e) {
      debugPrint('Fetch by ids error: $e');
    }
  }

  // ── Fetch quiz questions ────────────────────────────────────
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

      final allQ = (data as List)
          .map((e) => QuizQuestion.fromJson(e))
          .toList();

      allQ.shuffle();
      quizQuestions = allQ.take(10).toList();
    } catch (e) {
      debugPrint('Fetch quiz error: $e');
    }
  }

  // ── Public: đảm bảo quiz questions đã được load ────────────
  // Gọi từ UI trước khi navigate vào QuizPage để tránh màn hình đen
  Future<void> ensureQuizLoaded() async {
    if (quizQuestions.isEmpty && isQuizUnlocked) {
      await _fetchQuizQuestions();
      notifyListeners();
    }
  }

  // ── Đánh dấu đã đọc fact ───────────────────────────────────
  Future<void> markFactRead(int index) async {
    // Chỉ xử lý khi người dùng đọc fact mới (chưa đọc trước đó)
    if (index + 1 <= readCount) return;

    final prefs = await SharedPreferences.getInstance();

    final prevReadCount = readCount;
    readCount = index + 1;
    await prefs.setInt(_keyReadCount, readCount);

    // totalFactsRead: cộng đúng số fact mới (tránh double count khi resume)
    final newFactsThisCall = readCount - prevReadCount;
    totalFactsRead += newFactsThisCall;
    await prefs.setInt(_keyTotalFacts, totalFactsRead);

    // FIX: dùng _dailySpeciesInMemory thay vì đọc lại từ prefs mỗi lần
    // tránh race condition khi prefs chưa flush kịp
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
  }

  // ── Submit kết quả quiz ─────────────────────────────────────
  Future<void> submitQuizResult({
    required int correctCount,
    required List<String> answeredQuestionIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final totalAnswered =
        (prefs.getInt('quiz_total_answered') ?? 0) + answeredQuestionIds.length;
    final totalCorrect =
        (prefs.getInt('quiz_total_correct') ?? 0) + correctCount;

    await prefs.setInt('quiz_total_answered', totalAnswered);
    await prefs.setInt('quiz_total_correct', totalCorrect);

    quizCorrectPct = totalAnswered > 0
        ? ((totalCorrect / totalAnswered) * 100).round()
        : 0;

    // Cập nhật Supabase background — không block UI
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

  // ── Streak ──────────────────────────────────────────────────
  Future<void> _updateStreak(
      SharedPreferences prefs,
      String? lastDate,
      ) async {
    final yesterday = _yesterdayString();
    // FIX: dùng streakDays đã load vào memory từ _loadStats(), không đọc lại từ prefs
    // (tránh ghi đè giá trị đúng bằng giá trị cũ chưa được flush)

    if (lastDate == yesterday) {
      // Mở app đúng ngày sau ngày cuối: tăng chuỗi
      streakDays++;
    } else if (lastDate != null && lastDate != yesterday) {
      // Bỏ qua ít nhất 1 ngày: mất chuỗi
      streakDays = 0;
    }
    // Nếu lastDate == null (lần đầu dùng app): giữ nguyên streakDays = 0

    await prefs.setInt(_keyStreak, streakDays);
    await prefs.setString(_keyLastPlayed, _todayString());
  }

  // ── Streak recovery: khôi phục chuỗi khi bỏ lỡ 1 ngày ─────
  // Tối đa 2 lần/tháng. Gọi từ UI khi người dùng xác nhận dùng lượt khôi phục.
  Future<bool> recoverStreak() async {
    if (streakRecoveryLeft <= 0) return false;

    final prefs = await SharedPreferences.getInstance();
    // Khôi phục: tăng lại streak lên (streak hiện tại đã bị reset = 0)
    // Ta cộng lại số ngày chuỗi cũ — nhưng vì không lưu chuỗi cũ,
    // ta tăng lên 1 để tính "không bị gián đoạn"
    streakDays = (prefs.getInt(_keyStreak) ?? 0) + 1;
    streakRecoveryLeft--;

    await prefs.setInt(_keyStreak, streakDays);
    await prefs.setInt(_keyRecoveryUsed,
        2 - streakRecoveryLeft + (prefs.getInt(_keyRecoveryUsed) ?? 0));

    notifyListeners();
    return true;
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();

    // FIX: _loadStats chỉ load stats tích lũy (facts, species, quiz)
    // KHÔNG load streakDays ở đây — streak được tính đúng trong _updateStreak()
    // và chỉ được đọc lại từ prefs SAU KHI _updateStreak đã xong (trong _checkAndRefreshDaily)
    totalFactsRead = prefs.getInt(_keyTotalFacts) ?? 0;
    totalSpecies   = prefs.getInt(_keyTotalSpecies) ?? 0;
    streakDays     = prefs.getInt(_keyStreak) ?? 0; // baseline — sẽ được update đúng bởi _updateStreak nếu ngày mới

    final totalAnswered = prefs.getInt('quiz_total_answered') ?? 0;
    final totalCorrect  = prefs.getInt('quiz_total_correct') ?? 0;
    quizCorrectPct = totalAnswered > 0
        ? ((totalCorrect / totalAnswered) * 100).round()
        : 0;

    // Load streak recovery quota
    final thisMonth = _monthString();
    final savedMonth = prefs.getString(_keyRecoveryMonth) ?? '';
    if (savedMonth != thisMonth) {
      // Tháng mới: reset quota về 2
      await prefs.setString(_keyRecoveryMonth, thisMonth);
      await prefs.setInt(_keyRecoveryUsed, 0);
      streakRecoveryLeft = 2;
    } else {
      final used = prefs.getInt(_keyRecoveryUsed) ?? 0;
      streakRecoveryLeft = (2 - used).clamp(0, 2);
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