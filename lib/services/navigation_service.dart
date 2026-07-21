import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<T?>? navigateTo<T>(Widget page) {
    return navigatorKey.currentState?.push<T>(
      MaterialPageRoute(builder: (context) => page),
    );
  }

  static void pop<T>([T? result]) {
    return navigatorKey.currentState?.pop<T>(result);
  }
}
