import 'dart:developer';

import 'package:freedom/core/services/push_notification_service/socket_delivery_model.dart';
import 'package:freedom/core/services/push_notification_service/socket_ride_models.dart';
import 'package:freedom/core/services/socket_service.dart';
import 'package:freedom/feature/message_driver/cubit/in_app_message_cubit.dart';
import 'package:async/async.dart';

abstract class UnifiedDriverMessage {
  String get messageType;
  String get contextId;
  String get messageBody;
  String get senderId;
  String get notificationId;
  String get timeStamp;
  MessageContext get context;
}

class RideDriverMessage implements UnifiedDriverMessage {
  final DriverMessage _driverMessage;

  RideDriverMessage(this._driverMessage);

  @override
  String get messageType => _driverMessage.type;

  @override
  String get contextId => _driverMessage.notification.rideId;

  @override
  String get messageBody => _driverMessage.notification.body;

  @override
  String get senderId => _driverMessage.notification.from;

  @override
  String get notificationId => _driverMessage.notification.notificationId;

  @override
  String get timeStamp => _driverMessage.notification.timestamp;

  @override
  MessageContext get context => MessageContext.ride;

  DriverMessage get originalMessage => _driverMessage;
}

class DeliveryDriverMessage implements UnifiedDriverMessage {
  final DeliveryManMessage _deliveryMessage;

  DeliveryDriverMessage(this._deliveryMessage);

  @override
  String get messageType => _deliveryMessage.type;

  @override
  String get contextId => _deliveryMessage.notification.deliveryId;

  @override
  String get messageBody => _deliveryMessage.notification.body;

  @override
  String get senderId => _deliveryMessage.notification.from;

  @override
  String get notificationId => _deliveryMessage.notification.notificationId;

  @override
  String get timeStamp => _deliveryMessage.notification.timestamp;

  @override
  MessageContext get context => MessageContext.delivery;

  DeliveryManMessage get originalMessage => _deliveryMessage;
}

class UnifiedMessageStream {
  static Stream<UnifiedDriverMessage> create(SocketService socketService) {
    final rideStream = socketService.onDriverMessage.map(
      (msg) => RideDriverMessage(msg) as UnifiedDriverMessage,
    );

    final deliveryStream = socketService.onDeliveryMessage.map((msg) {
      log('Received delivery message: ${msg.notification.body}');
      return DeliveryDriverMessage(msg) as UnifiedDriverMessage;
    });

    return StreamGroup.merge([rideStream, deliveryStream]);
  }
}
