// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_methods.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserPaymentMethodsResponseImpl _$$UserPaymentMethodsResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$UserPaymentMethodsResponseImpl(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$UserPaymentMethodsResponseImplToJson(
        _$UserPaymentMethodsResponseImpl instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };

_$CardPaymentMethodImpl _$$CardPaymentMethodImplFromJson(
        Map<String, dynamic> json) =>
    _$CardPaymentMethodImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      cardType: json['cardType'] as String,
      last4: json['last4'] as String,
      expiryMonth: json['expiryMonth'] as String,
      expiryYear: json['expiryYear'] as String,
      isDefault: json['isDefault'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      token: json['token'] as String?,
    );

Map<String, dynamic> _$$CardPaymentMethodImplToJson(
        _$CardPaymentMethodImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'type': instance.type,
      'cardType': instance.cardType,
      'last4': instance.last4,
      'expiryMonth': instance.expiryMonth,
      'expiryYear': instance.expiryYear,
      'isDefault': instance.isDefault,
      'createdAt': instance.createdAt.toIso8601String(),
      'token': instance.token,
    };

_$MomoPaymentMethodImpl _$$MomoPaymentMethodImplFromJson(
        Map<String, dynamic> json) =>
    _$MomoPaymentMethodImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      momoProvider: json['momoProvider'] as String,
      momoNumber: json['momoNumber'] as String,
      isDefault: json['isDefault'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$MomoPaymentMethodImplToJson(
        _$MomoPaymentMethodImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'type': instance.type,
      'momoProvider': instance.momoProvider,
      'momoNumber': instance.momoNumber,
      'isDefault': instance.isDefault,
      'createdAt': instance.createdAt.toIso8601String(),
    };
