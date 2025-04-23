import 'package:freedom/app/app.dart';
import 'package:freedom/bootstrap.dart';
import 'package:freedom/core/config/environment_config.dart';
import 'package:freedom/core/services/audio_call_service/audio_call_service.dart';

void main() {
  EnvironmentConfig.setEnvironment(Environment.staging);
  final callService = StreamCallService();
  bootstrap(() => App(
        callService: callService,
      ));
}
