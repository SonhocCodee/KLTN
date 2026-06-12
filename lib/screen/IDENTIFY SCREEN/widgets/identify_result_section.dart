import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../language/Locale_provider.dart';
import '../service/Identify_service.dart';

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
    final t = context.watch<LocaleProvider>();

    // Ảnh không hợp lệ
    if (service.isNotAnimal) {
      return FadeTransition(
        opacity: fadeAnim,
        child: SlideTransition(
          position: slideAnim,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.redAccent.withOpacity(0.35),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hide_image_rounded,
                    color: Colors.redAccent,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  t.tr('Ảnh không hợp lệ'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.tr(
                    'Không tìm thấy động vật trong ảnh này.\nHãy thử lại với ảnh chứa mèo, chó hoặc các loài động vật khác.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Không có kết quả
    if (service.resultNameVi == null) return const SizedBox.shrink();

    // Tên hiển thị theo ngôn ngữ
    // Dòng chính: tiếng Anh khi isEnglish, tiếng Việt khi không
    // Dòng phụ (italic): luôn hiện tên còn lại
    final String primaryName = t.isEnglish
        ? (service.resultNameEn ?? service.resultNameVi ?? '')
        : (service.resultNameVi ?? '');
    final String secondaryName = t.isEnglish
        ? (service.resultNameVi ?? '')
        : (service.resultNameEn ?? '');

    // Kết quả bình thường
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
                Text(
                  t.tr('Kết Quả Hồ Sơ'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
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
                    color: canNavigate
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: canNavigate
                          ? colorScheme.primary.withOpacity(0.1)
                          : colorScheme.shadow.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Ảnh
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: service.resultImageUrl != null
                              ? Image.network(
                                  service.resultImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildPlaceholder(colorScheme),
                                )
                              : service.selectedImage != null
                              ? Image.file(
                                  service.selectedImage!,
                                  fit: BoxFit.cover,
                                )
                              : _buildPlaceholder(colorScheme),
                        ),
                      ),
                    ),

                    // Thông tin
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 16,
                          top: 12,
                          bottom: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tên chính theo ngôn ngữ
                            Text(
                              primaryName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: colorScheme.onSurface,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Tên phụ (ngôn ngữ còn lại, italic)
                            if (secondaryName.isNotEmpty)
                              Text(
                                secondaryName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _accentOrange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${service.resultConfidence ?? '?'}% ${t.tr('Khớp')}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _accentOrange,
                                    ),
                                  ),
                                ),
                                if (canNavigate)
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                              ],
                            ),
                            if (!canNavigate) ...[
                              const SizedBox(height: 8),
                              Text(
                                t.tr('Loài này chưa có trong từ điển'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
      child: Center(
        child: Icon(
          Icons.pets_rounded,
          color: colorScheme.outlineVariant,
          size: 36,
        ),
      ),
    );
  }
}
