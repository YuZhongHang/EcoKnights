// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'aqi_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AqiInfo _$AqiInfoFromJson(Map<String, dynamic> json) {
  return _AqiInfo.fromJson(json);
}

/// @nodoc
mixin _$AqiInfo {
  @JsonKey(name: 'city')
  City get city => throw _privateConstructorUsedError;
  @JsonKey(name: 'aqi')
  int get aqi => throw _privateConstructorUsedError;
  @JsonKey(name: 'iaqi')
  AqiDetail get aqiDetail => throw _privateConstructorUsedError;

  /// Serializes this AqiInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AqiInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AqiInfoCopyWith<AqiInfo> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AqiInfoCopyWith<$Res> {
  factory $AqiInfoCopyWith(AqiInfo value, $Res Function(AqiInfo) then) =
      _$AqiInfoCopyWithImpl<$Res, AqiInfo>;
  @useResult
  $Res call(
      {@JsonKey(name: 'city') City city,
      @JsonKey(name: 'aqi') int aqi,
      @JsonKey(name: 'iaqi') AqiDetail aqiDetail});

  $CityCopyWith<$Res> get city;
  $AqiDetailCopyWith<$Res> get aqiDetail;
}

/// @nodoc
class _$AqiInfoCopyWithImpl<$Res, $Val extends AqiInfo>
    implements $AqiInfoCopyWith<$Res> {
  _$AqiInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AqiInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? city = null,
    Object? aqi = null,
    Object? aqiDetail = null,
  }) {
    return _then(_value.copyWith(
      city: null == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as City,
      aqi: null == aqi
          ? _value.aqi
          : aqi // ignore: cast_nullable_to_non_nullable
              as int,
      aqiDetail: null == aqiDetail
          ? _value.aqiDetail
          : aqiDetail // ignore: cast_nullable_to_non_nullable
              as AqiDetail,
    ) as $Val);
  }

  /// Create a copy of AqiInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CityCopyWith<$Res> get city {
    return $CityCopyWith<$Res>(_value.city, (value) {
      return _then(_value.copyWith(city: value) as $Val);
    });
  }

  /// Create a copy of AqiInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AqiDetailCopyWith<$Res> get aqiDetail {
    return $AqiDetailCopyWith<$Res>(_value.aqiDetail, (value) {
      return _then(_value.copyWith(aqiDetail: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AqiInfoImplCopyWith<$Res> implements $AqiInfoCopyWith<$Res> {
  factory _$$AqiInfoImplCopyWith(
          _$AqiInfoImpl value, $Res Function(_$AqiInfoImpl) then) =
      __$$AqiInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'city') City city,
      @JsonKey(name: 'aqi') int aqi,
      @JsonKey(name: 'iaqi') AqiDetail aqiDetail});

  @override
  $CityCopyWith<$Res> get city;
  @override
  $AqiDetailCopyWith<$Res> get aqiDetail;
}

/// @nodoc
class __$$AqiInfoImplCopyWithImpl<$Res>
    extends _$AqiInfoCopyWithImpl<$Res, _$AqiInfoImpl>
    implements _$$AqiInfoImplCopyWith<$Res> {
  __$$AqiInfoImplCopyWithImpl(
      _$AqiInfoImpl _value, $Res Function(_$AqiInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of AqiInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? city = null,
    Object? aqi = null,
    Object? aqiDetail = null,
  }) {
    return _then(_$AqiInfoImpl(
      city: null == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as City,
      aqi: null == aqi
          ? _value.aqi
          : aqi // ignore: cast_nullable_to_non_nullable
              as int,
      aqiDetail: null == aqiDetail
          ? _value.aqiDetail
          : aqiDetail // ignore: cast_nullable_to_non_nullable
              as AqiDetail,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AqiInfoImpl implements _AqiInfo {
  const _$AqiInfoImpl(
      {@JsonKey(name: 'city') required this.city,
      @JsonKey(name: 'aqi') required this.aqi,
      @JsonKey(name: 'iaqi') required this.aqiDetail});

  factory _$AqiInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$AqiInfoImplFromJson(json);

  @override
  @JsonKey(name: 'city')
  final City city;
  @override
  @JsonKey(name: 'aqi')
  final int aqi;
  @override
  @JsonKey(name: 'iaqi')
  final AqiDetail aqiDetail;

  @override
  String toString() {
    return 'AqiInfo(city: $city, aqi: $aqi, aqiDetail: $aqiDetail)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AqiInfoImpl &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.aqi, aqi) || other.aqi == aqi) &&
            (identical(other.aqiDetail, aqiDetail) ||
                other.aqiDetail == aqiDetail));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, city, aqi, aqiDetail);

  /// Create a copy of AqiInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AqiInfoImplCopyWith<_$AqiInfoImpl> get copyWith =>
      __$$AqiInfoImplCopyWithImpl<_$AqiInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AqiInfoImplToJson(
      this,
    );
  }
}

abstract class _AqiInfo implements AqiInfo {
  const factory _AqiInfo(
          {@JsonKey(name: 'city') required final City city,
          @JsonKey(name: 'aqi') required final int aqi,
          @JsonKey(name: 'iaqi') required final AqiDetail aqiDetail}) =
      _$AqiInfoImpl;

  factory _AqiInfo.fromJson(Map<String, dynamic> json) = _$AqiInfoImpl.fromJson;

  @override
  @JsonKey(name: 'city')
  City get city;
  @override
  @JsonKey(name: 'aqi')
  int get aqi;
  @override
  @JsonKey(name: 'iaqi')
  AqiDetail get aqiDetail;

  /// Create a copy of AqiInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AqiInfoImplCopyWith<_$AqiInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
