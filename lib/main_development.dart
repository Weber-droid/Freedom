import 'package:freedom/app/app.dart';
import 'package:freedom/bootstrap.dart';
import 'package:freedom/core/config/environment_config.dart';
import 'package:freedom/di/locator.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  EnvironmentConfig.setEnvironment(Environment.development);
  await locator();
  await Hive.initFlutter();
  await Hive.openBox<bool>('firstTimerUser');
  await bootstrap(() => const App());
}
