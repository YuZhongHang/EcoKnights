// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'aqi_detail_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AqiDetailItem _$AqiDetailItemFromJson(Map<String, dynamic> json) {
  return _AqiDetailItem.fromJson(json);
}

/// @nodoc
mixin _$AqiDetailItem {
  @JsonKey(name: 'v')
  int get value => throw _privateConstructorUsedError;

  /// Serializes this AqiDetailItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AqiDetailItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AqiDetailItemCopyWith<AqiDetailItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AqiDetailItemCopyWith<$Res> {
  factory $AqiDetailItemCopyWith(
          AqiDetailItem value, $Res Function(AqiDetailItem) then) =
      _$AqiDetailItemCopyWithImpl<$Res, AqiDetailItem>;
  @useResult
  $Res call({@JsonKey(name: 'v') int value});
}

/// @nodoc
class _$AqiDetailItemCopyWithImpl<$Res, $Val extends AqiDetailItem>
    implements $AqiDetailItemCopyWith<$Res> {
  _$AqiDetailItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AqiDetailItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
  }) {
    return _then(_value.copyWith(
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AqiDetailItemImplCopyWith<$Res>
    implements $AqiDetailItemCopyWith<$Res> {
  factory _$$AqiDetailItemImplCopyWith(
          _$AqiDetailItemImpl value, $Res Function(_$AqiDetailItemImpl) then) =
      __$$AqiDetailItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'v') int value});
}

/// @nodoc
class __$$AqiDetailItemImplCopyWithImpl<$Res>
    extends _$AqiDetailItemCopyWithImpl<$Res, _$AqiDetailItemImpl>
    implements _$$AqiDetailItemImplCopyWith<$Res> {
  __$$AqiDetailItemImplCopyWithImpl(
      _$AqiDetailItemImpl _value, $Res Function(_$AqiDetailItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of AqiDetailItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
  }) {
    return _then(_$AqiDetailItemImpl(
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AqiDetailItemImpl implements _AqiDetailItem {
  const _$AqiDetailItemImpl({@JsonKey(name: 'v') required this.value});

  factory _$AqiDetailItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$AqiDetailItemImplFromJson(json);

  @override
  @JsonKey(name: 'v')
  final int value;

  @override
  String toString() {
    return 'AqiDetailItem(value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AqiDetailItemImpl &&
            (identical(other.value, value) || other.value == value));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, value);

  /// Create a copy of AqiDetailItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AqiDetailItemImplCopyWith<_$AqiDetailItemImpl> get copyWith =>
      __$$AqiDetailItemImplCopyWithImpl<_$AqiDetailItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AqiDetailItemImplToJson(
      this,
    );
  }
}

abstract class _AqiDetailItem implements AqiDetailItem {
  const factory _AqiDetailItem({@JsonKey(name: 'v') required final int value}) =
      _$AqiDetailItemImpl;

  factory _AqiDetailItem.fromJson(Map<String, dynamic> json) =
      _$AqiDetailItemImpl.fromJson;

  @override
  @JsonKey(name: 'v')
  int get value;

  /// Create a copy of AqiDetailItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AqiDetailItemImplCopyWith<_$AqiDetailItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
