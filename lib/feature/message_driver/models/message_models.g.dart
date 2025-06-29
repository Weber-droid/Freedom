// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MessageModelsAdapter extends TypeAdapter<MessageModels> {
  @override
  final int typeId = 2;

  @override
  MessageModels read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MessageModels(
      fields[0] as String?,
      fields[1] as String?,
      fields[2] as DateTime?,
      fields[3] as String?,
      fields[4] as String?,
      fields[5] as String?,
      fields[6] as String?,
      status: fields[7] as MessageStatus,
    );
  }

  @override
  void write(BinaryWriter writer, MessageModels obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.message)
      ..writeByte(1)
      ..write(obj.senderId)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.rideId)
      ..writeByte(4)
      ..write(obj.driverId)
      ..writeByte(5)
      ..write(obj.driverName)
      ..writeByte(6)
      ..write(obj.userName)
      ..writeByte(7)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModelsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ConversationAdapter extends TypeAdapter<Conversation> {
  @override
  final int typeId = 3;

  @override
  Conversation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Conversation(
      fields[0] as String,
      (fields[3] as List).cast<MessageModels>(),
      fields[1] as String,
      fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Conversation obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.rideId)
      ..writeByte(1)
      ..write(obj.driverId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.messages);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MessageStatusAdapter extends TypeAdapter<MessageStatus> {
  @override
  final int typeId = 4;

  @override
  MessageStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MessageStatus.sending;
      case 1:
        return MessageStatus.sent;
      case 2:
        return MessageStatus.delivered;
      case 3:
        return MessageStatus.failed;
      default:
        return MessageStatus.sending;
    }
  }

  @override
  void write(BinaryWriter writer, MessageStatus obj) {
    switch (obj) {
      case MessageStatus.sending:
        writer.writeByte(0);
        break;
      case MessageStatus.sent:
        writer.writeByte(1);
        break;
      case MessageStatus.delivered:
        writer.writeByte(2);
        break;
      case MessageStatus.failed:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
