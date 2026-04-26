import 'package:flutter/material.dart';
import '../service/Identify_service.dart';

class IdentifyLoadingOverlay extends StatelessWidget {
  final IdentifyService service;
  const IdentifyLoadingOverlay({super.key, required this.service});

  static const _accentOrange = Color(0xFFEF6C00);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (!service.isAnalyzing) return const SizedBox.shrink();

    return Container(
      color: colorScheme.surface.withOpacity(0.85),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: colorScheme.shadow.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 10))]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(width: 60, height: 60, child: CircularProgressIndicator(color: _accentOrange, strokeWidth: 4)),
                  Icon(Icons.pets_rounded, color: colorScheme.primary, size: 28),
                ],
              ),
              const SizedBox(height: 24),
              Text('Đang đánh hơi...', style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                service.aiSource == 'groq' ? '⚡ Groq Llama 4 đang dò tìm' : ' Đang nhận diện',
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}