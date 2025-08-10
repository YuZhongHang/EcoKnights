import 'package:freezed_annotation/freezed_annotation.dart';

import 'aqi_detail/aqi_detail.dart';
import 'city.dart';

part 'aqi_info.freezed.dart';

part 'aqi_info.g.dart';

@freezed
class AqiInfo with _$AqiInfo {
  const factory AqiInfo({
    @JsonKey(name: 'city') required City city,
    @JsonKey(name: 'aqi') required int aqi,
    @JsonKey(name: 'iaqi') required AqiDetail aqiDetail,
  }) = _AqiInfo;

  factory AqiInfo.fromJson(Map<String, dynamic> json) =>
      _$AqiInfoFromJson(json);
}

// AqiInfoの拡張メソッドとして実装
extension AqiInfoExtension on AqiInfo {
  String get status {
    if (aqi <= 50) return 'GOOD';
    if (aqi <= 100) return 'MODERATE';
    if (aqi <= 150) return 'HAZARDOUS';
    if (aqi <= 200) return 'UNHEALTHY';
    if (aqi <= 300) return 'VERY UNHEALTHY';
    return 'SEVERE';
  }
}
