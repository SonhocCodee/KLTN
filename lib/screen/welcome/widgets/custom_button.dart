import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onPressed;

  const CustomButton({
    super.key,
    required this.text,
    required this.icon,
    required this.gradientColors,
    required this.onPressed,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    // Vẫn giữ animation lặp lại để nút có hiệu ứng "thở" nhẹ và lấp lánh
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Hiệu ứng thở nhẹ (tự động phình ra thu vào xíu xiu cho đẹp)
    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Hiệu ứng ánh sáng chạy qua
    _shimmerAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value, // Chỉ dùng scale tự động, không scale khi ấn
          child: GestureDetector(
            // QUAN TRỌNG: Dùng onTap để chạy logic ngay lập tức khi chạm vào
            onTap: widget.onPressed,

            child: Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: widget.gradientColors,
                ),
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradientColors[0].withOpacity(0.5),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Shimmer effect (Hiệu ứng lấp lánh giữ nguyên)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: Transform.translate(
                      offset: Offset(_shimmerAnimation.value * 200, 0),
                      child: Container(
                        width: 400,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Button content
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Icon tĩnh, không di chuyển khi ấn nữa
                        Icon(
                          widget.icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}