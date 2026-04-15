import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../animal_list/Breed list screen.dart';
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
                      Text(data.category.nameVi,
                          style: const TextStyle(
                              fontSize: 22, color: Color(0xFF1E293B))),
                      Text(
                        getShortDesc(data.category.id),
                        style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                _buildBadge(data),
              ],
            ),
          ),
          _InteractiveAnimalCard(data: data),
        ],
      ),
    );
  }

  Widget _buildBadge(AnimalCategoryData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: data.category.gradient[0].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        data.displayText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: data.category.gradient[0],
        ),
      ),
    );
  }
}

// Giữ nguyên class _InteractiveAnimalCard (vì nó khá lớn và có animation)
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
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Stack(
            children: [
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
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hasData ? 'Khám phá ngay' : 'Đang cập nhật',
                            style: const TextStyle(
                              color: Colors.white,
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
                    color: Colors.black45,
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