import 'package:freedom/app/app.dart';
import 'package:freedom/bootstrap.dart';
import 'package:freedom/core/config/environment_config.dart';

void main() {
  EnvironmentConfig.setEnvironment(Environment.staging);
  bootstrap(() => const App());
}
