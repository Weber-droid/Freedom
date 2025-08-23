import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:freedom/app/app.dart';
import 'package:freedom/bootstrap.dart';
import 'package:freedom/core/config/environment_config.dart';
import 'package:freedom/core/services/background_service.dart';
import 'package:freedom/core/services/push_notification_service/push_nofication_service.dart';
import 'package:freedom/core/services/socket_service.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
    name: 'Freedom-main-app',
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  EnvironmentConfig.setEnvironment(Environment.development);
  await PushNotificationService.initialize();
  await dotenv.load(fileName: ".env");
  await locator();
  await initializeStorage();
  final service = getIt<SocketService>();
  await BackgroundMessageService.instance.initialize(service);
  await bootstrap(() => App());
}
