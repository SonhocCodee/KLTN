import 'package:flutter/material.dart';
import 'package:kltn_app/screen/welcome/widgets/animated_icon.dart';
import 'package:kltn_app/screen/welcome/widgets/custom_button.dart';
import 'package:kltn_app/screen/welcome/widgets/floating_emoji.dart';
import 'package:kltn_app/screen/welcome/widgets/liquid_pb.dart';
import 'package:kltn_app/screen/welcome/widgets/onboarding_page.dart';
import 'package:kltn_app/screen/welcome/widgets/page_indicator.dart';
import 'dart:math' as math;
import 'package:kltn_app/screen/welcome/widgets/particle_system.dart';

import 'package:kltn_app/screen/welcome/widgets/page_content.dart';

import '../Auth/auth_screen.dart';
import '../home/home_wrapper.dart';

// Màn hình chào mừng (Welcome/Onboarding Screen)
// Hiển thị 4 trang giới thiệu về ứng dụng với animations và hiệu ứng đẹp mắt
// Chức năng chính:
// Cho phép người dùng vuốt qua 4 trang giới thiệu
// Mỗi trang có theme riêng (Underwater, Land, Sky, Ready)
// Có nút "Tiếp theo", "Bỏ qua" và thanh chỉ báo trang
// Hiệu ứng particles, floating animals, gradient backgrounds
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  // Controller

  // Controller để điều khiển PageView (vuốt trang)
  final PageController _pageController = PageController();

  // Chỉ số trang hiện tại (0-3)
  int _currentPage = 0;

  // Controller cho animation chuyển trang
  // Duration: 800ms - tốc độ vừa phải, mượt mà
  late AnimationController _pageTransitionController;

  // Controller cho hiệu ứng parallax background
  // Duration: 20s - chuyển động chậm, tạo cảm giác sâu
  // repeat() - lặp vô hạn
  late AnimationController _parallaxController;

  // Dữ liệu

  // Danh sách 4 trang onboarding
  // Mỗi trang có: icon, title, subtitle, description, màu gradient, màu particles
  final List<OnboardingPage> _pages = [
    // Trang 1: Thế giới dưới nước
    OnboardingPage(
      icon: Icons.water_drop_rounded,
      title: 'Thế Giới Dưới Nước',
      subtitle: 'Underwater World',
      description:
          'Khám phá đại dương kỳ diệu với những sinh vật biển đầy màu sắc và bí ẩn',
      gradientColors: [
        Color(0xFF0288D1),
        Color(0xFF4FC3F7),
      ], // Xanh dương đậm -> nhạt
      particleColor: Color(0xFF4FC3F7),
    ),

    // Trang 2: Vương quốc trên cạn
    OnboardingPage(
      icon: Icons.landscape_rounded,
      title: 'Vương Quốc Trên Cạn',
      subtitle: 'Land Kingdom',
      description:
          'Gặp gỡ những loài động vật hoang dã sống trên đồng cỏ và trong rừng xanh',
      gradientColors: [
        Color(0xFF66BB6A),
        Color(0xFF81C784),
      ], // Xanh lá đậm -> nhạt
      particleColor: Color(0xFF66BB6A),
    ),

    // Trang 3: Bầu trời tự do
    OnboardingPage(
      icon: Icons.cloud_rounded,
      title: 'Bầu Trời Tự Do',
      subtitle: 'Freedom Sky',
      description:
          'Chiêm ngưỡng những loài chim bay cao giữa bầu trời xanh thẳm',
      gradientColors: [
        Color(0xFF42A5F5),
        Color(0xFF90CAF9),
      ], // Xanh da trời đậm -> nhạt
      particleColor: Color(0xFF42A5F5),
    ),

    // Trang 4: Sẵn sàng khám phá
    OnboardingPage(
      icon: Icons.check_circle_rounded,
      title: 'Sẵn Sàng Khám Phá!',
      subtitle: 'Ready to Explore',
      description:
          'Hãy bắt đầu hành trình khám phá thế giới động vật đầy màu sắc của bạn ngay bây giờ',
      gradientColors: [Color(0xFFFBBF24), Color(0xFFF97316)], // Vàng -> cam
      particleColor: Color(0xFFFBBF24),
    ),
  ];

  // Vòng đời màn hình

  @override
  void initState() {
    super.initState();

    // Khởi tạo controller cho animation chuyển trang
    _pageTransitionController = AnimationController(
      duration: const Duration(milliseconds: 800), // Thời gian animation
      vsync: this, // TickerProvider để tối ưu hiệu suất
    )..forward(); // Chạy animation ngay khi khởi tạo

    // Khởi tạo controller cho parallax background
    _parallaxController = AnimationController(
      duration: const Duration(seconds: 20), // Chuyển động chậm rãi
      vsync: this,
    )..repeat(); // Lặp vô hạn để tạo hiệu ứng liên tục
  }

  @override
  void dispose() {
    // Giải phóng bộ nhớ khi widget bị destroy
    _pageController.dispose();
    _pageTransitionController.dispose();
    _parallaxController.dispose();
    super.dispose();
  }

  // Xử lý sự kiện

  // Callback khi người dùng vuốt sang trang khác
  // @param page - Chỉ số trang mới
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    // Reset và chạy lại animation để tạo hiệu ứng fade in
    _pageTransitionController.reset();
    _pageTransitionController.forward();
  }

  // Chuyển sang trang tiếp theo
  // Chỉ hoạt động nếu chưa đến trang cuối
  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 900), // Animation mượt mà
        curve: Curves.easeInOutCubic, // Đường cong tự nhiên
      );
    }
  }

  // Bỏ qua và nhảy thẳng đến trang cuối
  void _skipToEnd() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
    );
  }

  // Xử lý khi người dùng nhấn "Bắt đầu ngay"
  // Hiển thị SnackBar chào mừng
  void _getStarted() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const AuthScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  // Dựng giao diện

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Layer 1: Background động với gradient và parallax
          EcosystemBackground(
            colors: _pages[_currentPage].gradientColors,
            controller: _parallaxController,
            // Trang 4 sử dụng background của trang 3 (tránh tạo background mới)
            pageIndex: _currentPage >= 3 ? 2 : _currentPage,
          ),

          // Layer 2: Hệ thống hạt bay lượn
          ParticleSystem(
            color: _pages[_currentPage].particleColor,
            particleCount: 30, // Số lượng particles
          ),

          // Layer 3: Nội dung chính
          SafeArea(
            child: Stack(
              children: [
                // Khu nội dung chính
                Positioned.fill(
                  child: Stack(
                    children: [
                      // Hiển thị động vật bay lượn (chỉ ở 3 trang đầu)
                      // Trang 4 không có floating animals
                      if (_currentPage < 3)
                        FloatingAnimals(pageIndex: _currentPage),

                      // PageView - cho phép vuốt trái/phải
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        itemCount: _pages.length,
                        itemBuilder: (context, index) {
                          // Sử dụng widget riêng để build nội dung trang
                          return PageContent(page: _pages[index], index: index);
                        },
                      ),
                    ],
                  ),
                ),

                // Khu nút dưới
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // AnimatedSwitcher - tự động tạo hiệu ứng khi child thay đổi
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            switchInCurve: Curves.easeOut, // Nút mới xuất hiện
                            switchOutCurve: Curves.easeIn, // Nút cũ biến mất
                            // Định nghĩa cách animation chạy
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(
                                        0,
                                        2,
                                      ), // Bắt đầu từ dưới xa
                                      end: Offset
                                          .zero, // Kết thúc tại vị trí gốc
                                    ).animate(animation),
                                    child: child,
                                  );
                                },

                            // Nút action chính
                            child: CustomButton(
                              // KEY QUAN TRỌNG: Khi key thay đổi, AnimatedSwitcher
                              // sẽ hiểu là widget mới và chạy animation
                              key: ValueKey<int>(_currentPage),

                              // Text và icon thay đổi ở trang cuối
                              text: _currentPage == _pages.length - 1
                                  ? 'Bắt đầu Ngay'
                                  : 'Tiếp Theo',
                              icon: _currentPage == _pages.length - 1
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              gradientColors:
                                  _pages[_currentPage].gradientColors,

                              // Callback khác nhau cho trang cuối
                              onPressed: _currentPage == _pages.length - 1
                                  ? _getStarted
                                  : _nextPage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Chấm trạng thái phía trên
                // Thanh chỉ báo trang (dots)
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: PageIndicator(
                      currentPage: _currentPage,
                      pageCount: _pages.length,
                      gradientColors: _pages[_currentPage].gradientColors,

                      // Cho phép tap vào dot để nhảy đến trang đó
                      onDotTap: (index) {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOutCubic,
                        );
                      },
                    ),
                  ),
                ),

                // Nút bỏ qua
                // Chỉ hiện nút "Bỏ qua" khi chưa đến trang cuối
                if (_currentPage < _pages.length - 1)
                  SlideTransition(
                    // Animation trượt từ phải vào
                    position:
                        Tween<Offset>(
                          begin: const Offset(
                            1,
                            0,
                          ), // Bắt đầu từ bên phải ngoài màn hình
                          end: Offset.zero, // Kết thúc tại vị trí gốc
                        ).animate(
                          CurvedAnimation(
                            parent: _pageTransitionController,
                            curve: Curves.easeOut,
                          ),
                        ),
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          margin: const EdgeInsets.only(top: 10, right: 10),

                          // Gradient background cho nút
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _pages[_currentPage].gradientColors,
                            ),
                          ),

                          // Material + InkWell để tạo ripple effect khi tap
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _skipToEnd,
                              borderRadius: BorderRadius.circular(20),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                child: Text(
                                  'Bỏ qua',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
