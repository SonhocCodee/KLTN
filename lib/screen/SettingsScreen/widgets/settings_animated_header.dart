import 'package:flutter/material.dart';

class SettingsAnimatedHeader extends StatelessWidget {
  final Animation<double> scaleAnimation;
  final Color accentOrange;

  const SettingsAnimatedHeader({
    super.key,
    required this.scaleAnimation,
    required this.accentOrange,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          ScaleTransition(
            scale: scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.pets_rounded, size: 50, color: accentOrange),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tùy chỉnh chuyến thám hiểm của bạn',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}