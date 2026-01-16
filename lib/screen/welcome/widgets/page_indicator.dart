import 'package:flutter/material.dart';

class PageIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final List<Color> gradientColors;
  final Function(int) onDotTap;

  const PageIndicator({
    super.key,
    required this.currentPage,
    required this.pageCount,
    required this.gradientColors,
    required this.onDotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;
        return GestureDetector(
          onTap: () => onDotTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 40 : 10,
            height: 10,
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: gradientColors,
              )
                  : null,
              color: isActive ? null : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(5),
              boxShadow: isActive
                  ? [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
