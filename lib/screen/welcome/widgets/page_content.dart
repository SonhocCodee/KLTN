import 'package:flutter/material.dart';
import 'package:kltn_app/screen/welcome/widgets/animated_icon.dart';

import 'dart:math' as math;

import '../welcome_screen.dart';
import 'onboarding_page.dart';

/// Widget hiển thị nội dung chính của một trang onboarding
///
/// Bao gồm 3 phần chính:
/// 1. Icon động với animation xoay và scale
/// 2. Title + Subtitle với gradient text và fade in
/// 3. Description trong container bo tròn với glass effect
///
/// Tất cả đều có animation riêng khi trang được hiển thị
class PageContent extends StatelessWidget {
  /// Dữ liệu của trang (title, description, colors, etc.)
  final OnboardingPage page;

  /// Chỉ số trang (để truyền cho PulseAnimatedIcon)
  final int index;

  const PageContent({
    super.key,
    required this.page,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ===== PHẦN 1: ICON ĐỘNG =====
          _buildAnimatedIcon(),

          const SizedBox(height: 48),

          // ===== PHẦN 2: TITLE VÀ SUBTITLE =====
          _buildTitleSection(),

          const SizedBox(height: 24),

          // ===== PHẦN 3: DESCRIPTION =====
          _buildDescriptionBox(),
        ],
      ),
    );
  }

  /// Build icon với animation xoay và phóng to
  ///
  /// Animation:
  /// - Scale từ 0 -> 1 (hiệu ứng phóng to)
  /// - Rotate 4 vòng trong quá trình phóng to
  /// - ElasticOut curve tạo hiệu ứng nảy đàn hồi
  Widget _buildAnimatedIcon() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 100),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut, // Đường cong nảy đàn hồi
      builder: (context, value, child) {
        return Transform.scale(
          scale: value, // Phóng to từ 0 -> 1
          child: Transform.rotate(
            // Xoay 4 vòng (4 * π) trong quá trình phóng to
            angle: (1 - value) * math.pi * 4,
            child: child,
          ),
        );
      },
      child: PulseAnimatedIcon(
        pageIndex: index,
        gradientColors: page.gradientColors,
      ),
    );
  }

  /// Build phần title và subtitle
  ///
  /// Title:
  /// - ShaderMask để tạo gradient text
  /// - Font size lớn (36), bold (w900)
  /// - Shadow để tạo chiều sâu
  ///
  /// Subtitle:
  /// - Font nhỏ hơn (14), mỏng hơn
  /// - Màu đen mờ, letter spacing rộng
  /// - Fade in sau title
  Widget _buildTitleSection() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            // Trượt từ dưới lên (offset Y giảm dần)
            offset: Offset(0, 80 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          // Title với gradient
          ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: [
                  page.gradientColors[0], // Màu đầu
                  page.gradientColors[1], // Màu giữa
                  page.gradientColors[0], // Màu cuối (lặp lại để tạo hiệu ứng)
                ],
                stops: const [0.0, 0.5, 1.0], // Vị trí các màu
              ).createShader(bounds);
            },
            child: Text(
              page.title,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white, // ShaderMask sẽ override màu này
                letterSpacing: -0.5, // Chữ khít nhau hơn một chút
                shadows: [
                  Shadow(
                    offset: Offset(0, 2),
                    blurRadius: 8,
                    color: Colors.black45,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle với fade in riêng
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: child,
              );
            },
            child: Text(
              page.subtitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.5),
                letterSpacing: 1.5, // Chữ giãn rộng
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Build phần mô tả trong container bo tròn
  ///
  /// Glass morphism effect:
  /// - Background trắng mờ (opacity 0.35)
  /// - Border trắng nhạt
  /// - Shadow mềm phía dưới
  /// - Bo góc tròn 36px
  ///
  /// Animation:
  /// - Fade in + slide up giống title
  Widget _buildDescriptionBox() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 80 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // Glass effect: trắng mờ
          color: Colors.white.withOpacity(0.35),
          borderRadius: BorderRadius.circular(36),

          // Border nhẹ
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),

          // Shadow mềm
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10), // Shadow phía dưới
            ),
          ],
        ),
        child: Text(
          page.description,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black.withOpacity(0.5),
            height: 1.6, // Line height cho dễ đọc
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}