enum SocketModelStatus { accepted, arrived, started, completed, cancelled }

class DriverAcceptedModel {
  DriverAcceptedModel({
    this.driverId,
    this.status,
    this.rideId,
    this.motorcycleType,
    this.driverName,
    this.phone,
  });

  factory DriverAcceptedModel.fromJson(Map<String, dynamic> json) {
    final driverJson = json['driver'] as Map<String, dynamic>?;

    final driver = driverJson != null ? Driver.fromJson(driverJson) : null;

    return DriverAcceptedModel(
      rideId: json['rideId'] as String?,
      status: json['status'] as String?,
      driverId: driver?.id,
      driverName: driver?.name,
      phone: driver?.phone,
      motorcycleType: driver?.motorcycleType,
    );
  }

  Map<String, dynamic> toJson() => {
    'rideId': rideId,
    'status': status,
    'driver': {
      'id': driverId,
      'name': driverName,
      'phone': phone,
      'motorcycleType': motorcycleType,
    },
  };

  final String? rideId;
  final String? driverId;
  final String? status;
  final String? driverName;
  final String? phone;
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'motorcycleType': motorcycleType,
    };
  }

  final String id;
  final String name;
  final String phone;
  final String motorcycleType;
}

class DriverArrived {
  DriverArrived(this.rideId, this.status);

  factory DriverArrived.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DriverArrived('', '');
    return DriverArrived(
      json['rideId'] as String? ?? '',
      json['status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'rideId': rideId, 'status': status};

  final String rideId;
  final String status;
}

class DriverCancelled {
  DriverCancelled(this.rideId, this.status);

  factory DriverCancelled.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DriverCancelled('', '');
    return DriverCancelled(
      json['rideId'] as String? ?? '',
      json['status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'rideId': rideId, 'status': status};

  final String rideId;
  final String status;
}

class DriverStarted {
  DriverStarted(this.rideId, this.status);

  factory DriverStarted.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DriverStarted('', '');
    return DriverStarted(
      json['rideId'] as String? ?? '',
      json['status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'rideId': rideId, 'status': status};

  final String rideId;
  final String status;
}

class DriverCompleted {
  DriverCompleted(this.rideId, this.status);

  factory DriverCompleted.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DriverCompleted('', '');
    return DriverCompleted(
      json['rideId'] as String? ?? '',
      json['status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'rideId': rideId, 'status': status};

  final String rideId;
  final String status;
}

class DriverRejected {
  DriverRejected(this.rideId, this.status);

  factory DriverRejected.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DriverRejected('', '');
    return DriverRejected(
      json['rideId'] as String? ?? '',
      json['status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'rideId': rideId, 'status': status};

  final String rideId;
  final String status;
}

class DriverMessage {
  DriverMessage(this.type, this.notification);

  factory DriverMessage.fromJson(Map<String, dynamic> json) {
    return DriverMessage(
      json['type'] as String? ?? '',
      DriverNotificationBody.fromJson(
        json['notification'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'notification': notification.toJson(),
  };

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
  Map<String, dynamic> toJson() => {
    'rideId': rideId,
    'title': title,
    'body': body,
    'from': from,
    'notificationId': notificationId,
    'timestamp': timestamp,
  };
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

///Delivery model
