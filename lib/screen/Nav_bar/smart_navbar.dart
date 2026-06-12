// lib/widgets/smart_nav_bar.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../language/Locale_provider.dart'; // Đảm bảo đường dẫn này đúng

class SmartNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final ScrollController scrollController;

  const SmartNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.scrollController,
  });

  @override
  State<SmartNavBar> createState() => _SmartNavBarState();
}

class _SmartNavBarState extends State<SmartNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _setupAnimations(widget.currentIndex.toDouble());
  }

  void _setupAnimations(double targetIndex) {
    _positionAnimation = Tween<double>(begin: targetIndex, end: targetIndex)
        .animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
        );
  }

  @override
  void didUpdateWidget(SmartNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      final beginPos = _positionAnimation.value;
      _positionAnimation =
          Tween<double>(
            begin: beginPos,
            end: widget.currentIndex.toDouble(),
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
          );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _calculateScale(double progress) {
    const double peakScale = 1.3;
    const double baseScale = 1.0;
    final double t = progress - 0.5;
    final double parabola = 1 - 4 * t * t;
    return baseScale + (peakScale - baseScale) * parabola;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LocaleProvider>();

    // Màu chung cho cả 2 mode
    final inactiveColor = isDark ? Colors.white70 : Colors.black87;
    final activeColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: EdgeInsets.only(bottom: 25.w, left: 8, right: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30.r),
        child: isDark
            ? _buildDarkMode(
                activeColor,
                inactiveColor,
                t,
              ) // Dark: code cũ bạn thích
            : _buildLightMode(
                activeColor,
                inactiveColor,
                t,
              ), // Light: code mới đẹp
      ),
    );
  }

  // Dark mode: dùng code cũ bạn thích (blur + mờ nhẹ)
  Widget _buildDarkMode(
    Color activeColor,
    Color inactiveColor,
    LocaleProvider t,
  ) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 65.h,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: _buildContent(activeColor, inactiveColor, t),
      ),
    );
  }

  // Light mode: dùng code mới đẹp (nền trắng mờ + bóng đổ)
  Widget _buildLightMode(
    Color activeColor,
    Color inactiveColor,
    LocaleProvider t,
  ) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 65.h,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: Colors.black.withOpacity(0.1), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _buildContent(activeColor, inactiveColor, t),
      ),
    );
  }

  // Nội dung chung cho cả 2 mode
  Widget _buildContent(
    Color activeColor,
    Color inactiveColor,
    LocaleProvider t,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / 5;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Hiệu ứng active
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final progress = _controller.value;
                final currentIndex = _positionAnimation.value;
                final targetX = (currentIndex - 2) * itemWidth;
                final scale = _calculateScale(progress);
                return Transform.translate(
                  offset: Offset(targetX, 0),
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.center,
                    child: Container(
                      width: 75.w,
                      height: 67.h,
                      margin: EdgeInsets.symmetric(vertical: 3.h),
                      decoration: BoxDecoration(
                        color: activeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                    ),
                  ),
                );
              },
            ),

            // 5 tab items
            Row(
              children: List.generate(5, (index) {
                return Expanded(
                  child: _buildItem(
                    _getIconPath(index),
                    _getLabel(index),
                    index,
                    activeColor,
                    inactiveColor,
                    t,
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildItem(
    String iconPath,
    String label,
    int index,
    Color active,
    Color inactive,
    LocaleProvider t,
  ) {
    final isActive = index == widget.currentIndex;
    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              width: isActive ? 30.w : 25.w,
              height: isActive ? 30.w : 25.w,
              color: isActive ? active : inactive,
            ),
            SizedBox(height: 2.h),
            Text(
              t.tr(label), // <-- Đã thêm gọi t.tr() để dịch
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isActive ? active : inactive,
                fontSize: 10.sp,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getIconPath(int index) {
    const icons = [
      'assets/icons/home_navbar.png',
      'assets/icons/compass_navbar.png',
      'assets/icons/camera_navbar.png',
      'assets/icons/search2.png',
      'assets/icons/Setting_navbar.png',
    ];
    return icons[index];
  }

  String _getLabel(int index) {
    const labels = [
      "Trang chủ",
      "Khám phá",
      "Nhận diện",
      "Tìm kiếm",
      "Cài đặt",
    ];
    return labels[index];
  }
}
