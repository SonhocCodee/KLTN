import 'dart:math';
import 'package:flutter/material.dart';

// Widget hiển thị các động vật trôi nổi/bay lượn làm nền (Background Animation).
// Thay đổi loại động vật và kiểu chuyển động dựa trên [pageIndex].
class FloatingAnimals extends StatefulWidget {
  // Index xác định môi trường:
  // 0: Dưới nước (Cá bơi)
  // 1: Trên cạn (Thú đi/nhảy)
  // 2: Bầu trời (Chim bay)
  final int pageIndex;

  const FloatingAnimals({super.key, required this.pageIndex});

  @override
  State<FloatingAnimals> createState() => _FloatingAnimalsState();
}

class _FloatingAnimalsState extends State<FloatingAnimals>
    with SingleTickerProviderStateMixin {
  // Controller điều khiển hoạt ảnh chạy liên tục (loop)
  late AnimationController _controller;

  // Đối tượng Random để sinh vị trí/tốc độ ngẫu nhiên
  final Random _random = Random();

  // Danh sách chứa thông số của từng con vật đang hiển thị
  late List<AnimalIcon> _animals;

  @override
  void initState() {
    super.initState();
    // Khởi tạo animation chạy vô tận trong 20 giây cho 1 chu kỳ
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(); // repeat() giúp animation chạy lặp lại liên tục

    // Sinh danh sách động vật lần đầu
    _generateAnimals();
  }

  @override
  void didUpdateWidget(FloatingAnimals oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nếu chuyển trang (thay đổi môi trường), sinh lại danh sách động vật mới
    if (oldWidget.pageIndex != widget.pageIndex) {
      _generateAnimals();
    }
  }

  // Hàm tạo danh sách ngẫu nhiên các động vật và thông số chuyển động của chúng
  void _generateAnimals() {
    List<String> icons;

    // 1. Chọn bộ icon dựa trên môi trường (pageIndex)
    switch (widget.pageIndex) {
      case 0: // Môi trường nước
        icons = [
          '🐟',
          '🐠',
          '🐡',
          '🦈',
          '🐙',
          '🦑',
          '🐚',
          '🦀',
          '🐋',
          '🐬',
          '🦐',
          '🐢',
        ];
        break;
      case 1: // Môi trường đất liền
        icons = [
          '🦁',
          '🐯',
          '🐘',
          '🦒',
          '🦓',
          '🐆',
          '🦌',
          '🐎',
          '🐂',
          '🐃',
          '🐄',
          '🦘',
        ];
        break;
      case 2: // Môi trường bầu trời
        icons = [
          '🦅',
          '🦆',
          '🦉',
          '🦜',
          '🕊️',
          '🦚',
          '🐦',
          '🦩',
          '🦢',
          '🦅',
          '🦇',
          '🐔',
        ];
        break;
      default:
        icons = ['🐾'];
    }

    // 2. Tạo 10 đối tượng AnimalIcon với thông số ngẫu nhiên
    _animals = List.generate(10, (index) {
      return AnimalIcon(
        icon: icons[_random.nextInt(icons.length)],
        startX: _random.nextDouble(), // Vị trí bắt đầu ngang (0.0 -> 1.0)
        startY:
            _random.nextDouble() * 0.7 +
            0.15, // Vị trí dọc: Giới hạn từ 15% đến 85% chiều cao màn hình
        speed: _random.nextDouble() * 0.4 + 0.3, // Tốc độ di chuyển
        size: _random.nextDouble() * 25 + 35, // Kích thước: 35 -> 60
        amplitude: _random.nextDouble() * 60 + 40, // Biên độ dao động (sóng)
        phase:
            _random.nextDouble() *
            2 *
            pi, // Pha dao động (để các con vật không chuyển động đồng bộ)
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lấy kích thước màn hình để tính toán vị trí tuyệt đối
    final screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: _animals.map((animal) {
            // Giá trị từ 0.0 đến 1.0 đại diện cho tiến trình animation
            final progress = _controller.value;

            double x, y;
            double rotation = 0; // Góc xoay mặc định

            // Logic tính toán vị trí theo môi trường

            if (widget.pageIndex == 0) {
              // Case 0: dưới nước
              // Chuyển động: Bơi ngang + Lên xuống nhẹ nhàng (Sóng Sine)

              // X: Di chuyển từ trái qua phải, lặp lại khi vượt quá màn hình
              // (modulo 1.2 - 0.1 để vật thể đi hẳn ra ngoài màn hình mới quay lại)
              x =
                  ((animal.startX + progress * animal.speed * 0.5) % 1.2 -
                      0.1) *
                  screenSize.width;

              // Y: Vị trí gốc + Dao động Sine
              y =
                  screenSize.height * animal.startY +
                  sin(progress * 2 * pi + animal.phase) * animal.amplitude;

              // Rotation: Lắc lư nhẹ theo nhịp bơi
              rotation = sin(progress * 2 * pi + animal.phase) * 0.2;
            } else if (widget.pageIndex == 1) {
              // Case 1: đất liền
              // Chuyển động: Đi ngang + Nhảy tưng tưng

              // X: Di chuyển ngang chậm hơn dưới nước (hệ số 0.3)
              x =
                  ((animal.startX + progress * animal.speed * 0.3) % 1.2 -
                      0.1) *
                  screenSize.width;

              // Y: Tạo hiệu ứng nhảy bằng cách chỉ lấy phần dương của hàm Sine
              final jumpValue = sin(progress * 4 * pi + animal.phase);
              y =
                  screenSize.height * animal.startY -
                  (jumpValue > 0 ? jumpValue * animal.amplitude * 0.4 : 0);

              // Rotation: 0 (Động vật trên cạn thường giữ thăng bằng, không xoay)
            } else {
              // Case 2: bầu trời
              // Chuyển động: Bay lượn tự do theo đường cong phức tạp (Sin + Cos)

              // X: Bay nhanh nhất (hệ số 0.6)
              x =
                  ((animal.startX + progress * animal.speed * 0.6) % 1.2 -
                      0.1) *
                  screenSize.width;

              // Y: Kết hợp Sin và Cos để tạo đường bay lượn sóng tự nhiên hơn
              y =
                  screenSize.height * animal.startY +
                  sin(progress * 2 * pi + animal.phase) *
                      animal.amplitude *
                      0.8 +
                  cos(progress * 3 * pi + animal.phase) * 30;

              // Rotation: Nghiêng người theo hướng bay
              rotation = sin(progress * 2 * pi + animal.phase) * 0.3;
            }

            // Render widget
            return Positioned(
              left: x,
              top: y,
              child: Transform.rotate(
                angle: rotation,
                child: Transform.scale(
                  // Hiệu ứng "Thở": Phồng lên xẹp xuống nhẹ
                  scale: 1 + sin(progress * 4 * pi + animal.phase) * 0.15,
                  child: Opacity(
                    // Hiệu ứng Mờ ảo: Độ trong suốt thay đổi theo thời gian
                    opacity: 0.7 + sin(progress * 3 * pi + animal.phase) * 0.2,
                    child: Text(
                      animal.icon,
                      style: TextStyle(
                        fontSize: animal.size,
                        // Đổ bóng nhẹ để tách biệt khỏi nền
                        shadows: [
                          Shadow(
                            blurRadius: 8,
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// Class model lưu trữ thông số riêng biệt cho từng con vật
class AnimalIcon {
  final String icon; // Emoji con vật
  final double startX; // Vị trí X ban đầu (tỉ lệ 0-1)
  final double startY; // Vị trí Y ban đầu (tỉ lệ 0-1)
  final double speed; // Tốc độ di chuyển
  final double size; // Kích thước font chữ
  final double amplitude; // Biên độ dao động (độ cao sóng/nhảy)
  final double phase; // Pha dao động (độ lệch thời gian)

  AnimalIcon({
    required this.icon,
    required this.startX,
    required this.startY,
    required this.speed,
    required this.size,
    required this.amplitude,
    required this.phase,
  });
}
