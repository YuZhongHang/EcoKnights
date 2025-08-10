import 'package:aqi_map/model/api/aqi_info/aqi_info.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'aqi_info_response.freezed.dart';

part 'aqi_info_response.g.dart';

@freezed
class AqiInfoResponse with _$AqiInfoResponse {
  const factory AqiInfoResponse({
    @JsonKey(name: 'status') required String status,
    @JsonKey(name: 'data') required AqiInfo aqiInfo,
  }) = _AqiInfoResponse;

  factory AqiInfoResponse.fromJson(Map<String, dynamic> json) =>
      _$AqiInfoResponseFromJson(json);
}
