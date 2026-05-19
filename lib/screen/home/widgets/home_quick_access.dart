import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../language/Locale_provider.dart'; // Đảm bảo đường dẫn này đúng
import '../../Breed_List/Breed list screen.dart';
import '../animal_category_model.dart';

class HomeQuickAccess extends StatelessWidget {
  final List<AnimalCategoryData> categoryData;

  const HomeQuickAccess({super.key, required this.categoryData});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    return SizedBox(
      height: 120,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categoryData.length,
        itemBuilder: (context, index) {
          final item = categoryData[index];
          final cat = item.category;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: InkWell(
              onTap: () {
                // Điều hướng đến trang danh sách loài tương ứng
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BreedListScreen(
                      category: cat,
                      totalCount: item.count,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cat.gradient[0].withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: ClipOval(child: _getLottieForCategory(cat.id, context)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.tr(cat.nameVi), // Dịch tên Category
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getLottieForCategory(String id, BuildContext context) {
    String fileName = 'default_anim.json';
    if (id.contains('dog')) fileName = 'dog_anim.json';
    if (id.contains('cat')) fileName = 'cat_anim.json';
    if (id.contains('cattle')) fileName = 'cocattle_anim.json';
    if (id.contains('tiger')) fileName = 'Tiger_anim.json';
    if (id.contains('lion')) fileName = 'Lion_anim.json';
    if (id.contains('bear')) fileName = 'bear_anim.json';
    if (id.contains('horse')) fileName = 'horse_anim.json';
    if (id.contains('buffalo')) fileName = 'buffalo_anim.json';

    return Lottie.asset(
      'assets/icons/$fileName',
      fit: BoxFit.cover,
      repeat: true,
      animate: true,
      errorBuilder: (ctx, error, stackTrace) =>
          Icon(Icons.pets, color: Theme.of(ctx).colorScheme.onSurfaceVariant),
    );
  }
}