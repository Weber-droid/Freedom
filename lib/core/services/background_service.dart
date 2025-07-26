import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:freedom/app_preference.dart';
import 'package:freedom/core/services/push_notification_service/socket_delivery_model.dart';
import 'package:freedom/core/services/push_notification_service/socket_ride_models.dart';
import 'package:freedom/core/services/socket_service.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/message_driver/cache/in_app_message_cache.dart';
import 'package:freedom/feature/message_driver/models/message_models.dart';

class BackgroundMessageService {
  static BackgroundMessageService? _instance;
  static BackgroundMessageService get instance =>
      _instance ??= BackgroundMessageService._();

  BackgroundMessageService._();

  StreamSubscription<DriverMessage>? _rideMessageSubscription;
  StreamSubscription<DeliveryManMessage>? _deliveryMessageSubscription;
  SocketService? _socketService;
  String? _currentUserId;
  bool _isInitialized = false;

  final List<VoidCallback> _messageCallbacks = [];

  Future<void> initialize(SocketService socketService) async {
    if (_isInitialized) {
      log('BackgroundMessageService already initialized');
      return;
    }

    _socketService = socketService;
    await _initializeCurrentUserId();
    _startBackgroundListeners();
    _isInitialized = true;

    log('BackgroundMessageService initialized successfully');
  }

  Future<void> _initializeCurrentUserId() async {
    try {
      _currentUserId = await RegisterLocalDataSource().getUser().then(
        (user) => user?.userId,
      );
      log('BackgroundMessageService: Current user ID: $_currentUserId');
    } catch (e) {
      log('BackgroundMessageService: Error getting user ID: $e');
    }
  }

  void _startBackgroundListeners() {
    if (_socketService == null) {
      log('BackgroundMessageService: Socket service is null');
      return;
    }

    // Listen to ride messages
    _rideMessageSubscription?.cancel();
    _rideMessageSubscription = _socketService!.onDriverMessage.listen(
      (driverMessage) async {
        log(
          'BackgroundMessageService: Received ride message: ${driverMessage.notification.body}',
        );
        await _handleRideMessage(driverMessage);
      },
      onError: (error) {
        log('BackgroundMessageService: Error in ride message stream: $error');
      },
    );

    // Listen to delivery messages
    _deliveryMessageSubscription?.cancel();
    _deliveryMessageSubscription = _socketService!.onDeliveryMessage.listen(
      (deliveryMessage) async {
        log(
          'BackgroundMessageService: Received delivery message: ${deliveryMessage.notification.body}',
        );
        await _handleDeliveryMessage(deliveryMessage);
      },
      onError: (error) {
        log(
          'BackgroundMessageService: Error in delivery message stream: $error',
        );
      },
    );

    log(
      'BackgroundMessageService: Started listening to ride and delivery messages',
    );
  }

  Future<void> _handleRideMessage(DriverMessage driverMessage) async {
    try {
      await _initializeCurrentUserId();
      if (_currentUserId != null &&
          driverMessage.notification.from == _currentUserId) {
        log('BackgroundMessageService: Skipping own ride message');
        return;
      }
      final activeRideId = await AppPreferences.getRideId();
      if (activeRideId.isEmpty) {
        log('BackgroundMessageService: No active ride found');
        return;
      }
      if (driverMessage.notification.rideId != activeRideId) {
        log(
          'BackgroundMessageService: Message not for current ride: ${driverMessage.notification.rideId} != $activeRideId',
        );
        return;
      }

      final existingMessages = await InAppMessageCache.getMessages(
        activeRideId,
      );
      final messageExists = existingMessages.any(
        (msg) =>
            msg.message == driverMessage.notification.body &&
            msg.senderId == driverMessage.notification.from &&
            _isSimilarTimestamp(
              msg.timestamp,
              _parseTimestamp(driverMessage.notification.timestamp),
            ),
      );

      if (messageExists) {
        log('BackgroundMessageService: Ride message already exists, skipping');
        return;
      }

      // Create and save the message
      final messageTimestamp = _parseTimestamp(
        driverMessage.notification.timestamp,
      );
      final incomingMessage = MessageModels(
        driverMessage.notification.body,
        driverMessage.notification.from,
        messageTimestamp,
        driverMessage.notification.rideId,
        null,
        null,
        driverMessage.notification.notificationId,
        status: MessageStatus.delivered,
      );

      final cache = InAppMessageCache();
      await cache.addMessage(activeRideId, incomingMessage);

      log('BackgroundMessageService: Successfully saved ride message to cache');
      _notifyMessageCallbacks();
    } catch (e) {
      log('BackgroundMessageService: Error handling ride message: $e');
    }
  }

  Future<void> _handleDeliveryMessage(
    DeliveryManMessage deliveryMessage,
  ) async {
    try {
      await _initializeCurrentUserId();

      // Skip own messages
      if (_currentUserId != null &&
          deliveryMessage.notification.from == _currentUserId) {
        log('BackgroundMessageService: Skipping own delivery message');
        return;
      }

      // Get current active delivery ID
      final activeDeliveryId = await AppPreferences.getDeliveryId();
      if (activeDeliveryId.isEmpty) {
        log('BackgroundMessageService: No active delivery found');
        return;
      }

      // Only process messages for the current active delivery
      if (deliveryMessage.notification.deliveryId != activeDeliveryId) {
        log(
          'BackgroundMessageService: Message not for current delivery: ${deliveryMessage.notification.deliveryId} != $activeDeliveryId',
        );
        return;
      }

      // Check for duplicates
      final existingMessages = await InAppMessageCache.getMessages(
        activeDeliveryId,
      );
      final messageExists = existingMessages.any(
        (msg) =>
            msg.message == deliveryMessage.notification.body &&
            msg.senderId == deliveryMessage.notification.from &&
            _isSimilarTimestamp(
              msg.timestamp,
              _parseTimestamp(deliveryMessage.notification.timestamp),
            ),
      );

      if (messageExists) {
        log(
          'BackgroundMessageService: Delivery message already exists, skipping',
        );
        return;
      }

      // Create and save the message
      final messageTimestamp = _parseTimestamp(
        deliveryMessage.notification.timestamp,
      );
      final incomingMessage = MessageModels(
        deliveryMessage.notification.body,
        deliveryMessage.notification.from,
        messageTimestamp,
        deliveryMessage.notification.deliveryId,
        null, // driverId
        null, // driverName
        deliveryMessage.notification.notificationId,
        status: MessageStatus.delivered,
      );

      final cache = InAppMessageCache();
      await cache.addMessage(activeDeliveryId, incomingMessage);

      log(
        'BackgroundMessageService: Successfully saved delivery message to cache',
      );

      // Notify any listening cubits
      _notifyMessageCallbacks();
    } catch (e) {
      log('BackgroundMessageService: Error handling delivery message: $e');
    }
  }

  DateTime _parseTimestamp(String timestampString) {
    try {
      final parsedTimestamp = DateTime.tryParse(timestampString);
      if (parsedTimestamp != null) {
        return parsedTimestamp.toLocal();
      }

      final milliseconds = int.tryParse(timestampString);
      if (milliseconds != null) {
        if (milliseconds.toString().length == 10) {
          return DateTime.fromMillisecondsSinceEpoch(
            milliseconds * 1000,
            isUtc: true,
          ).toLocal();
        } else {
          return DateTime.fromMillisecondsSinceEpoch(
            milliseconds,
            isUtc: true,
          ).toLocal();
        }
      }

      return DateTime.now();
    } catch (e) {
      log('BackgroundMessageService: Error parsing timestamp: $e');
      return DateTime.now();
    }
  }

  bool _isSimilarTimestamp(DateTime? timestamp1, DateTime timestamp2) {
    if (timestamp1 == null) return false;
    return timestamp1.difference(timestamp2).abs().inSeconds < 5;
  }

  void _notifyMessageCallbacks() {
    for (final callback in _messageCallbacks) {
      try {
        callback();
      } catch (e) {
        log('BackgroundMessageService: Error in message callback: $e');
      }
    }
  }

  void addMessageCallback(VoidCallback callback) {
    _messageCallbacks.add(callback);
    log('BackgroundMessageService: Added message callback');
  }

  void removeMessageCallback(VoidCallback callback) {
    _messageCallbacks.remove(callback);
    log('BackgroundMessageService: Removed message callback');
  }

  void dispose() {
    _rideMessageSubscription?.cancel();
    _deliveryMessageSubscription?.cancel();
    _rideMessageSubscription = null;
    _deliveryMessageSubscription = null;
    _messageCallbacks.clear();
    _isInitialized = false;
    log('BackgroundMessageService disposed');
  }

  bool get isInitialized => _isInitialized;
}
