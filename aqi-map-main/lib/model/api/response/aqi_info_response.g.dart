// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aqi_info_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AqiInfoResponseImpl _$$AqiInfoResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$AqiInfoResponseImpl(
      status: json['status'] as String,
      aqiInfo: AqiInfo.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$AqiInfoResponseImplToJson(
        _$AqiInfoResponseImpl instance) =>
    <String, dynamic>{
      'status': instance.status,
      'data': instance.aqiInfo,
    };
