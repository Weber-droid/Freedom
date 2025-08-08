import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:freedom/shared/theme/app_colors.dart';

class PushNotificationService {
  static PushNotificationService? _instance;
  static PushNotificationService get instance {
    _instance ??= PushNotificationService._();
    return _instance!;
  }

  PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;

  final _messageStreamController = StreamController<RemoteMessage>.broadcast();
  final _tokenStreamController = StreamController<String>.broadcast();

  Stream<RemoteMessage> get onFcmMessage => _messageStreamController.stream;
  Stream<String> get onTokenRefresh => _tokenStreamController.stream;
  String? get fcmToken => _fcmToken;

  static Future<void> initialize() async {
    await AwesomeNotifications()
        .initialize('resource://drawable/notification_icon', [
          NotificationChannel(
            channelKey: 'ride_alerts',
            channelName: 'Ride Alerts',
            channelDescription: 'Notifications for ride status updates',
            defaultColor: thickFillColor,
            ledColor: thickFillColor,
            importance: NotificationImportance.High,
            playSound: true,
            enableVibration: true,
          ),
          NotificationChannel(
            channelKey: 'delivery_alerts',
            channelName: 'Delivery Alerts',
            channelDescription: 'Notifications for delivery status updates',
            defaultColor: thickFillColor,
            ledColor: thickFillColor,
            importance: NotificationImportance.High,
            playSound: true,
            enableVibration: true,
          ),
          NotificationChannel(
            channelKey: 'message_alerts',
            channelName: 'Message Alerts',
            channelDescription: 'Notifications for chat messages',
            defaultColor: thickFillColor,
            ledColor: thickFillColor,
            importance: NotificationImportance.High,
            playSound: true,
            enableVibration: true,
          ),
        ], debug: true);

    await instance._initializeFCM();
  }

  Future<void> _initializeFCM() async {
    try {
      await _requestFCMPermission();

      await _setupFCMMessageHandlers();

      await _getAndSaveFCMToken();

      _messaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        _tokenStreamController.add(token);
        log('FCM Token refreshed: $token');
      });

      log('FCM initialization completed successfully');
    } catch (e) {
      log('Error initializing FCM: $e');
    }
  }

  Future<void> _requestFCMPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    log('FCM Permission status: ${settings.authorizationStatus}');
  }

  Future<void> _setupFCMMessageHandlers() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Received foreground FCM message: ${message.messageId}');
      log('FCM Data: ${message.data}');

      _messageStreamController.add(message);

      _handleFCMMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log(
        'FCM notification tapped when app in background: ${message.messageId}',
      );
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      log(
        'App opened from terminated state via FCM notification: ${initialMessage.messageId}',
      );
    }
  }

  Future<void> _getAndSaveFCMToken() async {
    try {
      if (Platform.isIOS) {
        String? apnsToken;
        int attempts = 0;
        const maxAttempts = 10;

        while (apnsToken == null && attempts < maxAttempts) {
          try {
            apnsToken = await _messaging.getAPNSToken();
            if (apnsToken == null) {
              await Future.delayed(const Duration(milliseconds: 500));
              attempts++;
              log('Waiting for APNs token... attempt $attempts');
            }
          } catch (e) {
            log('Error getting APNs token on attempt $attempts: $e');
            await Future.delayed(const Duration(milliseconds: 500));
            attempts++;
          }
        }

        if (apnsToken != null) {
          log('APNs token obtained: ${apnsToken.substring(0, 20)}...');
        } else {
          log('Could not get APNs token after $maxAttempts attempts');
        }
      }

      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        log('FCM Token: $_fcmToken');
        _tokenStreamController.add(_fcmToken!);
      } else {
        log('FCM Token is null');
      }
    } catch (e) {
      log('Error getting FCM token: $e');

      Timer(const Duration(seconds: 2), () {
        _retryGetFCMToken();
      });
    }
  }

  Future<void> _retryGetFCMToken() async {
    try {
      log('Retrying FCM token fetch...');
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        log('FCM Token (retry): $_fcmToken');
        _tokenStreamController.add(_fcmToken!);
      }
    } catch (e) {
      log('Retry failed for FCM token: $e');
    }
  }

  void _handleFCMMessage(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    final messageType = data['type'] ?? '';
    final title = notification?.title ?? data['title'] ?? 'New Notification';
    final body = notification?.body ?? data['body'] ?? '';

    log('Processing FCM message type: $messageType');

    switch (messageType) {
      case 'ride_message':
        _showMessageNotification(
          title: title,
          body: body,
          data: data,
          channelKey: 'message_alerts',
        );
        break;

      case 'delivery_message':
        _showMessageNotification(
          title: title,
          body: body,
          data: data,
          channelKey: 'message_alerts',
        );
        break;

      case 'ride_status':
        _handleRideStatusFromFCM(data);
        break;

      case 'delivery_status':
        _handleDeliveryStatusFromFCM(data);
        break;

      case 'driver_accepted':
        showDriverAcceptNotification(
          driverName: data['driverName'] ?? 'Driver',
          vehicleInfo: data['vehicleInfo'] ?? '',
        );
        break;

      case 'driver_arrived':
        showDriverArrivedNotification(
          driverName: data['driverName'] ?? 'Driver',
          vehicleInfo: data['vehicleInfo'] ?? '',
        );
        break;

      default:
        _showGenericNotification(title: title, body: body, data: data);
        break;
    }
  }

  void _handleRideStatusFromFCM(Map<String, dynamic> data) {
    final status = data['status'] ?? '';
    final message = data['message'] ?? _getDefaultMessageForStatus(status);

    showRideStatusNotification(status: status, message: message);
  }

  void _handleDeliveryStatusFromFCM(Map<String, dynamic> data) {
    final status = data['status'] ?? '';
    final message = data['message'] ?? _getDefaultMessageForStatus(status);

    showDeliveryStatusNotification(status: status, message: message);
  }

  Future<void> _showMessageNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required String channelKey,
  }) async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        channelKey: channelKey,
        title: title,
        body: body,
        summary: 'Tap to reply',
        largeIcon: 'asset://assets/images/user.png',
        notificationLayout: NotificationLayout.BigText,
        wakeUpScreen: true,
        category: NotificationCategory.Message,
        payload: data.map((key, value) => MapEntry(key, value.toString())),
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'REPLY',
          label: 'Reply',
          color: Colors.blue,
        ),
        NotificationActionButton(
          key: 'OPEN_APP',
          label: 'Open',
          color: Colors.green,
        ),
      ],
    );
  }

  Future<void> _showGenericNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        channelKey: 'ride_alerts',
        title: title,
        body: body,
        payload: data.map((key, value) => MapEntry(key, value.toString())),
      ),
    );
  }

  static Future<bool> askPermissions() async {
    var isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      isAllowed =
          await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    return isAllowed;
  }

  Future<void> showDriverArrivedNotification({
    required String driverName,
    required String vehicleInfo,
    String? estimatedTime,
  }) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1004,
        channelKey: 'ride_alerts',
        title: '🚗 Your driver has arrived!',
        body: 'Your rider is here to pick you up, please be ready',
        summary: 'Tap to open app',
        largeIcon: 'asset://assets/images/bike_marker.png',
        notificationLayout: NotificationLayout.BigText,
        wakeUpScreen: true,
        fullScreenIntent: true,
        criticalAlert: true,
        category: NotificationCategory.Transport,
        payload: {
          'type': 'driver_arrived',
          'driverName': driverName,
          'motorCycleInfo': vehicleInfo,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'OPEN_APP',
          label: 'Open',
          color: Colors.blue,
        ),
      ],
    );
  }

  Future<void> showDriverAcceptNotification({
    required String driverName,
    required String vehicleInfo,
    String? estimatedTime,
  }) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1003,
        channelKey: 'ride_alerts',
        title: 'A rider has accepted your request',
        body:
            '$driverName is waiting for you${vehicleInfo.isNotEmpty ? ' in $vehicleInfo' : ''}',
        summary: 'Tap to open app',
        notificationLayout: NotificationLayout.BigText,
        wakeUpScreen: true,
        fullScreenIntent: true,
        criticalAlert: true,
        category: NotificationCategory.Transport,
        payload: {
          'type': 'rider_accepted',
          'riderName': driverName,
          'motorCycleInfo': vehicleInfo,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'OPEN_APP',
          label: 'Open',
          color: Colors.blue,
        ),
      ],
    );
  }

  Future<void> showDriverEnRouteNotification({
    required String driverName,
    required String estimatedTime,
    String? vehicleInfo,
  }) async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1002,
        channelKey: 'ride_alerts',
        title: '🚕 Driver on the way',
        body:
            '$driverName will arrive in $estimatedTime${vehicleInfo != null ? ' ($vehicleInfo)' : ''}',
        summary: 'Track your ride',
        largeIcon: 'asset://assets/images/bike_marker.png',
        payload: {
          'type': 'driver_enroute',
          'driverName': driverName,
          'estimatedTime': estimatedTime,
          'motorCycleInfo': vehicleInfo ?? '',
        },
      ),
    );
  }

  Future<void> showRideStatusNotification({
    required String status,
    required String message,
  }) async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) return;

    final title = _getTitleForStatus(status);
    final emoji = _getEmojiForStatus(status);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _getIdForStatus(status),
        channelKey: 'ride_alerts',
        title: '$emoji $title',
        body: message,
        payload: {
          'type': 'status_update',
          'status': status,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ),
    );
  }

  Future<void> showDeliveryStatusNotification({
    required String status,
    required String message,
  }) async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) return;

    final title = _getTitleForDeliveryStatus(status);
    final emoji = _getEmojiForStatus(status);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _getIdForStatus(status) + 100,
        channelKey: 'delivery_alerts',
        title: '$emoji $title',
        body: message,
        payload: {
          'type': 'delivery_status_update',
          'status': status,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ),
    );
  }

  Future<void> handleRideStatusUpdate(Map<String, dynamic> statusData) async {
    final status = statusData['status']?.toString() ?? '';

    switch (status.toLowerCase()) {
      case 'arrived':
        await showDriverArrivedNotification(
          driverName: statusData['driverName'] as String? ?? 'Driver',
          vehicleInfo: statusData['motorCycleInfo'] as String? ?? '',
          estimatedTime: statusData['estimatedTime'] as String?,
        );
        break;
      case 'enroute':
      case 'on_the_way':
        await showDriverEnRouteNotification(
          driverName: statusData['driverName'] as String? ?? 'Driver',
          estimatedTime: statusData['estimatedTime'] as String? ?? '5 mins',
          vehicleInfo: statusData['motorCycleInfo'] as String?,
        );
        break;
      case 'cancelled':
        await showRideStatusNotification(
          status: status,
          message: 'Your ride has been cancelled.',
        );
        break;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      log('Subscribed to FCM topic: $topic');
    } catch (e) {
      log('Error subscribing to FCM topic $topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      log('Unsubscribed from FCM topic: $topic');
    } catch (e) {
      log('Error unsubscribing from FCM topic $topic: $e');
    }
  }

  Future<void> subscribeToUserTopics(String userId) async {
    await subscribeToTopic('user_$userId');
    await subscribeToTopic('user_${userId}_rides');
    await subscribeToTopic('user_${userId}_deliveries');
  }

  Future<void> unsubscribeFromUserTopics(String userId) async {
    await unsubscribeFromTopic('user_$userId');
    await unsubscribeFromTopic('user_${userId}_rides');
    await unsubscribeFromTopic('user_${userId}_deliveries');
  }

  Future<void> deleteFCMToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      log('FCM token deleted');
    } catch (e) {
      log('Error deleting FCM token: $e');
    }
  }

  void dispose() {
    _messageStreamController.close();
    _tokenStreamController.close();
  }
}

String _getTitleForStatus(String status) {
  switch (status.toLowerCase()) {
    case 'arrived':
      return 'Driver Arrived';
    case 'enroute':
    case 'on_the_way':
      return 'Driver En Route';
    case 'started':
      return 'Ride Started';
    case 'completed':
      return 'Ride Completed';
    case 'cancelled':
      return 'Ride Cancelled';
    default:
      return 'Ride Update';
  }
}

String _getTitleForDeliveryStatus(String status) {
  switch (status.toLowerCase()) {
    case 'arrived':
      return 'Delivery Driver Arrived';
    case 'enroute':
    case 'on_the_way':
      return 'Delivery En Route';
    case 'started':
      return 'Delivery Started';
    case 'completed':
      return 'Delivery Completed';
    case 'cancelled':
      return 'Delivery Cancelled';
    default:
      return 'Delivery Update';
  }
}

String _getEmojiForStatus(String status) {
  switch (status.toLowerCase()) {
    case 'arrived':
      return '🚗';
    case 'enroute':
    case 'on_the_way':
      return '🚕';
    case 'started':
      return '🛣️';
    case 'completed':
      return '✅';
    case 'cancelled':
      return '❌';
    default:
      return '📱';
  }
}

int _getIdForStatus(String status) {
  switch (status.toLowerCase()) {
    case 'arrived':
      return 1001;
    case 'enroute':
    case 'on_the_way':
      return 1002;
    case 'started':
      return 1003;
    case 'completed':
      return 1004;
    case 'cancelled':
      return 1005;
    default:
      return 1000;
  }
}

String _getDefaultMessageForStatus(String status) {
  switch (status.toLowerCase()) {
    case 'arrived':
      return 'Your driver has arrived at your location';
    case 'enroute':
    case 'on_the_way':
      return 'Your driver is on the way';
    case 'started':
      return 'Your ride has started';
    case 'completed':
      return 'Your ride has been completed';
    case 'cancelled':
      return 'Your ride has been cancelled';
    default:
      return 'Ride status updated';
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}
