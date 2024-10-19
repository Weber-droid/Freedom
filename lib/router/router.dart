import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:freedom/feature/main_activity/main_activity_screen.dart';
import 'package:freedom/feature/splash/splash_screen.dart';
import 'package:freedom/router/error_page.dart';

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  log('Requested route: ${settings.name}');

  switch (settings.name) {
    case SplashPage.routeName:
      return _pageBuilder(
        (context) => const SplashPage(),
        settings: settings,
      );
    case MainActivityScreen.routeName:
      return _pageBuilder(
        (context) => const MainActivityScreen(),
        settings: settings,
      );
    default:
      return _pageBuilder(
        (context) => const ErrorPage(),
        settings: settings,
      );
  }
}

PageRouteBuilder<dynamic> _pageBuilder(
  Widget Function(BuildContext context) pageBuilder, {
  required RouteSettings settings,
}) {
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (context, _, __) => pageBuilder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}
