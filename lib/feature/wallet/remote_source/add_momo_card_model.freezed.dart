// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'add_momo_card_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AddMomoCardModel _$AddMomoCardModelFromJson(Map<String, dynamic> json) {
  return _AddMomoCardModel.fromJson(json);
}

/// @nodoc
mixin _$AddMomoCardModel {
  String get momoProvider => throw _privateConstructorUsedError;
  String get momoNumber => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  bool get isDefault => throw _privateConstructorUsedError;

  /// Serializes this AddMomoCardModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AddMomoCardModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AddMomoCardModelCopyWith<AddMomoCardModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AddMomoCardModelCopyWith<$Res> {
  factory $AddMomoCardModelCopyWith(
          AddMomoCardModel value, $Res Function(AddMomoCardModel) then) =
      _$AddMomoCardModelCopyWithImpl<$Res, AddMomoCardModel>;
  @useResult
  $Res call(
      {String momoProvider, String momoNumber, String type, bool isDefault});
}

/// @nodoc
class _$AddMomoCardModelCopyWithImpl<$Res, $Val extends AddMomoCardModel>
    implements $AddMomoCardModelCopyWith<$Res> {
  _$AddMomoCardModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AddMomoCardModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? momoProvider = null,
    Object? momoNumber = null,
    Object? type = null,
    Object? isDefault = null,
  }) {
    return _then(_value.copyWith(
      momoProvider: null == momoProvider
          ? _value.momoProvider
          : momoProvider // ignore: cast_nullable_to_non_nullable
              as String,
      momoNumber: null == momoNumber
          ? _value.momoNumber
          : momoNumber // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      isDefault: null == isDefault
          ? _value.isDefault
          : isDefault // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AddMomoCardModelImplCopyWith<$Res>
    implements $AddMomoCardModelCopyWith<$Res> {
  factory _$$AddMomoCardModelImplCopyWith(_$AddMomoCardModelImpl value,
          $Res Function(_$AddMomoCardModelImpl) then) =
      __$$AddMomoCardModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String momoProvider, String momoNumber, String type, bool isDefault});
}

/// @nodoc
class __$$AddMomoCardModelImplCopyWithImpl<$Res>
    extends _$AddMomoCardModelCopyWithImpl<$Res, _$AddMomoCardModelImpl>
    implements _$$AddMomoCardModelImplCopyWith<$Res> {
  __$$AddMomoCardModelImplCopyWithImpl(_$AddMomoCardModelImpl _value,
      $Res Function(_$AddMomoCardModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of AddMomoCardModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? momoProvider = null,
    Object? momoNumber = null,
    Object? type = null,
    Object? isDefault = null,
  }) {
    return _then(_$AddMomoCardModelImpl(
      momoProvider: null == momoProvider
          ? _value.momoProvider
          : momoProvider // ignore: cast_nullable_to_non_nullable
              as String,
      momoNumber: null == momoNumber
          ? _value.momoNumber
          : momoNumber // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      isDefault: null == isDefault
          ? _value.isDefault
          : isDefault // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AddMomoCardModelImpl implements _AddMomoCardModel {
  const _$AddMomoCardModelImpl(
      {required this.momoProvider,
      required this.momoNumber,
      required this.type,
      required this.isDefault});

  factory _$AddMomoCardModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AddMomoCardModelImplFromJson(json);

  @override
  final String momoProvider;
  @override
  final String momoNumber;
  @override
  final String type;
  @override
  final bool isDefault;

  @override
  String toString() {
    return 'AddMomoCardModel(momoProvider: $momoProvider, momoNumber: $momoNumber, type: $type, isDefault: $isDefault)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AddMomoCardModelImpl &&
            (identical(other.momoProvider, momoProvider) ||
                other.momoProvider == momoProvider) &&
            (identical(other.momoNumber, momoNumber) ||
                other.momoNumber == momoNumber) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.isDefault, isDefault) ||
                other.isDefault == isDefault));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, momoProvider, momoNumber, type, isDefault);

  /// Create a copy of AddMomoCardModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AddMomoCardModelImplCopyWith<_$AddMomoCardModelImpl> get copyWith =>
      __$$AddMomoCardModelImplCopyWithImpl<_$AddMomoCardModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AddMomoCardModelImplToJson(
      this,
    );
  }
}

abstract class _AddMomoCardModel implements AddMomoCardModel {
  const factory _AddMomoCardModel(
      {required final String momoProvider,
      required final String momoNumber,
      required final String type,
      required final bool isDefault}) = _$AddMomoCardModelImpl;

  factory _AddMomoCardModel.fromJson(Map<String, dynamic> json) =
      _$AddMomoCardModelImpl.fromJson;

  @override
  String get momoProvider;
  @override
  String get momoNumber;
  @override
  String get type;
  @override
  bool get isDefault;

  /// Create a copy of AddMomoCardModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AddMomoCardModelImplCopyWith<_$AddMomoCardModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
