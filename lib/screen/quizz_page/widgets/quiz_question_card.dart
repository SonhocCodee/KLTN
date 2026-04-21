import 'package:flutter/material.dart';
import '../../ExploreScreen/explore_service.dart';

class QuizQuestionCard extends StatelessWidget {
  final QuizQuestion question;

  const QuizQuestionCard({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primaryContainer, colorScheme.surfaceContainerHighest],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '🧠  Câu hỏi',
              style: TextStyle(color: colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            question.question,
            style: TextStyle(
              color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w600, height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}