import 'package:freedom/core/services/push_notification_service/socket_ride_models.dart';

class DeliveryManAcceptedModel {
  DeliveryManAcceptedModel({
    required this.deliveryId,
    required this.driverId,
    required this.status,
    required this.phone,
  });

  factory DeliveryManAcceptedModel.fromJson(Map<String, dynamic> json) {
    final driverJson = json['driver'] as Map<String, dynamic>?;

    final driver = driverJson != null ? DeliveryMan.fromJson(driverJson) : null;

    return DeliveryManAcceptedModel(
      deliveryId: json['deliveryId']?.toString(),
      status: json['status']?.toString(),
      driverId: driver?.id,
      phone: driver?.phone,
    );
  }

  final String? deliveryId;
  final String? driverId;
  final String? status;
  final String? phone;
}

class DeliveryMan {
  DeliveryMan({required this.id, required this.phone});

  factory DeliveryMan.fromJson(Map<String, dynamic> json) {
    return DeliveryMan(
      id: json['id'] as String,
      phone: json['phone'] as String,
    );
  }
  final String id;
  final String phone;
}

class Delivery {
  Delivery({
    required this.id,
    required this.name,
    required this.phone,
    required this.motorcycleType,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      motorcycleType: json['motorcycleType'] as String,
    );
  }
  final String id;
  final String name;
  final String phone;
  final String motorcycleType;
}

class DeliveryArrived {
  DeliveryArrived(this.deliveryId, this.status);
  factory DeliveryArrived.fromJson(Map<String, dynamic> json) {
    return DeliveryArrived(
      json['deliveryId'] as String,
      json['status'] as String,
    );
  }
  final String deliveryId;
  final String? status;
}

class DeliveryManCancelled {
  DeliveryManCancelled(this.driverId, this.status);
  factory DeliveryManCancelled.fromJson(Map<String, dynamic> json) {
    return DeliveryManCancelled(
      json['rideId'] as String,
      json['status'] as String,
    );
  }
  final String driverId;
  final String? status;
}

class DeliveryManStarted {
  DeliveryManStarted(this.deliveryId, this.status);
  factory DeliveryManStarted.fromJson(Map<String, dynamic> json) {
    return DeliveryManStarted(
      json['deliveryId'] as String,
      json['status'] as String,
    );
  }
  final String deliveryId;
  final String? status;
}

class DeliveryManCompleted {
  DeliveryManCompleted(this.driverId, this.status);
  factory DeliveryManCompleted.fromJson(Map<String, dynamic> json) {
    return DeliveryManCompleted(
      json['rideId'] as String,
      json['status'] as String,
    );
  }
  final String driverId;
  final String? status;
}

class DeliveryManRejected {
  DeliveryManRejected(this.driverId, this.status);
  factory DeliveryManRejected.fromJson(Map<String, dynamic> json) {
    return DeliveryManRejected(
      json['rideId'] as String,
      json['status'] as String,
    );
  }
  final String driverId;
  final String? status;
}

class DeliveryManMessage {
  DeliveryManMessage(this.type, this.notification);

  factory DeliveryManMessage.fromJson(Map<String, dynamic> json) {
    return DeliveryManMessage(
      json['type'] as String,
      DriverNotificationBody.fromJson(
        json['notification'] as Map<String, dynamic>,
      ),
    );
  }
  final String type;
  final DriverNotificationBody notification;
}

class DeliveryManNotificationBody {
  DeliveryManNotificationBody({
    required this.rideId,
    required this.title,
    required this.body,
    required this.from,
    required this.notificationId,
    required this.timestamp,
  });
  factory DeliveryManNotificationBody.fromJson(Map<String, dynamic> json) {
    return DeliveryManNotificationBody(
      rideId: json['rideId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      from: json['from'] as String,
      notificationId: json['notificationId'] as String,
      timestamp: json['timestamp'] as String,
    );
  }
  final String rideId;
  final String title;
  final String body;
  final String from;
  final String notificationId;
  final String timestamp;

  @override
  String toString() {
    return 'DriverNotificationBody(rideId: $rideId, title: $title, body: $body, from: $from, notificationId: $notificationId, timestamp: $timestamp)';
  }
}
