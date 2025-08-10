import 'package:freezed_annotation/freezed_annotation.dart';

part 'aqi_detail_item.freezed.dart';
part 'aqi_detail_item.g.dart';

@freezed
class AqiDetailItem with _$AqiDetailItem {
  const factory AqiDetailItem({
    @JsonKey(name: 'v') required int value,
  }) = _AqiDetailItem;

  factory AqiDetailItem.fromJson(Map<String, dynamic> json) =>
      _$AqiDetailItemFromJson(json);
}
