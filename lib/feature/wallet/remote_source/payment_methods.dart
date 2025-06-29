import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_methods.freezed.dart';
part 'payment_methods.g.dart';

@freezed
class UserPaymentMethodsResponse with _$UserPaymentMethodsResponse {
  const factory UserPaymentMethodsResponse({
    required bool success,
    required List<PaymentMethod> data,
  }) = _UserPaymentMethodsResponse;

  factory UserPaymentMethodsResponse.fromJson(Map<String, dynamic> json) =>
      _$UserPaymentMethodsResponseFromJson(json);
}

@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.none)
class PaymentMethod with _$PaymentMethod {
  @FreezedUnionValue('card')
  const factory PaymentMethod.card({
    required String id,
    required String userId,
    required String type,
    required String cardType,
    required String last4,
    required String expiryMonth,
    required String expiryYear,
    required bool isDefault,
    required DateTime createdAt,
    String? token,
  }) = CardPaymentMethod;

  @FreezedUnionValue('momo')
  const factory PaymentMethod.momo({
    required String id,
    required String userId,
    required String type,
    required String momoProvider,
    required String momoNumber,
    required bool isDefault,
    required DateTime createdAt,
  }) = MomoPaymentMethod;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodFromJson(json);
}

enum CardType {
  @JsonValue('mastercard')
  visa,

  @JsonValue('mastercard')
  mastercard;
}

enum MomoProvider {
  @JsonValue('MTN')
  mtn,

  @JsonValue('Vodafone')
  vodafone,

  @JsonValue('AirtelTigo')
  airtelTigo;
}
