// lib/main_layout.dart
import 'package:flutter/material.dart';
import '../ExploreScreen/ExploreScreen.dart';

import '../ExploreScreen/explore_page.dart';
import '../IDENTIFY SCREEN/indentify_screen.dart';
import '../Search_smart/search_smart_screen.dart';
import '../SettingsScreen/SettingsScreen.dart';
import '../home/home_screen.dart';
import 'navbar.dart';
// Import các màn hình thực tế của bạn tại đây
// import '../screens/home_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // Danh sách các màn hình tương ứng với 5 tab
  final List<Widget> _pages = const [
    HomeScreen(),
    ExplorePage(),
    IdentifyScreen(),
    SmartQuizPage(),
    AnimalSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Bắt buộc để có hiệu ứng kính mờ
      backgroundColor: const Color(0xFFF8FAFC), // Màu nền tổng thể
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavBarIOS(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}