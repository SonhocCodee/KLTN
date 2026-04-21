import 'package:flutter/material.dart';
import '../identify_service.dart';

class IdentifyResultSection extends StatelessWidget {
  final IdentifyService service;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final VoidCallback onOpenDetail;

  const IdentifyResultSection({
    super.key,
    required this.service,
    required this.fadeAnim,
    required this.slideAnim,
    required this.onOpenDetail,
  });

  static const _accentOrange = Color(0xFFEF6C00);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (service.resultNameVi == null) return const SizedBox.shrink();

    final canNavigate = service.resultAnimalId != null;

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.stars_rounded, color: _accentOrange),
                const SizedBox(width: 8),
                Text('Kết Quả Hồ Sơ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: canNavigate ? onOpenDetail : null,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: canNavigate ? colorScheme.primary : colorScheme.outlineVariant,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(color: canNavigate ? colorScheme.primary.withOpacity(0.1) : colorScheme.shadow.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))
                  ],
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                          width: 100, height: 100,
                          child: service.resultImageUrl != null
                              ? Image.network(service.resultImageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder(colorScheme))
                              : service.selectedImage != null
                              ? Image.file(service.selectedImage!, fit: BoxFit.cover)
                              : _buildPlaceholder(colorScheme),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, right: 16, top: 12, bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.resultNameVi ?? '',
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colorScheme.onSurface, height: 1.2),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              service.resultNameEn ?? '',
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: _accentOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                  child: Text('${service.resultConfidence ?? '?'}% Khớp', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _accentOrange)),
                                ),
                                if (canNavigate)
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                                    child: Icon(Icons.arrow_forward_rounded, size: 16, color: colorScheme.onPrimary),
                                  ),
                              ],
                            ),
                            if (!canNavigate) ...[
                              const SizedBox(height: 8),
                              const Text('Loài này chưa có trong từ điển', style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w600)),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainer,
      child: Center(child: Icon(Icons.pets_rounded, color: colorScheme.outlineVariant, size: 36)),
    );
  }
}