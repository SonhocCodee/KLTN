import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget tạo background động với gradient và các vòng tròn parallax
///
/// Chức năng:
/// - Gradient background thay đổi theo trang hiện tại
/// - 3 vòng tròn lớn với hiệu ứng blur chuyển động chậm
/// - Tạo cảm giác sâu và sinh động cho UI
///
/// Animation:
/// - Sử dụng AnimationController từ parent
/// - Các vòng tròn xoay với tốc độ khác nhau
/// - Không tự quản lý controller để tránh rebuild không cần thiết
class EcosystemBackground extends StatelessWidget {
  /// Màu gradient của background (2 màu)
  final List<Color> colors;

  /// Controller để điều khiển animation parallax
  /// Được truyền từ parent để đồng bộ với các animation khác
  final AnimationController controller;

  /// Chỉ số trang hiện tại (0: underwater, 1: land, 2: sky)
  /// Dùng để điều chỉnh vị trí và kích thước vòng tròn
  final int pageIndex;

  const EcosystemBackground({
    super.key,
    required this.colors,
    required this.controller,
    required this.pageIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Gradient làm nền chính
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),

      // AnimatedBuilder: rebuild khi controller thay đổi
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Stack(
            children: [
              // Vòng tròn 1 - Lớn nhất, chuyển động chậm nhất
              Positioned(
                // Vị trí động dựa trên animation
                top: -100 + math.sin(controller.value * 2 * math.pi) * 50,
                left: -150 + math.cos(controller.value * 2 * math.pi) * 30,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Màu trắng mờ với opacity thấp
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),

              // Vòng tròn 2 - Vừa, chuyển động vừa
              Positioned(
                // Xoay ngược chiều với vòng 1 (nhân với -1)
                bottom: -50 + math.sin(controller.value * 2 * math.pi * -1) * 40,
                right: -100 + math.cos(controller.value * 2 * math.pi * -1) * 25,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),

              // Vòng tròn 3 - Nhỏ nhất, chuyển động nhanh nhất
              Positioned(
                // Chuyển động nhanh gấp 1.5 lần (nhân với 1.5)
                top: MediaQuery.of(context).size.height * 0.4 +
                    math.sin(controller.value * 2 * math.pi * 1.5) * 30,
                right: 50 + math.cos(controller.value * 2 * math.pi * 1.5) * 20,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}