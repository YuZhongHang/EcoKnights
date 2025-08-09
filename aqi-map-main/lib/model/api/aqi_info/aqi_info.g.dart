// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aqi_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AqiInfoImpl _$$AqiInfoImplFromJson(Map<String, dynamic> json) =>
    _$AqiInfoImpl(
      city: City.fromJson(json['city'] as Map<String, dynamic>),
      aqi: (json['aqi'] as num).toInt(),
      aqiDetail: AqiDetail.fromJson(json['iaqi'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$AqiInfoImplToJson(_$AqiInfoImpl instance) =>
    <String, dynamic>{
      'city': instance.city,
      'aqi': instance.aqi,
      'iaqi': instance.aqiDetail,
    };
