import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../language/Locale_provider.dart';
import '../dentify_history_screen.dart';
import '../service/Identify_service.dart';

class IdentifyHeader extends StatelessWidget {
  final IdentifyService service;
  const IdentifyHeader({super.key, required this.service});

  static const _accentOrange = Color(0xFFEF6C00);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _accentOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: _accentOrange,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    maxLines: 1,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        color: colorScheme.onSurface,
                      ),
                      children: [
                        TextSpan(text: '${t.tr('Camera')} '),
                        TextSpan(
                          text: t.tr('thú vị'),
                          style: const TextStyle(color: _accentOrange),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: service,
                  child: const IdentifyHistoryScreen(),
                ),
              ),
            ),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _accentOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _accentOrange.withValues(alpha: 0.28),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        size: 20,
                        color: _accentOrange,
                      ),
                      if (service.historyItems.isNotEmpty)
                        Positioned(
                          top: -6,
                          right: -8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            decoration: const BoxDecoration(
                              color: _accentOrange,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              service.historyItems.length > 99
                                  ? '99+'
                                  : '${service.historyItems.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 7),
                  Text(
                    t.tr('Lịch sử'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _accentOrange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
