import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../animal_category_model.dart';

class HomeQuickAccess extends StatelessWidget {
  final List<AnimalCategoryData> categoryData;

  const HomeQuickAccess({super.key, required this.categoryData});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categoryData.length,
        itemBuilder: (context, index) {
          final cat = categoryData[index].category;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: cat.gradient[0].withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: ClipOval(child: _getLottieForCategory(cat.id)),
                ),
                const SizedBox(height: 8),
                Text(
                  cat.nameVi,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D4B2A),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _getLottieForCategory(String id) {
    String fileName = 'default_anim.json';
    if (id.contains('dog')) fileName = 'dog_anim.json';
    if (id.contains('cat')) fileName = 'cat_anim.json';
    if (id.contains('bird')) fileName = 'bird_anim.json';

    return Lottie.asset(
      'assets/icons/$fileName',
      fit: BoxFit.cover,
      repeat: true,
      animate: true,
      errorBuilder: (context, error, stackTrace) =>
      const Icon(Icons.pets, color: Colors.grey),
    );
  }
}