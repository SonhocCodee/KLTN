import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../language/Locale_provider.dart';

class HomeTopBar extends StatelessWidget {
  final Widget searchBox;

  const HomeTopBar({super.key, required this.searchBox});

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
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
            child: Column(
              children: [
                Text(
                  t.tr(dateStr).toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 9),
                const _HomeBrandTitle(),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: searchBox,
          ),
        ],
      ),
    );
  }
}

class _HomeBrandTitle extends StatelessWidget {
  const _HomeBrandTitle();

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF16A34A);
    const teal = Color(0xFF0891B2);
    const orange = Color(0xFFF97316);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: RichText(
        maxLines: 1,
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
          children: [
            TextSpan(
              text: 'zoo',
              style: TextStyle(color: green),
            ),
            TextSpan(
              text: 'tre',
              style: TextStyle(color: teal),
            ),
            TextSpan(
              text: 'k',
              style: TextStyle(color: orange),
            ),
          ],
        ),
      ),
    );
  }
}
