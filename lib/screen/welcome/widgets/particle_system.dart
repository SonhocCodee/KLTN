import 'dart:math';
import 'package:flutter/material.dart';

class ParticleSystem extends StatefulWidget {
  final Color color;
  final int particleCount;

  const ParticleSystem({
    super.key,
    required this.color,
    this.particleCount = 20, // Giảm số lượng chút vì dấu chân to hơn bụi
  });

  @override
  State<ParticleSystem> createState() => _ParticleSystemState();
}

class _ParticleSystemState extends State<ParticleSystem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20), // Bay chậm lại cho chill
      vsync: this,
    )..repeat();

    _initParticles();
  }

  void _initParticles() {
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(
        Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          // Kích thước ngẫu nhiên
          size: 4 + _random.nextDouble() * 6,
          // Bay xiên xiên nhẹ nhàng
          speedX: (_random.nextDouble() - 0.5) * 0.01,
          // Bay từ dưới lên
          speedY: -_random.nextDouble() * 0.005,
          // Góc xoay ngẫu nhiên cho tự nhiên
          rotation: _random.nextDouble() * 2 * pi,
          opacity: 0.1 + _random.nextDouble() * 0.3,
        ),
      );
    }
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
        return CustomPaint(
          painter: PawPrintPainter(particles: _particles, color: widget.color),
          child: Container(),
        );
      },
    );
  }
}

class Particle {
  double x;
  double y;
  final double size;
  final double speedX;
  final double speedY;
  final double rotation;
  final double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.rotation,
    required this.opacity,
  });

  void update() {
    x += speedX;
    y += speedY;

    // Cơ chế lặp lại vô tận
    if (y < -0.1) {
      y = 1.1;
      x = Random().nextDouble();
    }
    if (x < -0.1) x = 1.1;
    if (x > 1.1) x = -0.1;
  }
}

// Họa sĩ vẽ dấu chân thú
class PawPrintPainter extends CustomPainter {
  final List<Particle> particles;
  final Color color;

  PawPrintPainter({required this.particles, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update();

      final paint = Paint()
        ..color = color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      // Lưu trạng thái Canvas hiện tại
      canvas.save();

      // 1. Di chuyển bút đến vị trí hạt
      final centerX = particle.x * size.width;
      final centerY = particle.y * size.height;
      canvas.translate(centerX, centerY);

      // 2. Xoay Canvas theo góc của hạt (để dấu chân xoay lung tung)
      canvas.rotate(particle.rotation);

      // 3. Vẽ Dấu Chân (Gồm 1 đệm to + 3 ngón nhỏ)
      double r = particle.size;

      // Đệm thịt chính (Hình tròn to ở dưới)
      // Vẽ hơi dẹt một chút (Oval) cho giống thật
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(0, 0),
          width: r * 2.2,
          height: r * 1.8,
        ),
        paint,
      );

      // 3 Ngón chân (3 hình tròn nhỏ ở trên)
      double toeSize = r * 0.7; // Kích thước ngón
      double toeDist = r * 1.4; // Khoảng cách từ tâm đệm lên ngón

      // Ngón trái
      canvas.drawCircle(Offset(-toeDist * 0.8, -toeDist), toeSize, paint);
      // Ngón giữa (cao hơn chút)
      canvas.drawCircle(Offset(0, -toeDist * 1.2), toeSize, paint);
      // Ngón phải
      canvas.drawCircle(Offset(toeDist * 0.8, -toeDist), toeSize, paint);

      // Khôi phục Canvas để vẽ hạt tiếp theo
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(PawPrintPainter oldDelegate) => true;
}
