// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aqi_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AqiDetailImpl _$$AqiDetailImplFromJson(Map<String, dynamic> json) =>
    _$AqiDetailImpl(
      co: AqiDetailItem.fromJson(json['co'] as Map<String, dynamic>),
      no2: AqiDetailItem.fromJson(json['no2'] as Map<String, dynamic>),
      o3: AqiDetailItem.fromJson(json['o3'] as Map<String, dynamic>),
      so2: AqiDetailItem.fromJson(json['so2'] as Map<String, dynamic>),
      pm25: AqiDetailItem.fromJson(json['pm25'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$AqiDetailImplToJson(_$AqiDetailImpl instance) =>
    <String, dynamic>{
      'co': instance.co,
      'no2': instance.no2,
      'o3': instance.o3,
      'so2': instance.so2,
      'pm25': instance.pm25,
    };
