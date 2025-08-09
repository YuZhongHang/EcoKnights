// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'aqi_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AqiDetail _$AqiDetailFromJson(Map<String, dynamic> json) {
  return _AqiDetail.fromJson(json);
}

/// @nodoc
mixin _$AqiDetail {
  @JsonKey(name: 'co')
  AqiDetailItem get co => throw _privateConstructorUsedError;
  @JsonKey(name: 'no2')
  AqiDetailItem get no2 => throw _privateConstructorUsedError;
  @JsonKey(name: 'o3')
  AqiDetailItem get o3 => throw _privateConstructorUsedError;
  @JsonKey(name: 'so2')
  AqiDetailItem get so2 => throw _privateConstructorUsedError;
  @JsonKey(name: 'pm25')
  AqiDetailItem get pm25 => throw _privateConstructorUsedError;

  /// Serializes this AqiDetail to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AqiDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AqiDetailCopyWith<AqiDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AqiDetailCopyWith<$Res> {
  factory $AqiDetailCopyWith(AqiDetail value, $Res Function(AqiDetail) then) =
      _$AqiDetailCopyWithImpl<$Res, AqiDetail>;
  @useResult
  $Res call(
      {@JsonKey(name: 'co') AqiDetailItem co,
      @JsonKey(name: 'no2') AqiDetailItem no2,
      @JsonKey(name: 'o3') AqiDetailItem o3,
      @JsonKey(name: 'so2') AqiDetailItem so2,
      @JsonKey(name: 'pm25') AqiDetailItem pm25});

  $AqiDetailItemCopyWith<$Res> get co;
  $AqiDetailItemCopyWith<$Res> get no2;
  $AqiDetailItemCopyWith<$Res> get o3;
  $AqiDetailItemCopyWith<$Res> get so2;
  $AqiDetailItemCopyWith<$Res> get pm25;
}

/// @nodoc
class _$AqiDetailCopyWithImpl<$Res, $Val extends AqiDetail>
    implements $AqiDetailCopyWith<$Res> {
  _$AqiDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AqiDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? co = null,
    Object? no2 = null,
    Object? o3 = null,
    Object? so2 = null,
    Object? pm25 = null,
  }) {
    return _then(_value.copyWith(
      co: null == co
          ? _value.co
          : co // ignore: cast_nullable_to_non_nullable
              as AqiDetailItem,
      no2: null == no2
          ? _value.no2
          : no2 // ignore: cast_nullable_to_non_nullable
              as AqiDetailItem,
      o3: null == o3
          ? _value.o3
          : o3 // ignore: cast_nullable_to_non_nullable
              as AqiDetailItem,
      so2: null == so2
          ? _value.so2
          : so2 // ignore: cast_nullable_to_non_nullable
              as AqiDetailItem,
      pm25: null == pm25
          ? _value.pm25
          : pm25 // ignore: cast_nullable_to_non_nullable
              as AqiDetailItem,
    ) as $Val);
  }

  /// Create a copy of AqiDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AqiDetailItemCopyWith<$Res> get co {
    return $AqiDetailItemCopyWith<$Res>(_value.co, (value) {
      return _then(_value.copyWith(co: value) as $Val);
    });
  }

  /// Create a copy of AqiDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AqiDetailItemCopyWith<$Res> get no2 {
    return $AqiDetailItemCopyWith<$Res>(_value.no2, (value) {
      return _then(_value.copyWith(no2: value) as $Val);
    });
  }

  /// Create a copy of AqiDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AqiDetailItemCopyWith<$Res> get o3 {
    return $AqiDetailItemCopyWith<$Res>(_value.o3, (value) {
      return _then(_value.copyWith(o3: value) as $Val);
    });
  }

  /// Create a copy of AqiDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AqiDetailItemCopyWith<$Res> get so2 {
    return $AqiDetailItemCopyWith<$Res>(_value.so2, (value) {
      return _then(_value.copyWith(so2: value) as $Val);
    });
  }

  /// Create a copy of AqiDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AqiDetailItemCopyWith<$Res> get pm25 {
    return $AqiDetailItemCopyWith<$Res>(_value.pm25, (value) {
      return _then(_value.copyWith(pm25: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AqiDetailImplCopyWith<$Res>
    implements $AqiDetailCopyWith<$Res> {
  factory _$$AqiDetailImplCopyWith(
          _$AqiDetailImpl value, $Res Function(_$AqiDetailImpl) then) =
      __$$AqiDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'co') AqiDetailItem co,
      @JsonKey(name: 'no2') AqiDetailItem no2,
      @JsonKey(name: 'o3') AqiDetailItem o3,
      @JsonKey(name: 'so2') AqiDetailItem so2,
      @JsonKey(name: 'pm25') AqiDetailItem pm25});

  @override
  $AqiDetailItemCopyWith<$Res> get co;
  @override
  $AqiDetailItemCopyWith<$Res> get no2;
  @override
  $AqiDetailItemCopyWith<$Res> get o3;
  @override
  $AqiDetailItemCopyWith<$Res> get so2;
  @override
  $AqiDetailItemCopyWith<$Res> get pm25;
}

/// @nodoc
class __$$AqiDetailImplCopyWithImpl<$Res>
    extends _$AqiDetailCopyWithImpl<$Res, _$AqiDetailImpl>
    implements _$$AqiDetailImplCopyWith<$Res> {
  __$$AqiDetailImplCopyWithImpl(
      _$AqiDetailImpl _value, $Res Function(_$AqiDetailImpl) _then)
      : super(_value, _then);

  /// Create a copy of AqiDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? co = null,
    Object? no2 = null,
    Object? o3 = null,
    Object? so2 = null,
    Object? pm25 = null,
  }) {
    return _then(_$AqiDetailImpl(
      co: null == co
          ? _value.co
          : co // ignore: cast_nullable_to_non_nullable
              as AqiDetailItem,
      no2: null == no2
          ? _value.no2
          : no2 // ignore: cast_nullable_to_non_nullable
              as AqiDetailItem,
      o3: null == o3
          ? _value.o3
          : o3 // ignore: cast_nullable_to_non_nullable
              as AqiDetailItem,
      so2: null == so2
          ? _value.so2
          : so2 // ignore: cast_nullable_to_non_nullable
              as AqiDetailItem,
      pm25: null == pm25
          ? _value.pm25
          : pm25 // ignore: cast_nullable_to_non_nullable
              as AqiDetailItem,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AqiDetailImpl implements _AqiDetail {
  const _$AqiDetailImpl(
      {@JsonKey(name: 'co') required this.co,
      @JsonKey(name: 'no2') required this.no2,
      @JsonKey(name: 'o3') required this.o3,
      @JsonKey(name: 'so2') required this.so2,
      @JsonKey(name: 'pm25') required this.pm25});

  factory _$AqiDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$AqiDetailImplFromJson(json);

  @override
  @JsonKey(name: 'co')
  final AqiDetailItem co;
  @override
  @JsonKey(name: 'no2')
  final AqiDetailItem no2;
  @override
  @JsonKey(name: 'o3')
  final AqiDetailItem o3;
  @override
  @JsonKey(name: 'so2')
  final AqiDetailItem so2;
  @override
  @JsonKey(name: 'pm25')
  final AqiDetailItem pm25;

  @override
  String toString() {
    return 'AqiDetail(co: $co, no2: $no2, o3: $o3, so2: $so2, pm25: $pm25)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AqiDetailImpl &&
            (identical(other.co, co) || other.co == co) &&
            (identical(other.no2, no2) || other.no2 == no2) &&
            (identical(other.o3, o3) || other.o3 == o3) &&
            (identical(other.so2, so2) || other.so2 == so2) &&
            (identical(other.pm25, pm25) || other.pm25 == pm25));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, co, no2, o3, so2, pm25);

  /// Create a copy of AqiDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AqiDetailImplCopyWith<_$AqiDetailImpl> get copyWith =>
      __$$AqiDetailImplCopyWithImpl<_$AqiDetailImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AqiDetailImplToJson(
      this,
    );
  }
}

abstract class _AqiDetail implements AqiDetail {
  const factory _AqiDetail(
          {@JsonKey(name: 'co') required final AqiDetailItem co,
          @JsonKey(name: 'no2') required final AqiDetailItem no2,
          @JsonKey(name: 'o3') required final AqiDetailItem o3,
          @JsonKey(name: 'so2') required final AqiDetailItem so2,
          @JsonKey(name: 'pm25') required final AqiDetailItem pm25}) =
      _$AqiDetailImpl;

  factory _AqiDetail.fromJson(Map<String, dynamic> json) =
      _$AqiDetailImpl.fromJson;

  @override
  @JsonKey(name: 'co')
  AqiDetailItem get co;
  @override
  @JsonKey(name: 'no2')
  AqiDetailItem get no2;
  @override
  @JsonKey(name: 'o3')
  AqiDetailItem get o3;
  @override
  @JsonKey(name: 'so2')
  AqiDetailItem get so2;
  @override
  @JsonKey(name: 'pm25')
  AqiDetailItem get pm25;

  /// Create a copy of AqiDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AqiDetailImplCopyWith<_$AqiDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
