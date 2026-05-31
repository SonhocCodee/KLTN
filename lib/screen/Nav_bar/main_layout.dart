// lib/main_layout.dart
import 'package:flutter/material.dart';

import '../ExploreScreen/explore_page.dart';
import '../IDENTIFY SCREEN/indentify_screen.dart';
import '../Search_smart/search_smart_screen.dart';
import '../SettingsScreen/SettingsScreen.dart';
import '../home/home_screen.dart';
import 'navbar_selector.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    ExplorePage(),
    IdentifyScreen(),
    SmartQuizPage(),
    AnimalSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Kỹ thuật xịn: Nhận biết khi bàn phím bật lên để ẩn Navbar đi (tránh Navbar bị đẩy lên nóc bàn phím)
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      // Bỏ luôn extendBody ở đây vì Stack đã tự lo việc đó
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // 1. LỚP DƯỚI CÙNG: Nội dung các trang (Full màn hình)
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),

          // 2. LỚP TRÊN CÙNG: Thanh Navbar trôi nổi (Sẽ bị ẩn nếu bàn phím mở)
          if (!isKeyboardOpen)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0, // Bám chặt xuống đáy, padding của SmartNavBar sẽ tự đẩy nó lên
              child: PlatformNavBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() => _currentIndex = index);
                },
              ),
            ),
        ],
      ),
    );
  }
}