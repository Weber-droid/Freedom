import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:freedom/app/app.dart';
import 'package:freedom/bootstrap.dart';
import 'package:freedom/core/config/environment_config.dart';
import 'package:freedom/core/services/audio_call_service/audio_call_service.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/firebase_options.dart';

void main() async{
  EnvironmentConfig.setEnvironment(Environment.production);
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  EnvironmentConfig.setEnvironment(Environment.development);
  await locator();
  await initializeStorage();
  final callService = StreamCallService();
  await bootstrap(() => App(
        callService: callService,
      ));
}
