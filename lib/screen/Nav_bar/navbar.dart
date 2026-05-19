// lib/navbar/ios_navbar.dart
import 'package:flutter/cupertino.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:provider/provider.dart';
import '../language/Locale_provider.dart'; // Đảm bảo đường dẫn này đúng

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
    final t = context.watch<LocaleProvider>();

    // Danh sách tab cho app nhận diện
    final List<CNTabBarItem> items = [
      CNTabBarItem(label: t.tr('Trang chủ'), icon: const CNSymbol('house.fill')),
      CNTabBarItem(label: t.tr('Khám phá'), icon: const CNSymbol('magnifyingglass')),
      CNTabBarItem(label: t.tr('Nhận diện'), icon: const CNSymbol('camera.viewfinder')),
      CNTabBarItem(label: t.tr('Tìm kiếm'), icon: const CNSymbol('safari.fill')),
      CNTabBarItem(label: t.tr('Cài đặt'), icon: const CNSymbol('gearshape.fill')),
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