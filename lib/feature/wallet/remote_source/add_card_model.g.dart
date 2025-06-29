// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_card_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AddCardModelImpl _$$AddCardModelImplFromJson(Map<String, dynamic> json) =>
    _$AddCardModelImpl(
      type: json['type'] as String,
      cardType: json['cardType'] as String,
      last4: json['last4'] as String,
      expiryMonth: json['expiryMonth'] as String,
      expiryYear: json['expiryYear'] as String,
      isDefault: json['isDefault'] as bool,
      cardDetails:
          CardDetails.fromJson(json['cardDetails'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$AddCardModelImplToJson(_$AddCardModelImpl instance) =>
    <String, dynamic>{
      'type': instance.type,
      'cardType': instance.cardType,
      'last4': instance.last4,
      'expiryMonth': instance.expiryMonth,
      'expiryYear': instance.expiryYear,
      'isDefault': instance.isDefault,
      'cardDetails': instance.cardDetails,
    };

_$CardDetailsImpl _$$CardDetailsImplFromJson(Map<String, dynamic> json) =>
    _$CardDetailsImpl(
      cardNumber: json['card_number'] as String,
      cvv: json['cvv'] as String,
      expiryMonth: json['expiry_month'] as String,
      expiryYear: json['expiry_year'] as String,
      currency: json['currency'] as String,
    );

Map<String, dynamic> _$$CardDetailsImplToJson(_$CardDetailsImpl instance) =>
    <String, dynamic>{
      'card_number': instance.cardNumber,
      'cvv': instance.cvv,
      'expiry_month': instance.expiryMonth,
      'expiry_year': instance.expiryYear,
      'currency': instance.currency,
    };
