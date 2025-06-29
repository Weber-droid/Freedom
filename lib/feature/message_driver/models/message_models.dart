import 'package:hive/hive.dart';

part 'message_models.g.dart';

@HiveType(typeId: 4)
enum MessageStatus {
  @HiveField(0)
  sending,

  @HiveField(1)
  sent,

  @HiveField(2)
  delivered,

  @HiveField(3)
  failed,
}

@HiveType(typeId: 2)
class MessageModels {
  MessageModels(
    this.message,
    this.senderId,
    this.timestamp,
    this.rideId,
    this.driverId,
    this.driverName,
    this.userName, {
    this.status = MessageStatus.sent,
  });

  @HiveField(0)
  final String? message;

  @HiveField(1)
  final String? senderId;

  @HiveField(2)
  final DateTime? timestamp;

  @HiveField(3)
  final String? rideId;

  @HiveField(4)
  final String? driverId;

  @HiveField(5)
  final String? driverName;

  @HiveField(6)
  final String? userName;

  @HiveField(7)
  final MessageStatus status;

  MessageModels copyWith({
    String? message,
    String? senderId,
    DateTime? timestamp,
    String? rideId,
    String? driverId,
    String? driverName,
    String? userName,
    MessageStatus? status,
  }) {
    return MessageModels(
      message ?? this.message,
      senderId ?? this.senderId,
      timestamp ?? this.timestamp,
      rideId ?? this.rideId,
      driverId ?? this.driverId,
      driverName ?? this.driverName,
      userName ?? this.userName,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'MessageModels(message: $message, senderId: $senderId, status: $status, timestamp: ${timestamp?.millisecondsSinceEpoch})';
  }
}

@HiveType(typeId: 3)
class Conversation {
  Conversation(this.rideId, this.messages, this.driverId, this.userId);

  @HiveField(0)
  final String rideId;

  @HiveField(1)
  final String driverId;

  @HiveField(2)
  final String userId;

  @HiveField(3)
  final List<MessageModels> messages;

  Conversation copyWith({
    String? rideId,
    String? driverId,
    String? userId,
    List<MessageModels>? messages,
  }) {
    return Conversation(
      rideId ?? this.rideId,
      messages ?? this.messages,
      driverId ?? this.driverId,
      userId ?? this.userId,
    );
  }
}
