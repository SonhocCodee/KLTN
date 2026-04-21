import 'package:flutter/material.dart';
import '../../ExploreScreen/explore_service.dart';


class QuizExplanation extends StatelessWidget {
  final QuizQuestion question;
  final String? selectedKey;

  const QuizExplanation({super.key, required this.question, required this.selectedKey});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final isCorrect = selectedKey == question.correctAnswer;

    final successColor = isDark ? Colors.green.shade400 : Colors.green.shade700;
    final errorColor = isDark ? Colors.red.shade400 : Colors.red.shade700;

    final color = isCorrect ? successColor : errorColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isCorrect ? '✅' : '💡', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              question.explanation ?? (isCorrect ? 'Chính xác!' : 'Chưa đúng rồi!'),
              style: TextStyle(
                color: color,
                fontSize: 14, height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}