import 'package:aqi_map/model/api/aqi_info/aqi_detail/aqi_detail_item.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'aqi_detail.freezed.dart';

part 'aqi_detail.g.dart';

@freezed
class AqiDetail with _$AqiDetail {
  const factory AqiDetail({
    @JsonKey(name: 'co') required AqiDetailItem co,
    @JsonKey(name: 'no2') required AqiDetailItem no2,
    @JsonKey(name: 'o3') required AqiDetailItem o3,
    @JsonKey(name: 'so2') required AqiDetailItem so2,
    @JsonKey(name: 'pm25') required AqiDetailItem pm25,
  }) = _AqiDetail;

  factory AqiDetail.fromJson(Map<String, dynamic> json) =>
      _$AqiDetailFromJson(json);
}
