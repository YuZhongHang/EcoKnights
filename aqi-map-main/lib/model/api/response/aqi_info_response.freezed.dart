// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'aqi_info_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AqiInfoResponse _$AqiInfoResponseFromJson(Map<String, dynamic> json) {
  return _AqiInfoResponse.fromJson(json);
}

/// @nodoc
mixin _$AqiInfoResponse {
  @JsonKey(name: 'status')
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'data')
  AqiInfo get aqiInfo => throw _privateConstructorUsedError;

  /// Serializes this AqiInfoResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AqiInfoResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AqiInfoResponseCopyWith<AqiInfoResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AqiInfoResponseCopyWith<$Res> {
  factory $AqiInfoResponseCopyWith(
          AqiInfoResponse value, $Res Function(AqiInfoResponse) then) =
      _$AqiInfoResponseCopyWithImpl<$Res, AqiInfoResponse>;
  @useResult
  $Res call(
      {@JsonKey(name: 'status') String status,
      @JsonKey(name: 'data') AqiInfo aqiInfo});

  $AqiInfoCopyWith<$Res> get aqiInfo;
}

/// @nodoc
class _$AqiInfoResponseCopyWithImpl<$Res, $Val extends AqiInfoResponse>
    implements $AqiInfoResponseCopyWith<$Res> {
  _$AqiInfoResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AqiInfoResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? aqiInfo = null,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      aqiInfo: null == aqiInfo
          ? _value.aqiInfo
          : aqiInfo // ignore: cast_nullable_to_non_nullable
              as AqiInfo,
    ) as $Val);
  }

  /// Create a copy of AqiInfoResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AqiInfoCopyWith<$Res> get aqiInfo {
    return $AqiInfoCopyWith<$Res>(_value.aqiInfo, (value) {
      return _then(_value.copyWith(aqiInfo: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AqiInfoResponseImplCopyWith<$Res>
    implements $AqiInfoResponseCopyWith<$Res> {
  factory _$$AqiInfoResponseImplCopyWith(_$AqiInfoResponseImpl value,
          $Res Function(_$AqiInfoResponseImpl) then) =
      __$$AqiInfoResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'status') String status,
      @JsonKey(name: 'data') AqiInfo aqiInfo});

  @override
  $AqiInfoCopyWith<$Res> get aqiInfo;
}

/// @nodoc
class __$$AqiInfoResponseImplCopyWithImpl<$Res>
    extends _$AqiInfoResponseCopyWithImpl<$Res, _$AqiInfoResponseImpl>
    implements _$$AqiInfoResponseImplCopyWith<$Res> {
  __$$AqiInfoResponseImplCopyWithImpl(
      _$AqiInfoResponseImpl _value, $Res Function(_$AqiInfoResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of AqiInfoResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? aqiInfo = null,
  }) {
    return _then(_$AqiInfoResponseImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      aqiInfo: null == aqiInfo
          ? _value.aqiInfo
          : aqiInfo // ignore: cast_nullable_to_non_nullable
              as AqiInfo,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AqiInfoResponseImpl implements _AqiInfoResponse {
  const _$AqiInfoResponseImpl(
      {@JsonKey(name: 'status') required this.status,
      @JsonKey(name: 'data') required this.aqiInfo});

  factory _$AqiInfoResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AqiInfoResponseImplFromJson(json);

  @override
  @JsonKey(name: 'status')
  final String status;
  @override
  @JsonKey(name: 'data')
  final AqiInfo aqiInfo;

  @override
  String toString() {
    return 'AqiInfoResponse(status: $status, aqiInfo: $aqiInfo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AqiInfoResponseImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.aqiInfo, aqiInfo) || other.aqiInfo == aqiInfo));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, status, aqiInfo);

  /// Create a copy of AqiInfoResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AqiInfoResponseImplCopyWith<_$AqiInfoResponseImpl> get copyWith =>
      __$$AqiInfoResponseImplCopyWithImpl<_$AqiInfoResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AqiInfoResponseImplToJson(
      this,
    );
  }
}

abstract class _AqiInfoResponse implements AqiInfoResponse {
  const factory _AqiInfoResponse(
          {@JsonKey(name: 'status') required final String status,
          @JsonKey(name: 'data') required final AqiInfo aqiInfo}) =
      _$AqiInfoResponseImpl;

  factory _AqiInfoResponse.fromJson(Map<String, dynamic> json) =
      _$AqiInfoResponseImpl.fromJson;

  @override
  @JsonKey(name: 'status')
  String get status;
  @override
  @JsonKey(name: 'data')
  AqiInfo get aqiInfo;

  /// Create a copy of AqiInfoResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AqiInfoResponseImplCopyWith<_$AqiInfoResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
