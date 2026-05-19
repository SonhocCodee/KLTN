import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../language/Locale_provider.dart';
import 'animal_detail_utils.dart';

class AnimalDetailConservation extends StatelessWidget {
  final Map<String, dynamic> animal;

  const AnimalDetailConservation({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    final conservationStatus = animal['conservation_status'] ?? '';
    if (conservationStatus.isEmpty) return const SizedBox.shrink();

    final isEndangered = animal['is_endangered'] ?? false;
    final statusVi = t.tr(AnimalDetailUtils.translateValue('conservation', conservationStatus)); // Dịch tự động từ Utils

    final Color statusColor = isEndangered ? colorScheme.error : const Color(0xFF16A34A);
    final Color bgColor = isEndangered ? colorScheme.errorContainer : const Color(0xFF16A34A).withOpacity(0.1);
    final Color borderColor = isEndangered ? colorScheme.error : const Color(0xFF16A34A).withOpacity(0.3);

    final String statusIcon = isEndangered ? '🔴' : '🟢';
    final String statusDesc = isEndangered
        ? t.tr('Loài này đang đối mặt với nguy cơ tuyệt chủng')
        : t.tr('Quần thể ổn định, không bị đe dọa nghiêm trọng');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimalDetailUtils.buildSectionTitle(t.tr('Tình trạng bảo tồn'), '🛡️', colorScheme),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
          child: Row(
            children: [
              Text(statusIcon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(statusVi, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: statusColor)),
                    const SizedBox(height: 4),
                    Text(statusDesc, style: TextStyle(fontSize: 13, color: statusColor.withOpacity(0.8), height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}