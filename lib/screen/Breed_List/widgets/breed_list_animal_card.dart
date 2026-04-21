import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../home/animal_category_model.dart';

class BreedListAnimalCard extends StatelessWidget {
  final Map<String, dynamic> animal;
  final AnimalCategory category;
  final VoidCallback onTap;

  const BreedListAnimalCard({
    super.key,
    required this.animal,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final nameVi = animal['name_vietnamese'] ?? 'Chưa có tên';
    final nameEn = animal['name_english'] ?? '';

    final dynamic imageUrlRaw = animal['image_url'];
    final String imageUrl = (imageUrlRaw != null && imageUrlRaw.toString().isNotEmpty)
        ? imageUrlRaw.toString()
        : '';

    final conservationStatus = animal['conservation_status'] ?? '';
    final isEndangered = animal['is_endangered'] ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: category.gradient[0].withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Flexible(
                  flex: 3,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          cacheKey: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              color: category.gradient[0],
                              strokeWidth: 2,
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            return _buildPlaceholderImage();
                          },
                          httpHeaders: const {
                            'User-Agent': 'MyAnimalApp/1.0 (son623200@gmail.com)',
                          },
                          maxWidthDiskCache: 600,
                          maxHeightDiskCache: 600,
                          memCacheHeight: 600,
                          memCacheWidth: 600,
                        )
                            : _buildPlaceholderImage(),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (isEndangered)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.warning_amber, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'Nguy cấp',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Info — dùng IntrinsicHeight để tự co giãn theo cỡ chữ
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nameVi,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        nameEn,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: category.gradient[0],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (conservationStatus.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: category.gradient[0].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            conservationStatus,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: category.gradient[0],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: category.gradient,
        ),
      ),
      child: Center(
        child: Icon(
          category.icon,
          size: 50,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }
}