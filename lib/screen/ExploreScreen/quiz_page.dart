
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'explore_service.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with SingleTickerProviderStateMixin {
  int    _currentIndex  = 0;
  String? _selectedKey;          // 'option_a' ... 'option_d'
  bool   _hasAnswered   = false;
  int    _correctCount  = 0;
  final  List<String> _answeredIds = [];

  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 12).chain(
      CurveTween(curve: Curves.elasticIn),
    ).animate(_shakeCtrl);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _selectAnswer(String key, QuizQuestion question) {
    if (_hasAnswered) return;

    setState(() {
      _selectedKey = key;
      _hasAnswered = true;
    });

    _answeredIds.add(question.id);

    if (key == question.correctAnswer) {
      _correctCount++;
    } else {
      _shakeCtrl.forward(from: 0);
    }
  }

  void _nextQuestion(ExploreService service) {
    if (_currentIndex < service.quizQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedKey  = null;
        _hasAnswered  = false;
      });
    } else {
      _finishQuiz(service);
    }
  }

  void _finishQuiz(ExploreService service) {
    service.submitQuizResult(
      correctCount: _correctCount,
      answeredQuestionIds: _answeredIds,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: service,
          child: _ResultPage(
            correct: _correctCount,
            total: service.quizQuestions.length,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ExploreService>();
    final questions = service.quizQuestions;

    if (questions.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0F),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF7C6FFF)),
              SizedBox(height: 16),
              Text('Đang tải câu hỏi...', style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    final q = questions[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(questions.length),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuestionCard(q),
                    const SizedBox(height: 24),
                    ...q.options.entries.map(
                          (e) => _buildOptionButton(e.key, e.value, q),
                    ),
                    if (_hasAnswered) ...[
                      const SizedBox(height: 16),
                      _buildExplanation(q),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            if (_hasAnswered) _buildNextButton(service, questions),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(int total) {
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
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đố vui',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Câu ${_currentIndex + 1} / $total',
                  style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
                ),
              ],
            ),
          ),
          // Score indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x2222C55E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x4422C55E)),
            ),
            child: Text(
              '$_correctCount / ${_currentIndex + (_hasAnswered ? 1 : 0)}',
              style: const TextStyle(
                color: Color(0xFF4ADE80), fontSize: 13, fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuizQuestion q) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a1a2e), Color(0xFF0f1f40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2A3A5A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0x227C6FFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '🧠  Câu hỏi',
              style: TextStyle(color: Color(0xFFA89FFF), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            q.question,
            style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String key, String value, QuizQuestion q) {
    final isCorrect  = key == q.correctAnswer;
    final isSelected = key == _selectedKey;

    Color bgColor;
    Color borderColor;
    Color textColor;
    Widget? trailingIcon;

    if (!_hasAnswered) {
      bgColor     = const Color(0xFF16161F);
      borderColor = const Color(0xFF2A2A3A);
      textColor   = Colors.white;
    } else if (isCorrect) {
      bgColor     = const Color(0x2222C55E);
      borderColor = const Color(0xFF22C55E);
      textColor   = const Color(0xFF4ADE80);
      trailingIcon = const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 20);
    } else if (isSelected) {
      bgColor     = const Color(0x22EF4444);
      borderColor = const Color(0xFFEF4444);
      textColor   = const Color(0xFFFC8181);
      trailingIcon = const Icon(Icons.cancel_rounded, color: Color(0xFFFC8181), size: 20);
    } else {
      bgColor     = const Color(0xFF111118);
      borderColor = const Color(0xFF1E1E2E);
      textColor   = const Color(0xFF444444);
    }

    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) {
        double offset = 0;
        if (isSelected && !isCorrect) {
          offset = _shakeAnim.value * ((_shakeCtrl.value < 0.5) ? 1 : -1);
        }
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () => _selectAnswer(key, q),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              // Option label (A, B, C, D)
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: _hasAnswered && isCorrect
                      ? const Color(0xFF22C55E)
                      : _hasAnswered && isSelected
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF2A2A3A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    key.split('_').last.toUpperCase(),
                    style: TextStyle(
                      color: _hasAnswered && (isCorrect || isSelected)
                          ? Colors.white
                          : const Color(0xFF666666),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: textColor, fontSize: 15, fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                trailingIcon,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplanation(QuizQuestion q) {
    final isCorrect = _selectedKey == q.correctAnswer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0x1022C55E) : const Color(0x10EF4444),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect ? const Color(0x4022C55E) : const Color(0x40EF4444),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isCorrect ? '✅' : '💡', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              q.explanation ?? (isCorrect ? 'Chính xác!' : 'Chưa đúng rồi!'),
              style: TextStyle(
                color: isCorrect ? const Color(0xFF4ADE80) : const Color(0xFFFC8181),
                fontSize: 14, height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(ExploreService service, List<QuizQuestion> questions) {
    final isLast = _currentIndex == questions.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0F),
        border: Border(top: BorderSide(color: Color(0xFF1A1A2A))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () => _nextQuestion(service),
          style: ElevatedButton.styleFrom(
            backgroundColor: isLast ? const Color(0xFF22C55E) : const Color(0xFF7C6FFF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Text(
            isLast ? '🏆  Xem kết quả' : 'Câu tiếp theo  →',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// Result page
// ════════════════════════════════════════════════════════════════════════════════
class _ResultPage extends StatelessWidget {
  final int correct;
  final int total;

  const _ResultPage({required this.correct, required this.total});

  String get _emoji {
    final pct = correct / total;
    if (pct == 1.0) return '🏆';
    if (pct >= 0.8) return '🎉';
    if (pct >= 0.6) return '👍';
    return '💪';
  }

  String get _message {
    final pct = correct / total;
    if (pct == 1.0) return 'Hoàn hảo! Bạn thật xuất sắc!';
    if (pct >= 0.8) return 'Tuyệt vời! Bạn nhớ rất nhiều!';
    if (pct >= 0.6) return 'Khá tốt! Tiếp tục cố gắng nhé!';
    return 'Đọc lại facts và thử lại nhé!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_emoji, style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 24),
              Text(
                _message,
                style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Score circle
              Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C6FFF), Color(0xFF5B4FF0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C6FFF).withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$correct/$total',
                      style: const TextStyle(
                        color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'đúng',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // Pop về explore page
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C6FFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Về trang Khám phá',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Làm lại',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}