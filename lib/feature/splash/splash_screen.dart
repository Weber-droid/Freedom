import 'package:flutter/material.dart';
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

    final isFirstTimer = RegisterLocalDataSource.checkIsFirstTimer();
    final onboardingCompleted =
        RegisterLocalDataSource.checkOnboardingCompleted();
    final token = RegisterLocalDataSource.getJwtToken();

    if (!isFirstTimer &&
        onboardingCompleted &&
        token != null &&
        token.isNotEmpty) {
      await Navigator.pushNamed(context, MainActivityScreen.routeName);
      return;
    } else if (!isFirstTimer && !onboardingCompleted) {
      await Navigator.pushNamed(context, CarouselViewer.routeName);
      return;
    } else if (isFirstTimer) {
      await RegisterLocalDataSource.setIsFirstTimer(isFirstTimer: false);
      await Navigator.pushNamed(context,CarouselViewer.routeName);
      return;
    } else {
      await Navigator.pushNamed(context, LoginView.routeName);
      return;
    }
  }
}
