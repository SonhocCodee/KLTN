import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ExploreScreen/explore_service.dart';

// Import các Widgets con
import 'widgets/quiz_top_bar.dart';
import 'widgets/quiz_question_card.dart';
import 'widgets/quiz_option_button.dart';
import 'widgets/quiz_explanation.dart';
import 'widgets/quiz_next_button.dart';
import 'widgets/quiz_result_page.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with SingleTickerProviderStateMixin {
  int    _currentIndex  = 0;
  String? _selectedKey;
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
          child: QuizResultPage(
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
    final colorScheme = Theme.of(context).colorScheme;

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: colorScheme.primary),
              const SizedBox(height: 16),
              Text('Đang tải câu hỏi...', style: TextStyle(color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    final q = questions[_currentIndex];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            QuizTopBar(
              currentIndex: _currentIndex,
              total: questions.length,
              correctCount: _correctCount,
              hasAnswered: _hasAnswered,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    QuizQuestionCard(question: q),
                    const SizedBox(height: 24),
                    ...q.options.entries.map(
                          (e) => QuizOptionButton(
                        optionKey: e.key,
                        value: e.value,
                        question: q,
                        selectedKey: _selectedKey,
                        hasAnswered: _hasAnswered,
                        shakeAnim: _shakeAnim,
                        shakeCtrl: _shakeCtrl,
                        onSelect: _selectAnswer,
                      ),
                    ),
                    if (_hasAnswered) ...[
                      const SizedBox(height: 16),
                      QuizExplanation(question: q, selectedKey: _selectedKey),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            if (_hasAnswered)
              QuizNextButton(
                isLast: _currentIndex == questions.length - 1,
                onNext: () => _nextQuestion(service),
              ),
          ],
        ),
      ),
    );
  }
}