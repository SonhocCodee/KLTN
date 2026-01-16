import 'dart:math';
import 'package:flutter/material.dart';

class EcosystemBackground extends StatelessWidget {
  final List<Color> colors;
  final AnimationController controller;
  final int pageIndex; // 0: dưới nước, 1: đất/cỏ, 2: bầu trời

  const EcosystemBackground({
    super.key,
    required this.colors,
    required this.controller,
    this.pageIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: EcosystemPainter(
            progress: controller.value,
            pageIndex: pageIndex,
          ),
          child: Container(),
        );
      },
    );
  }
}

class EcosystemPainter extends CustomPainter {
  final double progress;
  final int pageIndex;

  EcosystemPainter({
    required this.progress,
    required this.pageIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pageIndex == 0) {
      _drawUnderwater(canvas, size);
    } else if (pageIndex == 1) {
      _drawLand(canvas, size);
    } else if (pageIndex == 2) {
      _drawSky(canvas, size);
    }
  }

  // Trang 0: Dưới nước
  void _drawUnderwater(Canvas canvas, Size size) {
    // Nền nước xanh gradient từ sáng đến tối
    final waterGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF4FC3F7), // Xanh sáng (gần mặt nước)
          Color(0xFF0288D1), // Xanh đậm
          Color(0xFF01579B), // Xanh rất đậm (đáy biển)
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), waterGradient);

    // Vẽ ánh sáng lấp lánh từ trên xuống
    _drawSunrays(canvas, size);

    // Vẽ bong bóng khí
    _drawBubbles(canvas, size);

    // Vẽ rong biển
    _drawSeaweed(canvas, size);
  }

  // Trang 1: Đất và cỏ
  void _drawLand(Canvas canvas, Size size) {
    // Bầu trời nhạt phía trên
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE3F2FD), // Xanh da trời nhạt
          Color(0xFFBBDEFB),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.5));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.5), skyPaint);

    // Lớp đất
    final landPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF4CAF50), // Nâu đất
          Color(0xFF4CAF50), // Nâu đậm
        ],
      ).createShader(Rect.fromLTWH(0, size.height * 0.5, size.width, size.height * 0.5));

    final landPath = Path();
    landPath.moveTo(0, size.height * 0.5);

    // Tạo đường gợn sóng cho đất
    for (double i = 0; i <= size.width; i++) {
      final y = size.height * 0.5 + sin((i / size.width * 4) + (progress * 2 * pi)) * 15;
      landPath.lineTo(i, y);
    }

    landPath.lineTo(size.width, size.height);
    landPath.lineTo(0, size.height);
    landPath.close();

    canvas.drawPath(landPath, landPaint);

    // Lớp cỏ xanh
    final grassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF81C784), // Xanh lá sáng
          Color(0xFF66BB6A),
          Color(0xFF4CAF50), // Xanh lá đậm
        ],
      ).createShader(Rect.fromLTWH(0, size.height * 0.45, size.width, size.height * 0.15));

    final grassPath = Path();
    grassPath.moveTo(0, size.height * 0.5);

    for (double i = 0; i <= size.width; i++) {
      final y = size.height * 0.5 + sin((i / size.width * 6) + (progress * 3 * pi)) * 12;
      grassPath.lineTo(i, y);
    }

    grassPath.lineTo(size.width, size.height * 0.6);
    grassPath.lineTo(0, size.height * 0.6);
    grassPath.close();

    canvas.drawPath(grassPath, grassPaint);

    // Vẽ cọng cỏ chi tiết
    _drawGrassBlades(canvas, size);

    // Vẽ hoa nhỏ
    _drawFlowers(canvas, size);
  }

  // Trang 2: Bầu trời
  void _drawSky(Canvas canvas, Size size) {
    // Gradient bầu trời từ xanh đậm đến sáng
    final skyGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1976D2), // Xanh đậm
          Color(0xFF42A5F5), // Xanh sáng
          Color(0xFF90CAF9), // Xanh nhạt
          Color(0xFFE3F2FD), // Gần trắng (chân trời)
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyGradient);

    // Vẽ mặt trời
    _drawSun(canvas, size);

    // Vẽ mây
    _drawClouds(canvas, size);

    // Vẽ chim bay xa (silhouette)
    _drawBirdSilhouettes(canvas, size);
  }

  // === HIỆU ỨNG DƯỚI NƯỚC ===

  void _drawSunrays(Canvas canvas, Size size) {
    final rayPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final path = Path();
      final startX = size.width * (0.2 + i * 0.15);

      path.moveTo(startX, 0);
      path.lineTo(startX - 30 + sin(progress * 2 * pi) * 10, size.height);
      path.lineTo(startX + 30 + cos(progress * 2 * pi) * 10, size.height);
      path.close();

      canvas.drawPath(path, rayPaint);
    }
  }

  void _drawBubbles(Canvas canvas, Size size) {
    final bubblePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 15; i++) {
      final x = (size.width * (i / 15) + progress * 50) % size.width;
      final y = size.height - ((progress * size.height + i * 50) % size.height);
      final radius = 3 + (i % 3) * 2.0;

      canvas.drawCircle(Offset(x, y), radius, bubblePaint);
    }
  }

  void _drawSeaweed(Canvas canvas, Size size) {
    final seaweedPaint = Paint()
      ..color = Color(0xFF2E7D32).withOpacity(0.6)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final x = size.width * (i / 8);
      final path = Path();
      path.moveTo(x, size.height);

      for (double j = 0; j < size.height * 0.4; j += 10) {
        final offsetX = sin((j / 20) + (progress * 2 * pi) + i) * 15;
        path.lineTo(x + offsetX, size.height - j);
      }

      canvas.drawPath(path, seaweedPaint);
    }
  }

  // === HIỆU ỨNG ĐẤT/CỎ ===

  void _drawGrassBlades(Canvas canvas, Size size) {
    final grassPaint = Paint()
      ..color = Color(0xFF2E7D32).withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 40; i++) {
      final x = size.width * (i / 40);
      final baseY = size.height * 0.5;
      final height = 20 + (i % 3) * 10;

      final path = Path();
      path.moveTo(x, baseY);
      path.quadraticBezierTo(
        x + sin(progress * 2 * pi + i) * 5,
        baseY - height / 2,
        x + sin(progress * 2 * pi + i) * 9,
        baseY - height,
      );

      canvas.drawPath(path, grassPaint);
    }
  }

  void _drawFlowers(Canvas canvas, Size size) {
    final flowerColors = [
      Color(0xFFE91E63), // Hồng
      Color(0xFFFFC107), // Vàng
      Color(0xFF9C27B0), // Tím
    ];

    for (int i = 0; i < 10; i++) {
      final x = size.width * (i / 10) + 20;
      final y = size.height * 0.48 + sin(i + progress * 2 * pi) * 5;

      final flowerPaint = Paint()
        ..color = flowerColors[i % 3]
        ..style = PaintingStyle.fill;

      // Cánh hoa (5 cánh)
      for (int j = 0; j < 5; j++) {
        final angle = (j / 5) * 2 * pi + progress;
        final petalX = x + cos(angle) * 3;
        final petalY = y + sin(angle) * 3;
        canvas.drawCircle(Offset(petalX, petalY), 2.5, flowerPaint);
      }

      // Nhụy hoa
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = Color(0xFFFFC107));
    }
  }

  // === HIỆU ỨNG BẦU TRỜI ===

  void _drawSun(Canvas canvas, Size size) {
    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color(0xFFFFF59D),
          Color(0xFFFFF176),
          Color(0xFFFFEE58).withOpacity(0.0),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.8, size.height * 0.2),
        radius: 60,
      ));

    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 60, sunPaint);

    // Vẽ core mặt trời
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      40,
      Paint()..color = Color(0xFFFDD835),
    );
  }

  void _drawClouds(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // Mây 1
    final cloud1X = (size.width * 0.2 + progress * 30) % (size.width + 100);
    _drawCloud(canvas, Offset(cloud1X, size.height * 0.25), 1.0, cloudPaint);

    // Mây 2
    final cloud2X = (size.width * 0.5 + progress * 20) % (size.width + 100);
    _drawCloud(canvas, Offset(cloud2X, size.height * 0.15), 1.2, cloudPaint);

    // Mây 3
    final cloud3X = (size.width * 0.7 - progress * 25) % (size.width + 100);
    _drawCloud(canvas, Offset(cloud3X, size.height * 0.35), 0.9, cloudPaint);
  }

  void _drawCloud(Canvas canvas, Offset position, double scale, Paint paint) {
    canvas.drawCircle(position, 25 * scale, paint);
    canvas.drawCircle(Offset(position.dx + 20 * scale, position.dy), 30 * scale, paint);
    canvas.drawCircle(Offset(position.dx + 45 * scale, position.dy), 25 * scale, paint);
    canvas.drawCircle(Offset(position.dx + 30 * scale, position.dy - 15 * scale), 20 * scale, paint);
  }

  void _drawBirdSilhouettes(Canvas canvas, Size size) {
    final birdPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 5; i++) {
      final x = (size.width * (0.1 + i * 0.15) + progress * 40 + i * 20) % (size.width + 50);
      final y = size.height * 0.3 + sin(progress * 2 * pi + i) * 30;

      final path = Path();
      // Cánh trái
      path.moveTo(x - 10, y);
      path.quadraticBezierTo(x - 15, y - 8, x - 20, y - 5);
      path.moveTo(x, y);
      // Cánh phải
      path.quadraticBezierTo(x + 15, y - 8, x + 20, y - 5);

      canvas.drawPath(path, birdPaint);
    }
  }

  @override
  bool shouldRepaint(EcosystemPainter oldDelegate) => true;
}