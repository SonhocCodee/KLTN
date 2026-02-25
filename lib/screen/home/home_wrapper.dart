import 'package:flutter/material.dart';
import '../Nav_bar/main_layout.dart';
import '../Nav_bar/navbar.dart';
import 'daily_fact_screen.dart';
import 'home_screen.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: _onPageChanged,
        physics: _currentPage == 1
            ? const NeverScrollableScrollPhysics() // Trang Home không vuốt lên được
            : const ClampingScrollPhysics(), // Trang Daily có thể vuốt lên
        children: const [
          DailyFactScreen(),
          MainLayout(),        ],
      ),
    );
  }
}
