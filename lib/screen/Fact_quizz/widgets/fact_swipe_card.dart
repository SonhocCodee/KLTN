import 'package:flutter/material.dart';
import '../../ExploreScreen/explore_service.dart';

class FactSwipeCard extends StatelessWidget {
  final DailyAnimal animal;
  final Color accentColor;
  final Animation<double> fadeAnim;

  const FactSwipeCard({
    super.key,
    required this.animal,
    required this.accentColor,
    required this.fadeAnim,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: fadeAnim,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest, // Màu nền thẻ adaptive
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  Stack(
                    children: [
                      if (animal.imageUrl != null)
                        Image.network(
                          animal.imageUrl!,
                          height: 280,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(colorScheme),
                        )
                      else
                        _imagePlaceholder(colorScheme),
                      Positioned(
                        top: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withOpacity(0.85),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.favorite_border_rounded, size: 20, color: colorScheme.onSurface),
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                animal.animalType?.toUpperCase() ?? 'ĐỘNG VẬT',
                                style: const TextStyle(
                                  color: Colors.black87, // Giữ đen vì accentColor luôn là màu pastel sáng
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          animal.nameVietnamese,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        if (animal.nameEnglish != null)
                          Text(
                            animal.nameEnglish!,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),

                        const SizedBox(height: 24),
                        Text(
                          "Bạn có biết?",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          animal.funFactVietnamese ?? 'Chưa có thông tin.',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 24),
                        Divider(color: colorScheme.outlineVariant),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            if (animal.primaryHabitat != null)
                              _infoChip(Icons.location_on_rounded, animal.primaryHabitat!, accentColor, colorScheme),
                            if (animal.conservationStatus != null)
                              _infoChip(Icons.shield_rounded, animal.conservationStatus!, accentColor, colorScheme),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder(ColorScheme colorScheme) {
    return Container(
      height: 280,
      width: double.infinity,
      color: colorScheme.surfaceContainer,
      child: Center(child: Icon(Icons.pets_rounded, size: 64, color: colorScheme.outlineVariant)),
    );
  }

  Widget _infoChip(IconData icon, String text, Color accentColor, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.2), // Giảm độ đậm để hợp Dark mode hơn
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}