import 'package:flutter/material.dart';

/// Dùng để điều hướng khi người dùng bấm vào push notification
/// mà không cần BuildContext.
class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}
