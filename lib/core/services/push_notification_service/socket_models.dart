enum SocketModelStatus { accepted, arrived, started, completed, cancelled }

class DriverAcceptedModel {
  DriverAcceptedModel(
    this.driverId,
    this.status,
    this.rideId,
    this.motorcycleType,
    this.driverName,
  );

  factory DriverAcceptedModel.fromJson(Map<String, dynamic> json) {
    return DriverAcceptedModel(
      json['rideId'] as String,
      json['status'] as String,
      Driver.fromJson(json['driver'] as Map<String, dynamic>).id,
      Driver.fromJson(json['driver'] as Map<String, dynamic>).motorcycleType,
      Driver.fromJson(json['driver'] as Map<String, dynamic>).name,
    );
  }
  final String? rideId;
  final String? driverId;
  final String? status;
  final String? driverName;
  final String? motorcycleType;
}

class Driver {
  Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.motorcycleType,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
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

class DriverArrived {
  DriverArrived(this.rideId, this.status);
  factory DriverArrived.fromJson(Map<String, dynamic> json) {
    return DriverArrived(json['rideId'] as String, json['status'] as String);
  }
  final String rideId;
  final String? status;
}

class DriverCancelled {
  DriverCancelled(this.driverId, this.status);
  factory DriverCancelled.fromJson(Map<String, dynamic> json) {
    return DriverCancelled(json['rideId'] as String, json['status'] as String);
  }
  final String driverId;
  final String? status;
}

class DriverStarted {
  DriverStarted(this.driverId, this.status);
  factory DriverStarted.fromJson(Map<String, dynamic> json) {
    return DriverStarted(json['rideId'] as String, json['status'] as String);
  }
  final String driverId;
  final String? status;
}

class DriverCompleted {
  DriverCompleted(this.driverId, this.status);
  factory DriverCompleted.fromJson(Map<String, dynamic> json) {
    return DriverCompleted(json['rideId'] as String, json['status'] as String);
  }
  final String driverId;
  final String? status;
}

class DriverRejected {
  DriverRejected(this.driverId, this.status);
  factory DriverRejected.fromJson(Map<String, dynamic> json) {
    return DriverRejected(json['rideId'] as String, json['status'] as String);
  }
  final String driverId;
  final String? status;
}

class DriverMessage {
  DriverMessage(this.type, this.notification);

  factory DriverMessage.fromJson(Map<String, dynamic> json) {
    return DriverMessage(
      json['type'] as String,
      DriverNotificationBody.fromJson(
        json['notification'] as Map<String, dynamic>,
      ),
    );
  }
  final String type;
  final DriverNotificationBody notification;
}

class DriverNotificationBody {
  DriverNotificationBody({
    required this.rideId,
    required this.title,
    required this.body,
    required this.from,
    required this.notificationId,
    required this.timestamp,
  });
  factory DriverNotificationBody.fromJson(Map<String, dynamic> json) {
    return DriverNotificationBody(
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
