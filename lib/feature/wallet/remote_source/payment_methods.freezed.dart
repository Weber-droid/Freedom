// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_methods.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserPaymentMethodsResponse _$UserPaymentMethodsResponseFromJson(
    Map<String, dynamic> json) {
  return _UserPaymentMethodsResponse.fromJson(json);
}

/// @nodoc
mixin _$UserPaymentMethodsResponse {
  bool get success => throw _privateConstructorUsedError;
  List<PaymentMethod> get data => throw _privateConstructorUsedError;

  /// Serializes this UserPaymentMethodsResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserPaymentMethodsResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserPaymentMethodsResponseCopyWith<UserPaymentMethodsResponse>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserPaymentMethodsResponseCopyWith<$Res> {
  factory $UserPaymentMethodsResponseCopyWith(UserPaymentMethodsResponse value,
          $Res Function(UserPaymentMethodsResponse) then) =
      _$UserPaymentMethodsResponseCopyWithImpl<$Res,
          UserPaymentMethodsResponse>;
  @useResult
  $Res call({bool success, List<PaymentMethod> data});
}

/// @nodoc
class _$UserPaymentMethodsResponseCopyWithImpl<$Res,
        $Val extends UserPaymentMethodsResponse>
    implements $UserPaymentMethodsResponseCopyWith<$Res> {
  _$UserPaymentMethodsResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserPaymentMethodsResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? data = null,
  }) {
    return _then(_value.copyWith(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as List<PaymentMethod>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserPaymentMethodsResponseImplCopyWith<$Res>
    implements $UserPaymentMethodsResponseCopyWith<$Res> {
  factory _$$UserPaymentMethodsResponseImplCopyWith(
          _$UserPaymentMethodsResponseImpl value,
          $Res Function(_$UserPaymentMethodsResponseImpl) then) =
      __$$UserPaymentMethodsResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool success, List<PaymentMethod> data});
}

/// @nodoc
class __$$UserPaymentMethodsResponseImplCopyWithImpl<$Res>
    extends _$UserPaymentMethodsResponseCopyWithImpl<$Res,
        _$UserPaymentMethodsResponseImpl>
    implements _$$UserPaymentMethodsResponseImplCopyWith<$Res> {
  __$$UserPaymentMethodsResponseImplCopyWithImpl(
      _$UserPaymentMethodsResponseImpl _value,
      $Res Function(_$UserPaymentMethodsResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserPaymentMethodsResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? data = null,
  }) {
    return _then(_$UserPaymentMethodsResponseImpl(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      data: null == data
          ? _value._data
          : data // ignore: cast_nullable_to_non_nullable
              as List<PaymentMethod>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserPaymentMethodsResponseImpl implements _UserPaymentMethodsResponse {
  const _$UserPaymentMethodsResponseImpl(
      {required this.success, required final List<PaymentMethod> data})
      : _data = data;

  factory _$UserPaymentMethodsResponseImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$UserPaymentMethodsResponseImplFromJson(json);

  @override
  final bool success;
  final List<PaymentMethod> _data;
  @override
  List<PaymentMethod> get data {
    if (_data is EqualUnmodifiableListView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_data);
  }

  @override
  String toString() {
    return 'UserPaymentMethodsResponse(success: $success, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserPaymentMethodsResponseImpl &&
            (identical(other.success, success) || other.success == success) &&
            const DeepCollectionEquality().equals(other._data, _data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, success, const DeepCollectionEquality().hash(_data));

  /// Create a copy of UserPaymentMethodsResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserPaymentMethodsResponseImplCopyWith<_$UserPaymentMethodsResponseImpl>
      get copyWith => __$$UserPaymentMethodsResponseImplCopyWithImpl<
          _$UserPaymentMethodsResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserPaymentMethodsResponseImplToJson(
      this,
    );
  }
}

abstract class _UserPaymentMethodsResponse
    implements UserPaymentMethodsResponse {
  const factory _UserPaymentMethodsResponse(
          {required final bool success,
          required final List<PaymentMethod> data}) =
      _$UserPaymentMethodsResponseImpl;

  factory _UserPaymentMethodsResponse.fromJson(Map<String, dynamic> json) =
      _$UserPaymentMethodsResponseImpl.fromJson;

  @override
  bool get success;
  @override
  List<PaymentMethod> get data;

  /// Create a copy of UserPaymentMethodsResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserPaymentMethodsResponseImplCopyWith<_$UserPaymentMethodsResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

PaymentMethod _$PaymentMethodFromJson(Map<String, dynamic> json) {
  switch (json['type']) {
    case 'card':
      return CardPaymentMethod.fromJson(json);
    case 'momo':
      return MomoPaymentMethod.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'type', 'PaymentMethod',
          'Invalid union type "${json['type']}"!');
  }
}

/// @nodoc
mixin _$PaymentMethod {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  bool get isDefault => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String id,
            String userId,
            String type,
            String cardType,
            String last4,
            String expiryMonth,
            String expiryYear,
            bool isDefault,
            DateTime createdAt,
            String? token)
        card,
    required TResult Function(
            String id,
            String userId,
            String type,
            String momoProvider,
            String momoNumber,
            bool isDefault,
            DateTime createdAt)
        momo,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String id,
            String userId,
            String type,
            String cardType,
            String last4,
            String expiryMonth,
            String expiryYear,
            bool isDefault,
            DateTime createdAt,
            String? token)?
        card,
    TResult? Function(
            String id,
            String userId,
            String type,
            String momoProvider,
            String momoNumber,
            bool isDefault,
            DateTime createdAt)?
        momo,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String id,
            String userId,
            String type,
            String cardType,
            String last4,
            String expiryMonth,
            String expiryYear,
            bool isDefault,
            DateTime createdAt,
            String? token)?
        card,
    TResult Function(String id, String userId, String type, String momoProvider,
            String momoNumber, bool isDefault, DateTime createdAt)?
        momo,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CardPaymentMethod value) card,
    required TResult Function(MomoPaymentMethod value) momo,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CardPaymentMethod value)? card,
    TResult? Function(MomoPaymentMethod value)? momo,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CardPaymentMethod value)? card,
    TResult Function(MomoPaymentMethod value)? momo,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this PaymentMethod to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PaymentMethod
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaymentMethodCopyWith<PaymentMethod> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentMethodCopyWith<$Res> {
  factory $PaymentMethodCopyWith(
          PaymentMethod value, $Res Function(PaymentMethod) then) =
      _$PaymentMethodCopyWithImpl<$Res, PaymentMethod>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String type,
      bool isDefault,
      DateTime createdAt});
}

/// @nodoc
class _$PaymentMethodCopyWithImpl<$Res, $Val extends PaymentMethod>
    implements $PaymentMethodCopyWith<$Res> {
  _$PaymentMethodCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PaymentMethod
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? type = null,
    Object? isDefault = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      isDefault: null == isDefault
          ? _value.isDefault
          : isDefault // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CardPaymentMethodImplCopyWith<$Res>
    implements $PaymentMethodCopyWith<$Res> {
  factory _$$CardPaymentMethodImplCopyWith(_$CardPaymentMethodImpl value,
          $Res Function(_$CardPaymentMethodImpl) then) =
      __$$CardPaymentMethodImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String type,
      String cardType,
      String last4,
      String expiryMonth,
      String expiryYear,
      bool isDefault,
      DateTime createdAt,
      String? token});
}

/// @nodoc
class __$$CardPaymentMethodImplCopyWithImpl<$Res>
    extends _$PaymentMethodCopyWithImpl<$Res, _$CardPaymentMethodImpl>
    implements _$$CardPaymentMethodImplCopyWith<$Res> {
  __$$CardPaymentMethodImplCopyWithImpl(_$CardPaymentMethodImpl _value,
      $Res Function(_$CardPaymentMethodImpl) _then)
      : super(_value, _then);

  /// Create a copy of PaymentMethod
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? type = null,
    Object? cardType = null,
    Object? last4 = null,
    Object? expiryMonth = null,
    Object? expiryYear = null,
    Object? isDefault = null,
    Object? createdAt = null,
    Object? token = freezed,
  }) {
    return _then(_$CardPaymentMethodImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
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
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      token: freezed == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CardPaymentMethodImpl implements CardPaymentMethod {
  const _$CardPaymentMethodImpl(
      {required this.id,
      required this.userId,
      required this.type,
      required this.cardType,
      required this.last4,
      required this.expiryMonth,
      required this.expiryYear,
      required this.isDefault,
      required this.createdAt,
      this.token});

  factory _$CardPaymentMethodImpl.fromJson(Map<String, dynamic> json) =>
      _$$CardPaymentMethodImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
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
  final DateTime createdAt;
  @override
  final String? token;

  @override
  String toString() {
    return 'PaymentMethod.card(id: $id, userId: $userId, type: $type, cardType: $cardType, last4: $last4, expiryMonth: $expiryMonth, expiryYear: $expiryYear, isDefault: $isDefault, createdAt: $createdAt, token: $token)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CardPaymentMethodImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
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
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.token, token) || other.token == token));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, type, cardType,
      last4, expiryMonth, expiryYear, isDefault, createdAt, token);

  /// Create a copy of PaymentMethod
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CardPaymentMethodImplCopyWith<_$CardPaymentMethodImpl> get copyWith =>
      __$$CardPaymentMethodImplCopyWithImpl<_$CardPaymentMethodImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String id,
            String userId,
            String type,
            String cardType,
            String last4,
            String expiryMonth,
            String expiryYear,
            bool isDefault,
            DateTime createdAt,
            String? token)
        card,
    required TResult Function(
            String id,
            String userId,
            String type,
            String momoProvider,
            String momoNumber,
            bool isDefault,
            DateTime createdAt)
        momo,
  }) {
    return card(id, userId, type, cardType, last4, expiryMonth, expiryYear,
        isDefault, createdAt, token);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String id,
            String userId,
            String type,
            String cardType,
            String last4,
            String expiryMonth,
            String expiryYear,
            bool isDefault,
            DateTime createdAt,
            String? token)?
        card,
    TResult? Function(
            String id,
            String userId,
            String type,
            String momoProvider,
            String momoNumber,
            bool isDefault,
            DateTime createdAt)?
        momo,
  }) {
    return card?.call(id, userId, type, cardType, last4, expiryMonth,
        expiryYear, isDefault, createdAt, token);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String id,
            String userId,
            String type,
            String cardType,
            String last4,
            String expiryMonth,
            String expiryYear,
            bool isDefault,
            DateTime createdAt,
            String? token)?
        card,
    TResult Function(String id, String userId, String type, String momoProvider,
            String momoNumber, bool isDefault, DateTime createdAt)?
        momo,
    required TResult orElse(),
  }) {
    if (card != null) {
      return card(id, userId, type, cardType, last4, expiryMonth, expiryYear,
          isDefault, createdAt, token);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CardPaymentMethod value) card,
    required TResult Function(MomoPaymentMethod value) momo,
  }) {
    return card(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CardPaymentMethod value)? card,
    TResult? Function(MomoPaymentMethod value)? momo,
  }) {
    return card?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CardPaymentMethod value)? card,
    TResult Function(MomoPaymentMethod value)? momo,
    required TResult orElse(),
  }) {
    if (card != null) {
      return card(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$CardPaymentMethodImplToJson(
      this,
    );
  }
}

abstract class CardPaymentMethod implements PaymentMethod {
  const factory CardPaymentMethod(
      {required final String id,
      required final String userId,
      required final String type,
      required final String cardType,
      required final String last4,
      required final String expiryMonth,
      required final String expiryYear,
      required final bool isDefault,
      required final DateTime createdAt,
      final String? token}) = _$CardPaymentMethodImpl;

  factory CardPaymentMethod.fromJson(Map<String, dynamic> json) =
      _$CardPaymentMethodImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get type;
  String get cardType;
  String get last4;
  String get expiryMonth;
  String get expiryYear;
  @override
  bool get isDefault;
  @override
  DateTime get createdAt;
  String? get token;

  /// Create a copy of PaymentMethod
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CardPaymentMethodImplCopyWith<_$CardPaymentMethodImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MomoPaymentMethodImplCopyWith<$Res>
    implements $PaymentMethodCopyWith<$Res> {
  factory _$$MomoPaymentMethodImplCopyWith(_$MomoPaymentMethodImpl value,
          $Res Function(_$MomoPaymentMethodImpl) then) =
      __$$MomoPaymentMethodImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String type,
      String momoProvider,
      String momoNumber,
      bool isDefault,
      DateTime createdAt});
}

/// @nodoc
class __$$MomoPaymentMethodImplCopyWithImpl<$Res>
    extends _$PaymentMethodCopyWithImpl<$Res, _$MomoPaymentMethodImpl>
    implements _$$MomoPaymentMethodImplCopyWith<$Res> {
  __$$MomoPaymentMethodImplCopyWithImpl(_$MomoPaymentMethodImpl _value,
      $Res Function(_$MomoPaymentMethodImpl) _then)
      : super(_value, _then);

  /// Create a copy of PaymentMethod
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? type = null,
    Object? momoProvider = null,
    Object? momoNumber = null,
    Object? isDefault = null,
    Object? createdAt = null,
  }) {
    return _then(_$MomoPaymentMethodImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      momoProvider: null == momoProvider
          ? _value.momoProvider
          : momoProvider // ignore: cast_nullable_to_non_nullable
              as String,
      momoNumber: null == momoNumber
          ? _value.momoNumber
          : momoNumber // ignore: cast_nullable_to_non_nullable
              as String,
      isDefault: null == isDefault
          ? _value.isDefault
          : isDefault // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MomoPaymentMethodImpl implements MomoPaymentMethod {
  const _$MomoPaymentMethodImpl(
      {required this.id,
      required this.userId,
      required this.type,
      required this.momoProvider,
      required this.momoNumber,
      required this.isDefault,
      required this.createdAt});

  factory _$MomoPaymentMethodImpl.fromJson(Map<String, dynamic> json) =>
      _$$MomoPaymentMethodImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String type;
  @override
  final String momoProvider;
  @override
  final String momoNumber;
  @override
  final bool isDefault;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'PaymentMethod.momo(id: $id, userId: $userId, type: $type, momoProvider: $momoProvider, momoNumber: $momoNumber, isDefault: $isDefault, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MomoPaymentMethodImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.momoProvider, momoProvider) ||
                other.momoProvider == momoProvider) &&
            (identical(other.momoNumber, momoNumber) ||
                other.momoNumber == momoNumber) &&
            (identical(other.isDefault, isDefault) ||
                other.isDefault == isDefault) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, type, momoProvider,
      momoNumber, isDefault, createdAt);

  /// Create a copy of PaymentMethod
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MomoPaymentMethodImplCopyWith<_$MomoPaymentMethodImpl> get copyWith =>
      __$$MomoPaymentMethodImplCopyWithImpl<_$MomoPaymentMethodImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String id,
            String userId,
            String type,
            String cardType,
            String last4,
            String expiryMonth,
            String expiryYear,
            bool isDefault,
            DateTime createdAt,
            String? token)
        card,
    required TResult Function(
            String id,
            String userId,
            String type,
            String momoProvider,
            String momoNumber,
            bool isDefault,
            DateTime createdAt)
        momo,
  }) {
    return momo(
        id, userId, type, momoProvider, momoNumber, isDefault, createdAt);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String id,
            String userId,
            String type,
            String cardType,
            String last4,
            String expiryMonth,
            String expiryYear,
            bool isDefault,
            DateTime createdAt,
            String? token)?
        card,
    TResult? Function(
            String id,
            String userId,
            String type,
            String momoProvider,
            String momoNumber,
            bool isDefault,
            DateTime createdAt)?
        momo,
  }) {
    return momo?.call(
        id, userId, type, momoProvider, momoNumber, isDefault, createdAt);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String id,
            String userId,
            String type,
            String cardType,
            String last4,
            String expiryMonth,
            String expiryYear,
            bool isDefault,
            DateTime createdAt,
            String? token)?
        card,
    TResult Function(String id, String userId, String type, String momoProvider,
            String momoNumber, bool isDefault, DateTime createdAt)?
        momo,
    required TResult orElse(),
  }) {
    if (momo != null) {
      return momo(
          id, userId, type, momoProvider, momoNumber, isDefault, createdAt);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CardPaymentMethod value) card,
    required TResult Function(MomoPaymentMethod value) momo,
  }) {
    return momo(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CardPaymentMethod value)? card,
    TResult? Function(MomoPaymentMethod value)? momo,
  }) {
    return momo?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CardPaymentMethod value)? card,
    TResult Function(MomoPaymentMethod value)? momo,
    required TResult orElse(),
  }) {
    if (momo != null) {
      return momo(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$MomoPaymentMethodImplToJson(
      this,
    );
  }
}

abstract class MomoPaymentMethod implements PaymentMethod {
  const factory MomoPaymentMethod(
      {required final String id,
      required final String userId,
      required final String type,
      required final String momoProvider,
      required final String momoNumber,
      required final bool isDefault,
      required final DateTime createdAt}) = _$MomoPaymentMethodImpl;

  factory MomoPaymentMethod.fromJson(Map<String, dynamic> json) =
      _$MomoPaymentMethodImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get type;
  String get momoProvider;
  String get momoNumber;
  @override
  bool get isDefault;
  @override
  DateTime get createdAt;

  /// Create a copy of PaymentMethod
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MomoPaymentMethodImplCopyWith<_$MomoPaymentMethodImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
