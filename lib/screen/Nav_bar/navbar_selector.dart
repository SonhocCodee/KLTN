// lib/navbar/navbar_selector.dart
import 'dart:io' show Platform;
import 'package:flutter/material.dart';

import 'navbar.dart'; // Chỉnh lại đường dẫn import nếu cần
import 'smart_navbar.dart'; // Chỉnh lại đường dẫn import nếu cần

class PlatformNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final ScrollController? scrollController;

  const PlatformNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    // Tự động phân luồng theo hệ điều hành
    if (Platform.isIOS) {
      return NavBarIOS(
        currentIndex: currentIndex,
        onTap: onTap,
      );
    } else {
      return SmartNavBar(
        currentIndex: currentIndex,
        onTap: onTap,
        scrollController: scrollController ?? ScrollController(),
      );
    }
  }
}