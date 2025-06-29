import 'package:freezed_annotation/freezed_annotation.dart';

part 'add_card_model.freezed.dart';
part 'add_card_model.g.dart';

@freezed
class AddCardModel with _$AddCardModel {
  const factory AddCardModel({
    required String type,
    required String cardType,
    required String last4,
    required String expiryMonth,
    required String expiryYear,
    required bool isDefault,
    required CardDetails cardDetails,
  }) = _AddCardModel;

  factory AddCardModel.fromJson(Map<String, dynamic> json) => _$AddCardModelFromJson(json);
}

@freezed
class CardDetails with _$CardDetails {
  const factory CardDetails({
    @JsonKey(name: 'card_number') required String cardNumber,
    required String cvv,
    @JsonKey(name: 'expiry_month') required String expiryMonth,
    @JsonKey(name: 'expiry_year') required String expiryYear,
    required String currency,
  }) = _CardDetails;

  factory CardDetails.fromJson(Map<String, dynamic> json) => _$CardDetailsFromJson(json);
}
