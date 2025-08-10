import 'package:freezed_annotation/freezed_annotation.dart';

part 'city.freezed.dart';

part 'city.g.dart';

@freezed
class City with _$City {
  const factory City({
    @JsonKey(name: 'geo') required List<int> latLng,
    @JsonKey(name: 'name') required String cityName,
  }) = _City;

  factory City.fromJson(Map<String, dynamic> json) => _$CityFromJson(json);
}
