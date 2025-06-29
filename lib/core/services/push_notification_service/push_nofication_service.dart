import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:freedom/shared/theme/app_colors.dart';

class PushNotificationService {
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
        ], debug: true);
  }

  static Future<bool> askPermissions() async {
    var isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      // You can show a custom dialog here or use the default
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
        body: ' Your rider to pick you up, please be ready}',
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

  Future<void> handleRideStatusUpdate(Map<String, dynamic> statusData) async {
    final status = statusData['status']?.toString() ?? '';

    switch (status.toLowerCase()) {
      case 'arrived':
        await showDriverArrivedNotification(
          driverName: statusData['driverName'] as String,
          vehicleInfo: statusData['motorCycleInfo'] as String,
          estimatedTime: statusData['estimatedTime'] as String,
        );
      case 'enroute':
      case 'on_the_way':
        await showDriverEnRouteNotification(
          driverName: statusData['driverName'] as String,
          estimatedTime: statusData['estimatedTime'] as String,
          vehicleInfo: statusData['motorCycleInfo'] as String,
        );
      case 'cancelled':
        await showRideStatusNotification(
          status: status,
          message: 'Your ride has been cancelled.',
        );
    }
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
