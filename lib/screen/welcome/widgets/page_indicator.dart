import 'package:flutter/material.dart';

// Đây là Widget hiển thị thanh chỉ dẫn (mấy cái chấm tròn/dài ở dưới slide)
class PageIndicator extends StatelessWidget {
  // Biến để biết trang hiện tại là số mấy (0, 1, 2...)
  final int currentPage;

  // Tổng số lượng trang
  final int pageCount;

  // Danh sách màu để làm hiệu ứng chuyển màu (Gradient) cho chấm đang chọn
  final List<Color> gradientColors;

  // Hàm callback: Khi bấm vào chấm thì báo ngược lại cho cha biết
  // (Giống cái Remote void nãy mình nói, bấm là gửi lệnh đi)
  final Function(int) onDotTap;

  const PageIndicator({
    super.key,
    required this.currentPage,
    required this.pageCount,
    required this.gradientColors,
    required this.onDotTap,
  });

  @override
  Widget build(BuildContext context) {
    // Row: Xếp các chấm nằm ngang hàng
    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // Căn giữa màn hình

      // List.generate: Tạo ra một danh sách các Widget con dựa trên tổng số trang
      children: List.generate(pageCount, (index) {

        // Logic kiểm tra: Chấm này có phải là trang đang hiện không?
        final isActive = index == currentPage;

        // GestureDetector: Biến cái hộp vẽ (Container) thành nút bấm được
        return GestureDetector(
          onTap: () => onDotTap(index), // Khi bấm, gọi hàm onDotTap và gửi số thứ tự đi

          // AnimatedContainer: Giống Container thường nhưng tự động làm mượt khi thay đổi kích thước/màu sắc
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400), // Thời gian chạy hiệu ứng (0.4 giây)
            curve: Curves.easeInOutCubic, // Kiểu chuyển động (nhanh dần rồi chậm lại cho tự nhiên)

            margin: const EdgeInsets.symmetric(horizontal: 4), // Khoảng cách giữa các chấm

            // --- LOGIC QUAN TRỌNG: Thay đổi hình dáng ---
            // Nếu đang chọn (isActive) thì dài ra (40), nếu không thì ngắn (10)
            width: isActive ? 40 : 10,
            height: 10, // Chiều cao cố định

            decoration: BoxDecoration(
              // Nếu đang chọn: Dùng màu Gradient. Nếu không: Không có Gradient (null)
              gradient: isActive
                  ? LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: gradientColors,
              )
                  : null,

              // Nếu đang chọn: Màu nền đè bởi Gradient (null). Nếu không: Màu xám nhạt
              color: isActive ? null : const Color(0xFFCBD5E1),

              borderRadius: BorderRadius.circular(5), // Bo tròn góc

              // Tạo bóng đổ (Shadow) chỉ khi đang được chọn cho nổi bật
              boxShadow: isActive
                  ? [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.5), // Bóng mờ theo màu chính
                  blurRadius: 8, // Độ nhòe của bóng
                  offset: const Offset(0, 2), // Bóng đổ xuống dưới một chút
                ),
              ]
                  : null, // Không chọn thì không đổ bóng
            ),
          ),
        );
      }),
    );
  }
}