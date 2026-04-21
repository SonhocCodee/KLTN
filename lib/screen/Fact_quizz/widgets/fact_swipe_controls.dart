import 'package:flutter/material.dart';

class FactSwipeControls extends StatelessWidget {
  final bool isLast;
  final VoidCallback onNextPage;

  const FactSwipeControls({
    super.key,
    required this.isLast,
    required this.onNextPage,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 64,
              child: ElevatedButton(
                onPressed: onNextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLast ? colorScheme.primary : colorScheme.inverseSurface,
                  foregroundColor: isLast ? colorScheme.onPrimary : colorScheme.onInverseSurface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLast ? 'KHÁM PHÁ XONG' : 'TIẾP TỤC',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    const SizedBox(width: 8),
                    Icon(isLast ? Icons.check_circle_outline : Icons.arrow_forward_ios, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}