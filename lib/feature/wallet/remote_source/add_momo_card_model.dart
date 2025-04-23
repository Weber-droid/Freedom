import 'package:freezed_annotation/freezed_annotation.dart';

part 'add_momo_card_model.freezed.dart';
part 'add_momo_card_model.g.dart';

@freezed
class AddMomoCardModel with _$AddMomoCardModel {
  const factory AddMomoCardModel({
    required String momoProvider,
    required String momoNumber,
    required String type,
    required bool isDefault,
  }) = _AddMomoCardModel;

  factory AddMomoCardModel.fromJson(Map<String, dynamic> json) =>
      _$AddMomoCardModelFromJson(json);
}
