import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:freedom/app/view/app.dart';
import 'package:freedom/di/locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PushNotification {
  final firebaseMessaging = FirebaseMessaging.instance;
  final _keyManagement = getIt<SharedPreferences>();

  Future<void> init() async {
    await firebaseMessaging.requestPermission();
    final fcmToken = await firebaseMessaging.getToken();
    //save fcm token to storage
    await _keyManagement.setString('fcmToken', fcmToken.toString());
    log(fcmToken.toString());
  }

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;
    navigatorKey.currentState!.pushNamed('/home');
  }

  Future<void> backGroundSettings() async {
    await FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
  }

  Future<void> onMessage() async {
    FirebaseMessaging.onMessage.listen(handleMessage);
  }

  Future<void> onMessageOpenedApp() async {
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  }
}
