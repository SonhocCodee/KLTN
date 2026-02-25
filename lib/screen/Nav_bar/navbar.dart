// lib/navbar/ios_navbar.dart
import 'package:flutter/cupertino.dart';
import 'package:cupertino_native/cupertino_native.dart';

class NavBarIOS extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const NavBarIOS({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Danh sách tab cho app nhận diện
    final List<CNTabBarItem> items = const [
      CNTabBarItem(label: 'Trang chủ', icon: CNSymbol('house.fill')),
      CNTabBarItem(label: 'Tìm kiếm', icon: CNSymbol('magnifyingglass')),
      CNTabBarItem(label: 'Nhận diện', icon: CNSymbol('camera.viewfinder')),
      CNTabBarItem(label: 'Khám phá', icon: CNSymbol('safari.fill')),
      CNTabBarItem(label: 'Cài đặt', icon: CNSymbol('gearshape.fill')),
    ];

    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: CNTabBar(
          items: items,
          currentIndex: currentIndex,
          tint: const Color(0xFF34D399), // Trả lại màu xanh chủ đạo
          height: 90,
          onTap: onTap,
        ),
      ),
    );
  }
}