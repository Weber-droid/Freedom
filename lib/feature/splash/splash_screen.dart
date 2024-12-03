import 'package:flutter/material.dart';
import 'package:freedom/feature/main_activity/main_activity_screen.dart';
import 'package:hive/hive.dart';

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
    final box = Hive.box<bool>('firstTimerUser');
    final isFirstTimer = box.get('isFirstTimer', defaultValue: true) ?? true;
    if (!isFirstTimer) {
      await Navigator.pushNamed(context, MainActivityScreen.routeName);
      return;
    }
    await Navigator.pushNamed(context, '/onBoarding');
  }
}
