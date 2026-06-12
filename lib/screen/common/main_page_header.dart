import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../language/Locale_provider.dart';

class MainPageHeader extends StatelessWidget {
  final String title;
  final String highlightedText;
  final String? emoji;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  const MainPageHeader({
    super.key,
    required this.title,
    required this.highlightedText,
    this.emoji,
    this.action,
    this.padding = const EdgeInsets.fromLTRB(24, 20, 24, 0),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();
    final now = DateTime.now();
    final weekdays = [
      '',
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    final months = [
      '',
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];
    final dateStr = '${weekdays[now.weekday]}, ${now.day} ${months[now.month]}';

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            t.tr(dateStr).toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: RichText(
              maxLines: 1,
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  color: colorScheme.onSurface,
                ),
                children: [
                  TextSpan(text: t.tr(title)),
                  if (highlightedText.isNotEmpty)
                    TextSpan(
                      text: ' ${t.tr(highlightedText)}',
                      style: TextStyle(color: colorScheme.primary),
                    ),
                  if (emoji != null)
                    TextSpan(
                      text: ' $emoji',
                      style: const TextStyle(fontSize: 25),
                    ),
                ],
              ),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 14),
            Center(child: action!),
          ],
        ],
      ),
    );
  }
}
