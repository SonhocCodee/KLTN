import 'package:flutter/material.dart';

class QuizResultPage extends StatelessWidget {
  final int correct;
  final int total;

  const QuizResultPage({super.key, required this.correct, required this.total});

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                style: TextStyle(
                  color: colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Score circle
              Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
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
                      style: TextStyle(
                        color: colorScheme.onPrimary, fontSize: 36, fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'đúng',
                      style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.8), fontSize: 14),
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
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Về trang Khám phá',
                    style: TextStyle(color: colorScheme.onPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Làm lại',
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}