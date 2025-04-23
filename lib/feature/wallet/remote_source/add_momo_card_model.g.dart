// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_momo_card_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AddMomoCardModelImpl _$$AddMomoCardModelImplFromJson(
        Map<String, dynamic> json) =>
    _$AddMomoCardModelImpl(
      momoProvider: json['momoProvider'] as String,
      momoNumber: json['momoNumber'] as String,
      type: json['type'] as String,
      isDefault: json['isDefault'] as bool,
    );

Map<String, dynamic> _$$AddMomoCardModelImplToJson(
        _$AddMomoCardModelImpl instance) =>
    <String, dynamic>{
      'momoProvider': instance.momoProvider,
      'momoNumber': instance.momoNumber,
      'type': instance.type,
      'isDefault': instance.isDefault,
    };
