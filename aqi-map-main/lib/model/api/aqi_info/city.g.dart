// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'city.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CityImpl _$$CityImplFromJson(Map<String, dynamic> json) => _$CityImpl(
      latLng: (json['geo'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      cityName: json['name'] as String,
    );

Map<String, dynamic> _$$CityImplToJson(_$CityImpl instance) =>
    <String, dynamic>{
      'geo': instance.latLng,
      'name': instance.cityName,
    };
