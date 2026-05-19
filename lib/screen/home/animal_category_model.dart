import 'package:flutter/material.dart';

class AnimalCategory {
  final String id;           // key nội bộ: 'dog', 'lion', 'tiger'
  final String animalType;   // khớp với DB animal_type: 'mammal', 'bird'...
  final String nameVi;
  final String nameEn;
  final IconData icon;
  final List<Color> gradient;
  final String imageAssetPath;
  final int totalExpected;
  final bool isEnabled;

  AnimalCategory({
    required this.id,
    required this.animalType,
    required this.nameVi,
    required this.nameEn,
    required this.icon,
    required this.gradient,
    required this.imageAssetPath,
    required this.totalExpected,
    this.isEnabled = true,
  });

  static final List<AnimalCategory> allCategories = [
    AnimalCategory(
      id: 'dog',
      animalType: 'dog',
      nameVi: 'Chó',
      nameEn: 'Dog',
      icon: Icons.pets,
      gradient: [Color(0xFFFBBF24), Color(0xFFF97316)],
      imageAssetPath: 'assets/images/Golden-Retrieve.jpg',
      totalExpected: 360,
      isEnabled: true,
    ),
    AnimalCategory(
      id: 'cat',
      animalType: 'cat',
      nameVi: 'Mèo',
      nameEn: 'Cat',
      icon: Icons.pets,
      gradient: [Color(0xFFEC4899), Color(0xFFDB2777)],
      imageAssetPath: 'assets/images/Cat.jpg',
      totalExpected: 73,
      isEnabled: true,
    ),
    AnimalCategory(
      id: 'tiger',
      animalType: 'mammal',  // DB dùng 'mammal' cho hổ
      nameVi: 'Hổ',
      nameEn: 'Tiger',
      icon: Icons.close_fullscreen,
      gradient: [Color(0xFFFF6B35), Color(0xFFF7931E)],
      imageAssetPath: 'assets/images/tiger.jpg',
      totalExpected: 9,
      isEnabled: true,
    ),
    AnimalCategory(
      id: 'lion',
      animalType: 'mammal',
      nameVi: 'Sư Tử',
      nameEn: 'Lion',
      icon: Icons.stars,
      gradient: [Color(0xFFFFB800), Color(0xFFFF8A00)],
      imageAssetPath: 'assets/images/lion.jpg',
      totalExpected: 5,
      isEnabled: true,
    ),
    AnimalCategory(
      id: 'bear',
      animalType: 'mammal',
      nameVi: 'Gấu',
      nameEn: 'Bear',
      icon: Icons.landscape,
      gradient: [Color(0xFF8B4513), Color(0xFF654321)],
      imageAssetPath: 'assets/images/bear.jpg',
      totalExpected: 10,
      isEnabled: true,
    ),
    AnimalCategory(
      id: 'horse',
      animalType: 'horse',
      nameVi: 'Ngựa',
      nameEn: 'Horse',
      icon: Icons.directions_run,
      gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      imageAssetPath: 'assets/images/horse.jpg',
      totalExpected: 350,
      isEnabled: true,
    ),
    AnimalCategory(
      id: 'cattle',
      animalType: 'cattle',
      nameVi: 'Bò',
      nameEn: 'Cattle',
      icon: Icons.agriculture,
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
      imageAssetPath: 'assets/images/cow.jpg',
      totalExpected: 800,
      isEnabled: true,
    ),
    AnimalCategory(
      id: 'buffalo',
      animalType: 'buffalo',
      nameVi: 'Trâu',
      nameEn: 'Buffalo',
      icon: Icons.water,
      gradient: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
      imageAssetPath: 'assets/images/buffalo.jpg',
      totalExpected: 18,
      isEnabled: true,
    ),
    AnimalCategory(
      id: 'bird',
      animalType: 'bird',
      nameVi: 'Chim',
      nameEn: 'Bird',
      icon: Icons.flutter_dash,
      gradient: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
      imageAssetPath: 'assets/images/bird.jpg',
      totalExpected: 10000,
      isEnabled: false,
    ),
    AnimalCategory(
      id: 'fish',
      animalType: 'fish',
      nameVi: 'Cá',
      nameEn: 'Fish',
      icon: Icons.set_meal,
      gradient: [Color(0xFF14B8A6), Color(0xFF0891B2)],
      imageAssetPath: 'assets/images/fish.jpg',
      totalExpected: 35000,
      isEnabled: false,
    ),
    AnimalCategory(
      id: 'reptile',
      animalType: 'reptile',
      nameVi: 'Bò Sát',
      nameEn: 'Reptile',
      icon: Icons.bug_report,
      gradient: [Color(0xFF84CC16), Color(0xFF65A30D)],
      imageAssetPath: 'assets/images/reptile.jpg',
      totalExpected: 11000,
      isEnabled: false,
    ),
  ];

  static AnimalCategory? getById(String id) {
    try {
      return allCategories.firstWhere((cat) => cat.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Tìm category theo animal_type từ DB
  static AnimalCategory? getByAnimalType(String type) {
    try {
      return allCategories.firstWhere((cat) => cat.animalType == type);
    } catch (_) {
      return null;
    }
  }

  static List<AnimalCategory> getEnabledCategories() =>
      allCategories.where((cat) => cat.isEnabled).toList();

  static List<AnimalCategory> getDisabledCategories() =>
      allCategories.where((cat) => !cat.isEnabled).toList();
}

class AnimalCategoryData {
  final AnimalCategory category;
  final int count;

  AnimalCategoryData({required this.category, required this.count});

  double get completionPercentage {
    if (category.totalExpected == 0) return 0;
    return (count / category.totalExpected * 100).clamp(0, 100);
  }

  String get displayText {
    if (count == 0) return 'Sắp ra mắt';
    if (completionPercentage >= 80) return '$count giống';
    return '$count/${category.totalExpected} loài';
  }

  bool get hasData => count > 0;
}