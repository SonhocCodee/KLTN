import 'package:flutter/material.dart';

class AnimalCategory {
  final String id; // 'dog', 'cat', 'bird', etc
  final String nameVi;
  final String nameEn;
  final IconData icon;
  final List<Color> gradient;
  final String imageAssetPath; // Ảnh local trong assets

  AnimalCategory({
    required this.id,
    required this.nameVi,
    required this.nameEn,
    required this.icon,
    required this.gradient,
    required this.imageAssetPath,
  });

  // Config cố định cho các loài
  static final List<AnimalCategory> allCategories = [
    AnimalCategory(
      id: 'dog',
      nameVi: 'Chó',
      nameEn: 'Dog',
      icon: Icons.pets,
      gradient: [Color(0xFFFBBF24), Color(0xFFF97316)],
      imageAssetPath: 'assets/animals/dog.jpg',
    ),
    AnimalCategory(
      id: 'cat',
      nameVi: 'Mèo',
      nameEn: 'Cat',
      icon: Icons.pets,
      gradient: [Color(0xFFEC4899), Color(0xFFDB2777)],
      imageAssetPath: 'assets/animals/cat.jpg',
    ),
    AnimalCategory(
      id: 'bird',
      nameVi: 'Chim',
      nameEn: 'Bird',
      icon: Icons.flutter_dash,
      gradient: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
      imageAssetPath: 'assets/animals/bird.jpg',
    ),
    AnimalCategory(
      id: 'fish',
      nameVi: 'Cá',
      nameEn: 'Fish',
      icon: Icons.set_meal,
      gradient: [Color(0xFF14B8A6), Color(0xFF0891B2)],
      imageAssetPath: 'assets/animals/fish.jpg',
    ),
    AnimalCategory(
      id: 'reptile',
      nameVi: 'Bò Sát',
      nameEn: 'Reptile',
      icon: Icons.bug_report,
      gradient: [Color(0xFF84CC16), Color(0xFF65A30D)],
      imageAssetPath: 'assets/animals/reptile.jpg',
    ),
    AnimalCategory(
      id: 'mammal',
      nameVi: 'Thú Hoang Dã',
      nameEn: 'Wild Mammal',
      icon: Icons.whatshot,
      gradient: [Color(0xFF9333EA), Color(0xFF7E22CE)],
      imageAssetPath: 'assets/animals/mammal.jpg',
    ),
  ];

  static AnimalCategory? getById(String id) {
    try {
      return allCategories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }
}

class AnimalCategoryData {
  final AnimalCategory category;
  final int count;

  AnimalCategoryData({
    required this.category,
    required this.count,
  });
}