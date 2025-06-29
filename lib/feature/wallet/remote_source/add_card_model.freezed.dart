// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'add_card_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AddCardModel _$AddCardModelFromJson(Map<String, dynamic> json) {
  return _AddCardModel.fromJson(json);
}

/// @nodoc
mixin _$AddCardModel {
  String get type => throw _privateConstructorUsedError;
  String get cardType => throw _privateConstructorUsedError;
  String get last4 => throw _privateConstructorUsedError;
  String get expiryMonth => throw _privateConstructorUsedError;
  String get expiryYear => throw _privateConstructorUsedError;
  bool get isDefault => throw _privateConstructorUsedError;
  CardDetails get cardDetails => throw _privateConstructorUsedError;

  /// Serializes this AddCardModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AddCardModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AddCardModelCopyWith<AddCardModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AddCardModelCopyWith<$Res> {
  factory $AddCardModelCopyWith(
          AddCardModel value, $Res Function(AddCardModel) then) =
      _$AddCardModelCopyWithImpl<$Res, AddCardModel>;
  @useResult
  $Res call(
      {String type,
      String cardType,
      String last4,
      String expiryMonth,
      String expiryYear,
      bool isDefault,
      CardDetails cardDetails});

  $CardDetailsCopyWith<$Res> get cardDetails;
}

/// @nodoc
class _$AddCardModelCopyWithImpl<$Res, $Val extends AddCardModel>
    implements $AddCardModelCopyWith<$Res> {
  _$AddCardModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AddCardModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? cardType = null,
    Object? last4 = null,
    Object? expiryMonth = null,
    Object? expiryYear = null,
    Object? isDefault = null,
    Object? cardDetails = null,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      cardType: null == cardType
          ? _value.cardType
          : cardType // ignore: cast_nullable_to_non_nullable
              as String,
      last4: null == last4
          ? _value.last4
          : last4 // ignore: cast_nullable_to_non_nullable
              as String,
      expiryMonth: null == expiryMonth
          ? _value.expiryMonth
          : expiryMonth // ignore: cast_nullable_to_non_nullable
              as String,
      expiryYear: null == expiryYear
          ? _value.expiryYear
          : expiryYear // ignore: cast_nullable_to_non_nullable
              as String,
      isDefault: null == isDefault
          ? _value.isDefault
          : isDefault // ignore: cast_nullable_to_non_nullable
              as bool,
      cardDetails: null == cardDetails
          ? _value.cardDetails
          : cardDetails // ignore: cast_nullable_to_non_nullable
              as CardDetails,
    ) as $Val);
  }

  /// Create a copy of AddCardModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CardDetailsCopyWith<$Res> get cardDetails {
    return $CardDetailsCopyWith<$Res>(_value.cardDetails, (value) {
      return _then(_value.copyWith(cardDetails: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AddCardModelImplCopyWith<$Res>
    implements $AddCardModelCopyWith<$Res> {
  factory _$$AddCardModelImplCopyWith(
          _$AddCardModelImpl value, $Res Function(_$AddCardModelImpl) then) =
      __$$AddCardModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String type,
      String cardType,
      String last4,
      String expiryMonth,
      String expiryYear,
      bool isDefault,
      CardDetails cardDetails});

  @override
  $CardDetailsCopyWith<$Res> get cardDetails;
}

/// @nodoc
class __$$AddCardModelImplCopyWithImpl<$Res>
    extends _$AddCardModelCopyWithImpl<$Res, _$AddCardModelImpl>
    implements _$$AddCardModelImplCopyWith<$Res> {
  __$$AddCardModelImplCopyWithImpl(
      _$AddCardModelImpl _value, $Res Function(_$AddCardModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of AddCardModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? cardType = null,
    Object? last4 = null,
    Object? expiryMonth = null,
    Object? expiryYear = null,
    Object? isDefault = null,
    Object? cardDetails = null,
  }) {
    return _then(_$AddCardModelImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      cardType: null == cardType
          ? _value.cardType
          : cardType // ignore: cast_nullable_to_non_nullable
              as String,
      last4: null == last4
          ? _value.last4
          : last4 // ignore: cast_nullable_to_non_nullable
              as String,
      expiryMonth: null == expiryMonth
          ? _value.expiryMonth
          : expiryMonth // ignore: cast_nullable_to_non_nullable
              as String,
      expiryYear: null == expiryYear
          ? _value.expiryYear
          : expiryYear // ignore: cast_nullable_to_non_nullable
              as String,
      isDefault: null == isDefault
          ? _value.isDefault
          : isDefault // ignore: cast_nullable_to_non_nullable
              as bool,
      cardDetails: null == cardDetails
          ? _value.cardDetails
          : cardDetails // ignore: cast_nullable_to_non_nullable
              as CardDetails,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AddCardModelImpl implements _AddCardModel {
  const _$AddCardModelImpl(
      {required this.type,
      required this.cardType,
      required this.last4,
      required this.expiryMonth,
      required this.expiryYear,
      required this.isDefault,
      required this.cardDetails});

  factory _$AddCardModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AddCardModelImplFromJson(json);

  @override
  final String type;
  @override
  final String cardType;
  @override
  final String last4;
  @override
  final String expiryMonth;
  @override
  final String expiryYear;
  @override
  final bool isDefault;
  @override
  final CardDetails cardDetails;

  @override
  String toString() {
    return 'AddCardModel(type: $type, cardType: $cardType, last4: $last4, expiryMonth: $expiryMonth, expiryYear: $expiryYear, isDefault: $isDefault, cardDetails: $cardDetails)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AddCardModelImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.cardType, cardType) ||
                other.cardType == cardType) &&
            (identical(other.last4, last4) || other.last4 == last4) &&
            (identical(other.expiryMonth, expiryMonth) ||
                other.expiryMonth == expiryMonth) &&
            (identical(other.expiryYear, expiryYear) ||
                other.expiryYear == expiryYear) &&
            (identical(other.isDefault, isDefault) ||
                other.isDefault == isDefault) &&
            (identical(other.cardDetails, cardDetails) ||
                other.cardDetails == cardDetails));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, type, cardType, last4,
      expiryMonth, expiryYear, isDefault, cardDetails);

  /// Create a copy of AddCardModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AddCardModelImplCopyWith<_$AddCardModelImpl> get copyWith =>
      __$$AddCardModelImplCopyWithImpl<_$AddCardModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AddCardModelImplToJson(
      this,
    );
  }
}

abstract class _AddCardModel implements AddCardModel {
  const factory _AddCardModel(
      {required final String type,
      required final String cardType,
      required final String last4,
      required final String expiryMonth,
      required final String expiryYear,
      required final bool isDefault,
      required final CardDetails cardDetails}) = _$AddCardModelImpl;

  factory _AddCardModel.fromJson(Map<String, dynamic> json) =
      _$AddCardModelImpl.fromJson;

  @override
  String get type;
  @override
  String get cardType;
  @override
  String get last4;
  @override
  String get expiryMonth;
  @override
  String get expiryYear;
  @override
  bool get isDefault;
  @override
  CardDetails get cardDetails;

  /// Create a copy of AddCardModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AddCardModelImplCopyWith<_$AddCardModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CardDetails _$CardDetailsFromJson(Map<String, dynamic> json) {
  return _CardDetails.fromJson(json);
}

/// @nodoc
mixin _$CardDetails {
  @JsonKey(name: 'card_number')
  String get cardNumber => throw _privateConstructorUsedError;
  String get cvv => throw _privateConstructorUsedError;
  @JsonKey(name: 'expiry_month')
  String get expiryMonth => throw _privateConstructorUsedError;
  @JsonKey(name: 'expiry_year')
  String get expiryYear => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;

  /// Serializes this CardDetails to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CardDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CardDetailsCopyWith<CardDetails> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CardDetailsCopyWith<$Res> {
  factory $CardDetailsCopyWith(
          CardDetails value, $Res Function(CardDetails) then) =
      _$CardDetailsCopyWithImpl<$Res, CardDetails>;
  @useResult
  $Res call(
      {@JsonKey(name: 'card_number') String cardNumber,
      String cvv,
      @JsonKey(name: 'expiry_month') String expiryMonth,
      @JsonKey(name: 'expiry_year') String expiryYear,
      String currency});
}

/// @nodoc
class _$CardDetailsCopyWithImpl<$Res, $Val extends CardDetails>
    implements $CardDetailsCopyWith<$Res> {
  _$CardDetailsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CardDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cardNumber = null,
    Object? cvv = null,
    Object? expiryMonth = null,
    Object? expiryYear = null,
    Object? currency = null,
  }) {
    return _then(_value.copyWith(
      cardNumber: null == cardNumber
          ? _value.cardNumber
          : cardNumber // ignore: cast_nullable_to_non_nullable
              as String,
      cvv: null == cvv
          ? _value.cvv
          : cvv // ignore: cast_nullable_to_non_nullable
              as String,
      expiryMonth: null == expiryMonth
          ? _value.expiryMonth
          : expiryMonth // ignore: cast_nullable_to_non_nullable
              as String,
      expiryYear: null == expiryYear
          ? _value.expiryYear
          : expiryYear // ignore: cast_nullable_to_non_nullable
              as String,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CardDetailsImplCopyWith<$Res>
    implements $CardDetailsCopyWith<$Res> {
  factory _$$CardDetailsImplCopyWith(
          _$CardDetailsImpl value, $Res Function(_$CardDetailsImpl) then) =
      __$$CardDetailsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'card_number') String cardNumber,
      String cvv,
      @JsonKey(name: 'expiry_month') String expiryMonth,
      @JsonKey(name: 'expiry_year') String expiryYear,
      String currency});
}

/// @nodoc
class __$$CardDetailsImplCopyWithImpl<$Res>
    extends _$CardDetailsCopyWithImpl<$Res, _$CardDetailsImpl>
    implements _$$CardDetailsImplCopyWith<$Res> {
  __$$CardDetailsImplCopyWithImpl(
      _$CardDetailsImpl _value, $Res Function(_$CardDetailsImpl) _then)
      : super(_value, _then);

  /// Create a copy of CardDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cardNumber = null,
    Object? cvv = null,
    Object? expiryMonth = null,
    Object? expiryYear = null,
    Object? currency = null,
  }) {
    return _then(_$CardDetailsImpl(
      cardNumber: null == cardNumber
          ? _value.cardNumber
          : cardNumber // ignore: cast_nullable_to_non_nullable
              as String,
      cvv: null == cvv
          ? _value.cvv
          : cvv // ignore: cast_nullable_to_non_nullable
              as String,
      expiryMonth: null == expiryMonth
          ? _value.expiryMonth
          : expiryMonth // ignore: cast_nullable_to_non_nullable
              as String,
      expiryYear: null == expiryYear
          ? _value.expiryYear
          : expiryYear // ignore: cast_nullable_to_non_nullable
              as String,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CardDetailsImpl implements _CardDetails {
  const _$CardDetailsImpl(
      {@JsonKey(name: 'card_number') required this.cardNumber,
      required this.cvv,
      @JsonKey(name: 'expiry_month') required this.expiryMonth,
      @JsonKey(name: 'expiry_year') required this.expiryYear,
      required this.currency});

  factory _$CardDetailsImpl.fromJson(Map<String, dynamic> json) =>
      _$$CardDetailsImplFromJson(json);

  @override
  @JsonKey(name: 'card_number')
  final String cardNumber;
  @override
  final String cvv;
  @override
  @JsonKey(name: 'expiry_month')
  final String expiryMonth;
  @override
  @JsonKey(name: 'expiry_year')
  final String expiryYear;
  @override
  final String currency;

  @override
  String toString() {
    return 'CardDetails(cardNumber: $cardNumber, cvv: $cvv, expiryMonth: $expiryMonth, expiryYear: $expiryYear, currency: $currency)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CardDetailsImpl &&
            (identical(other.cardNumber, cardNumber) ||
                other.cardNumber == cardNumber) &&
            (identical(other.cvv, cvv) || other.cvv == cvv) &&
            (identical(other.expiryMonth, expiryMonth) ||
                other.expiryMonth == expiryMonth) &&
            (identical(other.expiryYear, expiryYear) ||
                other.expiryYear == expiryYear) &&
            (identical(other.currency, currency) ||
                other.currency == currency));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, cardNumber, cvv, expiryMonth, expiryYear, currency);

  /// Create a copy of CardDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CardDetailsImplCopyWith<_$CardDetailsImpl> get copyWith =>
      __$$CardDetailsImplCopyWithImpl<_$CardDetailsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CardDetailsImplToJson(
      this,
    );
  }
}

abstract class _CardDetails implements CardDetails {
  const factory _CardDetails(
      {@JsonKey(name: 'card_number') required final String cardNumber,
      required final String cvv,
      @JsonKey(name: 'expiry_month') required final String expiryMonth,
      @JsonKey(name: 'expiry_year') required final String expiryYear,
      required final String currency}) = _$CardDetailsImpl;

  factory _CardDetails.fromJson(Map<String, dynamic> json) =
      _$CardDetailsImpl.fromJson;

  @override
  @JsonKey(name: 'card_number')
  String get cardNumber;
  @override
  String get cvv;
  @override
  @JsonKey(name: 'expiry_month')
  String get expiryMonth;
  @override
  @JsonKey(name: 'expiry_year')
  String get expiryYear;
  @override
  String get currency;

  /// Create a copy of CardDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CardDetailsImplCopyWith<_$CardDetailsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
