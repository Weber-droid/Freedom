// ignore_for_file: use_build_context_synchronously

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:freedom/app_preference.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/auth/view/login_view.dart';
import 'package:freedom/feature/main_activity/main_activity_screen.dart';
import 'package:freedom/feature/onboarding/view/carousel_view.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  static const routeName = '/';

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateUser();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Image(
        image: AssetImage('assets/images/splash_image.png'),
        height: double.infinity,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Future<void> _navigateUser() async {
    await Future<void>.delayed(const Duration(seconds: 2));

    // Get all values asynchronously
    final isFirstTimer = await AppPreferences.isFirstTimer();
    final onboardingCompleted = await AppPreferences.isOnboardingCompleted();
    final token = await AppPreferences.getToken();

    log('NAVIGATION CHECK - isFirstTimer: $isFirstTimer, onboardingCompleted: $onboardingCompleted, token: $token');

    if (!isFirstTimer && onboardingCompleted && token.isNotEmpty) {
      log('Navigating to MainActivityScreen - authenticated user');
      await Navigator.pushReplacementNamed(context, MainActivityScreen.routeName);
    } else if (!isFirstTimer && !onboardingCompleted) {
      log('Navigating to CarouselViewer - returning user who needs to complete onboarding');
      await Navigator.pushReplacementNamed(context, CarouselViewer.routeName);
    } else if (isFirstTimer) {
      log('Navigating to CarouselViewer - first time user');
      await AppPreferences.setFirstTimer(false);
      log('isFirstTimer flag set to false');
      await Navigator.pushReplacementNamed(context, CarouselViewer.routeName);
    } else {
      log('Navigating to LoginView - fallback case');
      await Navigator.pushReplacementNamed(context, LoginView.routeName);
    }
  }
}
