// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      id: fields[0] as String?,
      phone: fields[1] as String?,
      email: fields[2] as String?,
      role: fields[3] as String?,
      token: fields[4] as String?,
      success: fields[5] as bool?,
      message: fields[6] as String?,
      userId: fields[7] as String?,
      userImage: fields[8] as String?,
      firstName: fields[9] as String?,
      surname: fields[10] as String?,
      profilePicture: fields[11] as String?,
      isPhoneVerified: fields[12] as bool?,
      isEmailVerified: fields[13] as bool?,
      authProvider: fields[14] as String?,
      socialId: fields[15] as String?,
      socialProfile: (fields[16] as Map?)?.cast<String, dynamic>(),
      rideHistory: (fields[17] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
          ?.toList(),
      paymentMethod: fields[18] as String?,
      paystackCustomerId: fields[19] as String?,
      mobileMoneyProvider: fields[20] as String?,
      preferredLanguage: fields[21] as String?,
      cardTokens: (fields[22] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
          ?.toList(),
      knownDevices: (fields[23] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
          ?.toList(),
      createdAt: fields[24] as DateTime?,
      updatedAt: fields[25] as DateTime?,
      notificationPreferences: fields[26] as NotificationPreferences?,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(27)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.phone)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.token)
      ..writeByte(5)
      ..write(obj.success)
      ..writeByte(6)
      ..write(obj.message)
      ..writeByte(7)
      ..write(obj.userId)
      ..writeByte(8)
      ..write(obj.userImage)
      ..writeByte(9)
      ..write(obj.firstName)
      ..writeByte(10)
      ..write(obj.surname)
      ..writeByte(11)
      ..write(obj.profilePicture)
      ..writeByte(12)
      ..write(obj.isPhoneVerified)
      ..writeByte(13)
      ..write(obj.isEmailVerified)
      ..writeByte(14)
      ..write(obj.authProvider)
      ..writeByte(15)
      ..write(obj.socialId)
      ..writeByte(16)
      ..write(obj.socialProfile)
      ..writeByte(17)
      ..write(obj.rideHistory)
      ..writeByte(18)
      ..write(obj.paymentMethod)
      ..writeByte(19)
      ..write(obj.paystackCustomerId)
      ..writeByte(20)
      ..write(obj.mobileMoneyProvider)
      ..writeByte(21)
      ..write(obj.preferredLanguage)
      ..writeByte(22)
      ..write(obj.cardTokens)
      ..writeByte(23)
      ..write(obj.knownDevices)
      ..writeByte(24)
      ..write(obj.createdAt)
      ..writeByte(25)
      ..write(obj.updatedAt)
      ..writeByte(26)
      ..write(obj.notificationPreferences);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NotificationPreferencesAdapter
    extends TypeAdapter<NotificationPreferences> {
  @override
  final int typeId = 1;

  @override
  NotificationPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationPreferences(
      loginAlerts: fields[0] as bool?,
      securityAlerts: fields[1] as bool?,
      marketingEmails: fields[2] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationPreferences obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.loginAlerts)
      ..writeByte(1)
      ..write(obj.securityAlerts)
      ..writeByte(2)
      ..write(obj.marketingEmails);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
