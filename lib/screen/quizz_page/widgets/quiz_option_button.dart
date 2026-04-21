import 'package:flutter/material.dart';
import '../../ExploreScreen/explore_service.dart';


class QuizOptionButton extends StatelessWidget {
  final String optionKey;
  final String value;
  final QuizQuestion question;
  final String? selectedKey;
  final bool hasAnswered;
  final Animation<double> shakeAnim;
  final AnimationController shakeCtrl;
  final Function(String, QuizQuestion) onSelect;

  const QuizOptionButton({
    super.key,
    required this.optionKey,
    required this.value,
    required this.question,
    required this.selectedKey,
    required this.hasAnswered,
    required this.shakeAnim,
    required this.shakeCtrl,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final isCorrect  = optionKey == question.correctAnswer;
    final isSelected = optionKey == selectedKey;

    final successColor = isDark ? Colors.green.shade400 : Colors.green.shade600;
    final errorColor = isDark ? Colors.red.shade400 : Colors.red.shade600;

    Color bgColor;
    Color borderColor;
    Color textColor;
    Widget? trailingIcon;

    if (!hasAnswered) {
      bgColor     = colorScheme.surfaceContainerHighest;
      borderColor = colorScheme.outlineVariant;
      textColor   = colorScheme.onSurface;
    } else if (isCorrect) {
      bgColor     = successColor.withOpacity(0.15);
      borderColor = successColor;
      textColor   = successColor;
      trailingIcon = Icon(Icons.check_circle_rounded, color: successColor, size: 20);
    } else if (isSelected) {
      bgColor     = errorColor.withOpacity(0.15);
      borderColor = errorColor;
      textColor   = errorColor;
      trailingIcon = Icon(Icons.cancel_rounded, color: errorColor, size: 20);
    } else {
      bgColor     = colorScheme.surfaceContainer;
      borderColor = colorScheme.outlineVariant.withOpacity(0.5);
      textColor   = colorScheme.onSurfaceVariant.withOpacity(0.6);
    }

    return AnimatedBuilder(
      animation: shakeAnim,
      builder: (_, child) {
        double offset = 0;
        if (isSelected && !isCorrect) {
          offset = shakeAnim.value * ((shakeCtrl.value < 0.5) ? 1 : -1);
        }
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () => onSelect(optionKey, question),
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
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: hasAnswered && isCorrect
                      ? successColor
                      : hasAnswered && isSelected
                      ? errorColor
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: (!hasAnswered || (!isCorrect && !isSelected))
                      ? Border.all(color: colorScheme.outlineVariant)
                      : null,
                ),
                child: Center(
                  child: Text(
                    optionKey.split('_').last.toUpperCase(),
                    style: TextStyle(
                      color: hasAnswered && (isCorrect || isSelected)
                          ? Colors.white
                          : colorScheme.onSurfaceVariant,
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
}