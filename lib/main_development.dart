import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:freedom/app/app.dart';
import 'package:freedom/bootstrap.dart';
import 'package:freedom/core/config/environment_config.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  EnvironmentConfig.setEnvironment(Environment.development);
  await locator();
  await initializeStorage();
  await bootstrap(() => const App());
}

