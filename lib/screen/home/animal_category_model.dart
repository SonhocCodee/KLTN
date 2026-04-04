import 'package:flutter/material.dart';

class AnimalCategory {
  final String id; // 'dog', 'cat', 'bird', etc
  final String nameVi;
  final String nameEn;
  final IconData icon;
  final List<Color> gradient;
  final String imageAssetPath;
  final int totalExpected; //
  final bool isEnabled; //

  AnimalCategory({
    required this.id,
    required this.nameVi,
    required this.nameEn,
    required this.icon,
    required this.gradient,
    required this.imageAssetPath,
    required this.totalExpected,
    this.isEnabled = true, // Mặc định bật
  });

  // ═══════════════════════════════════════════════════════════════
  // 🎯 CONFIG: THÊM/SỬA LOÀI Ở ĐÂY
  // ═══════════════════════════════════════════════════════════════
  static final List<AnimalCategory> allCategories = [
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // ĐỘNG VẬT NHỘN NHỊP (Đã có data)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    AnimalCategory(
      id: 'dog',
      nameVi: 'Chó',
      nameEn: 'Dog',
      icon: Icons.pets,
      gradient: [Color(0xFFFBBF24), Color(0xFFF97316)],
      imageAssetPath: 'assets/images/Golden-Retrieve.jpg',
      totalExpected: 360, // Tổng số giống chó trên thế giới
      isEnabled: true,
    ),

    AnimalCategory(
      id: 'cat',
      nameVi: 'Mèo',
      nameEn: 'Cat',
      icon: Icons.pets,
      gradient: [Color(0xFFEC4899), Color(0xFFDB2777)],
      imageAssetPath: 'assets/images/Cat.jpg',
      totalExpected: 73, // Tổng số giống mèo được công nhận
      isEnabled: true,
    ),

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // ĐỘNG VẬT HOANG DÃ (Có data)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    AnimalCategory(
      id: 'tiger',
      nameVi: 'Hổ',
      nameEn: 'Tiger',
      icon: Icons.close_fullscreen,
      gradient: [Color(0xFFFF6B35), Color(0xFFF7931E)],
      imageAssetPath: 'assets/animals/tiger.jpg',
      totalExpected: 9, // 6 subspecies còn sống + 3 đã tuyệt chủng
      isEnabled: true,
    ),

    AnimalCategory(
      id: 'lion',
      nameVi: 'Sư Tử',
      nameEn: 'Lion',
      icon: Icons.stars,
      gradient: [Color(0xFFFFB800), Color(0xFFFF8A00)],
      imageAssetPath: 'assets/animals/lion.jpg',
      totalExpected: 8, // Các subspecies sư tử
      isEnabled: true,
    ),

    AnimalCategory(
      id: 'bear',
      nameVi: 'Gấu',
      nameEn: 'Bear',
      icon: Icons.landscape,
      gradient: [Color(0xFF8B4513), Color(0xFF654321)],
      imageAssetPath: 'assets/animals/bear.jpg',
      totalExpected: 10, // 8 loài chính + subspecies
      isEnabled: true,
    ),

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // ĐỘNG VẬT CHĂN NUÔI (Có data)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    AnimalCategory(
      id: 'horse',
      nameVi: 'Ngựa',
      nameEn: 'Horse',
      icon: Icons.directions_run,
      gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      imageAssetPath: 'assets/animals/horse.jpg',
      totalExpected: 350, // Tổng số giống ngựa trên thế giới
      isEnabled: true,
    ),

    AnimalCategory(
      id: 'cattle',
      nameVi: 'Bò',
      nameEn: 'Cattle',
      icon: Icons.agriculture,
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
      imageAssetPath: 'assets/animals/cattle.jpg',
      totalExpected: 800, // Tổng số giống bò trên thế giới
      isEnabled: true,
    ),

    AnimalCategory(
      id: 'buffalo',
      nameVi: 'Trâu',
      nameEn: 'Buffalo',
      icon: Icons.water,
      gradient: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
      imageAssetPath: 'assets/animals/buffalo.jpg',
      totalExpected: 18, // Các giống trâu chính
      isEnabled: true,
    ),

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // SẮP RA MẮT (Chưa có data - set isEnabled = false)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    AnimalCategory(
      id: 'bird',
      nameVi: 'Chim',
      nameEn: 'Bird',
      icon: Icons.flutter_dash,
      gradient: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
      imageAssetPath: 'assets/animals/bird.jpg',
      totalExpected: 10000, // Tổng số loài chim trên thế giới
      isEnabled: false, // 👈 TẮT vì chưa có data
    ),

    AnimalCategory(
      id: 'fish',
      nameVi: 'Cá',
      nameEn: 'Fish',
      icon: Icons.set_meal,
      gradient: [Color(0xFF14B8A6), Color(0xFF0891B2)],
      imageAssetPath: 'assets/animals/fish.jpg',
      totalExpected: 35000, // Tổng số loài cá
      isEnabled: false, // 👈 TẮT vì chưa có data
    ),

    AnimalCategory(
      id: 'reptile',
      nameVi: 'Bò Sát',
      nameEn: 'Reptile',
      icon: Icons.bug_report,
      gradient: [Color(0xFF84CC16), Color(0xFF65A30D)],
      imageAssetPath: 'assets/animals/reptile.jpg',
      totalExpected: 11000, // Tổng số loài bò sát
      isEnabled: false, // 👈 TẮT vì chưa có data
    ),

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 💡 CÁCH THÊM LOÀI MỚI:
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 1. Copy đoạn code AnimalCategory{...} bên trên
    // 2. Sửa: id, nameVi, nameEn, icon, gradient, imageAssetPath
    // 3. Sửa: totalExpected (tổng số loài/giống trên thế giới)
    // 4. Sửa: isEnabled = false (nếu chưa có data)
    // 5. Sau khi cào xong data → đổi isEnabled = true
    // 6. App sẽ tự động hiển thị!
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ];

  /// Lấy category theo ID
  static AnimalCategory? getById(String id) {
    try {
      return allCategories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Lấy danh sách categories đã bật
  static List<AnimalCategory> getEnabledCategories() {
    return allCategories.where((cat) => cat.isEnabled).toList();
  }

  /// Lấy danh sách categories chưa bật
  static List<AnimalCategory> getDisabledCategories() {
    return allCategories.where((cat) => !cat.isEnabled).toList();
  }
}

// ═══════════════════════════════════════════════════════════════
// Data model kết hợp category + count từ database
// ═══════════════════════════════════════════════════════════════
class AnimalCategoryData {
  final AnimalCategory category;
  final int count; // Số lượng THỰC TẾ từ database

  AnimalCategoryData({
    required this.category,
    required this.count,
  });

  /// Tính phần trăm hoàn thành
  double get completionPercentage {
    if (category.totalExpected == 0) return 0;
    return (count / category.totalExpected * 100).clamp(0, 100);
  }

  /// Format hiển thị: "75 giống" hoặc "100/10000 loài"
  String get displayText {
    if (count == 0) {
      return 'Sắp ra mắt';
    } else if (completionPercentage >= 80) {
      // Nếu đã có > 80% → chỉ hiện số hiện tại
      return '$count giống';
    } else {
      // Nếu < 80% → hiện "current/total"
      return '$count/${category.totalExpected} loài';
    }
  }

  /// Kiểm tra có data không
  bool get hasData => count > 0;
}