import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../language/Locale_provider.dart'; // Đảm bảo đường dẫn này đúng
import '../../Breed_List/Breed list screen.dart';
import '../animal_category_model.dart';
import '../home_screen.dart'; // Để gọi _getShortDesc (sẽ di chuyển hàm này)

class HomeAnimalSection extends StatelessWidget {
  final AnimalCategoryData data;
  final String Function(String) getShortDesc;

  const HomeAnimalSection({
    super.key,
    required this.data,
    required this.getShortDesc,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.pets,
                    color: data.category.gradient[0].withOpacity(0.6),
                    size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.tr(data.category.nameVi), // Dịch tên Category
                          style: TextStyle(
                              fontSize: 22, color: colorScheme.onSurface)),
                      Text(
                        getShortDesc(data.category.id),
                        style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                _buildBadge(data, t),
              ],
            ),
          ),
          _InteractiveAnimalCard(data: data),
        ],
      ),
    );
  }

  Widget _buildBadge(AnimalCategoryData data, LocaleProvider t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: data.category.gradient[0].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        t.tr(data.displayText), // Dịch nội dung badge (vd: "15 loài" hoặc "Chưa có")
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: data.category.gradient[0],
        ),
      ),
    );
  }
}

class _InteractiveAnimalCard extends StatefulWidget {
  final AnimalCategoryData data;
  const _InteractiveAnimalCard({super.key, required this.data});

  @override
  State<_InteractiveAnimalCard> createState() => _InteractiveAnimalCardState();
}

class _InteractiveAnimalCardState extends State<_InteractiveAnimalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation =
        Tween<double>(begin: 1.0, end: 0.98).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasData = widget.data.hasData;
    final category = widget.data.category;
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    return GestureDetector(
      onTapDown: (_) => hasData ? _controller.forward() : null,
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        if (hasData) {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BreedListScreen(
                category: category,
                totalCount: widget.data.count,
              ),
            ),
          );
        }
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            image: DecorationImage(
              image: AssetImage(category.imageAssetPath),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Stack(
            children: [
              // Lớp phủ đen trong suốt để nổi bật text trên ảnh (giữ nguyên màu đen)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2), // Giữ nguyên màu sáng vì nền đã làm tối
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hasData ? t.tr('Khám phá ngay') : t.tr('Đang cập nhật'),
                            style: const TextStyle(
                              color: Colors.white, // Giữ màu trắng
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.auto_awesome,
                              color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (!hasData)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black45, // Giữ màu đen mờ che ảnh
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: Icon(Icons.lock_clock,
                        color: Colors.white, size: 40),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}