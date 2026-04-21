import 'package:flutter/material.dart';
import '../identify_service.dart';

class IdentifyHeader extends StatelessWidget {
  final IdentifyService service;
  const IdentifyHeader({super.key, required this.service});

  static const _accentOrange = Color(0xFFEF6C00);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Camera Thú Vị',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.pets_rounded, color: _accentOrange, size: 28),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Khám phá thế giới động vật qua ống kính',
                  style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (service.aiSource.isNotEmpty) _buildAiBadge(service.aiSource, colorScheme),
        ],
      ),
    );
  }

  Widget _buildAiBadge(String aiSource, ColorScheme colorScheme) {
    final isGemini = aiSource == 'gemini';
    final isGroq = aiSource == 'groq';
    final Color color = isGemini ? const Color(0xFF4285F4) : isGroq ? const Color(0xFF7C3AED) : colorScheme.primary;
    final String label = isGemini ? 'Gemini AI' : isGroq ? 'Groq AI' : aiSource == 'local_fallback' ? 'Local AI*' : 'Local AI';
    final IconData icon = isGemini ? Icons.auto_awesome : isGroq ? Icons.bolt : Icons.memory;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}