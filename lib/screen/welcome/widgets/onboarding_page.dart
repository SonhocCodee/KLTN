import 'package:flutter/material.dart';

/// Model class đại diện cho một trang trong onboarding flow
///
/// Chứa tất cả thông tin cần thiết để hiển thị một trang:
/// - Icon đại diện cho chủ đề
/// - Tiêu đề (title) và phụ đề (subtitle)
/// - Mô tả chi tiết
/// - Màu sắc cho gradient và particles
///
/// Immutable class - tất cả properties là final
class OnboardingPage {
  /// Icon hiển thị ở giữa trang (ví dụ: water_drop, landscape, cloud)
  final IconData icon;

  /// Tiêu đề chính bằng tiếng Việt
  /// Ví dụ: "Thế Giới Dưới Nước"
  final String title;

  /// Phụ đề bằng tiếng Anh (nhỏ hơn, mờ hơn)
  /// Ví dụ: "Underwater World"
  final String subtitle;

  /// Mô tả chi tiết về nội dung trang
  /// Hiển thị trong một container bo tròn với background mờ
  final String description;

  /// Danh sách 2 màu cho gradient background
  /// [0] - Màu đậm hơn (thường ở trên/trái)
  /// [1] - Màu nhạt hơn (thường ở dưới/phải)
  final List<Color> gradientColors;

  /// Màu của các particles bay lượn
  /// Thường giống với gradientColors[1] để hài hòa
  final Color particleColor;

  /// Constructor với tất cả required parameters
  /// Không có giá trị mặc định vì mỗi trang cần thông tin riêng
  OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.gradientColors,
    required this.particleColor,
  });
}