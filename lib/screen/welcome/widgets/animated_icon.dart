import 'package:flutter/material.dart';
import 'dart:math' as math;

class PulseAnimatedIcon extends StatefulWidget {
  final List<Color> gradientColors;
  final int pageIndex;

  const PulseAnimatedIcon({
    super.key,
    required this.gradientColors,
    this.pageIndex = 0,
  });

  @override
  State<PulseAnimatedIcon> createState() => _PulseAnimatedIconState();
}

class _PulseAnimatedIconState extends State<PulseAnimatedIcon>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _orbitController;
  late AnimationController _glowController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _orbitAnimation;
  late Animation<double> _glowAnimation;

  // Cấu hình icon và vệ tinh theo từng trang
  final List<Map<String, dynamic>> _iconConfigs = [
    {
      // Trang 0: Nước
      'main': '🦈', // Cá mập
      'satellites': ['🦁', '🦉'], // Sư tử, Cú
    },
    {
      // Trang 1: Đất
      'main': '🦁', // Sư tử
      'satellites': ['🦈', '🦉'], // Cá mập, Cú
    },
    {
      // Trang 2: Trời
      'main': '🦉', // Cú mèo
      'satellites': ['🦁', '🦈'], // Sư tử, Cá mập
    },
    {
      // Trang 3: App / Kết thúc
      'main': '🐾', // Icon App (Dấu chân đại diện)
      'satellites': ['🦈', '🦁', '🦉'], // 3 vệ tinh
    },
  ];

  @override
  void initState() {
    super.initState();

    // 1. Nhịp tim (Pulse)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 2. Xoay vòng (Orbit)
    _orbitController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _orbitAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_orbitController);

    // 3. Phát sáng (Glow)
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _orbitController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lấy cấu hình dựa trên pageIndex (dùng toán tử % để an toàn)
    final config = _iconConfigs[widget.pageIndex % _iconConfigs.length];
    final String mainIcon = config['main'];
    final List<String> satellites = config['satellites'];

    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController,
        _orbitController,
        _glowController,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: SizedBox(
            width: 260,
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Lớp 1: vòng sáng lan tỏa
                ...List.generate(3, (index) {
                  return Transform.scale(
                    scale: 1.0 + (index * 0.25) * _glowAnimation.value,
                    child: Container(
                      width: 140 + (index * 20),
                      height: 140 + (index * 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.gradientColors[0].withOpacity(
                            (0.3 - (index * 0.1)) * _glowAnimation.value,
                          ),
                          width: 1.5,
                        ),
                      ),
                    ),
                  );
                }),

                // Lớp 2: quỹ đạo mờ
                Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                      style: BorderStyle.solid,
                    ),
                  ),
                ),

                // LỚP 3: VỆ TINH XOAY QUANH (Dynamic)
                ...List.generate(satellites.length, (index) {
                  // Tự động chia đều góc dựa trên số lượng vệ tinh
                  // Nếu 2 con -> cách nhau 180 độ
                  // Nếu 3 con -> cách nhau 120 độ
                  final double angleStep = (2 * math.pi) / satellites.length;
                  final double currentAngle =
                      _orbitAnimation.value + (index * angleStep);

                  final radius = 105.0; // Bán kính quỹ đạo

                  return Transform.translate(
                    offset: Offset(
                      math.cos(currentAngle) * radius,
                      math.sin(currentAngle) * radius,
                    ),
                    // Xoay ngược vệ tinh để luôn đứng thẳng
                    child: Transform.rotate(
                      angle: -_orbitAnimation.value,
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: widget.gradientColors[1].withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            satellites[index],
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                // Lớp 4: icon chính (main)
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.gradientColors,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.gradientColors[0].withOpacity(
                          0.6 * _glowAnimation.value,
                        ),
                        blurRadius: 30,
                        spreadRadius: 5,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      mainIcon,
                      style: const TextStyle(fontSize: 65, height: 1.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
