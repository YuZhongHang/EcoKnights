import 'package:aqi_map/repository/aqi_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'model/api/aqi_info/aqi_info.dart';

part 'aqi_notifier.g.dart';

@riverpod
class AqiNotifier extends _$AqiNotifier {
  @override
  Future<AqiInfo> build() async {
    final aqiRepository = ref.watch(aqiRepositoryProvider);
    final response = await aqiRepository.fetchCurrentLocationAqi();
    return response;
  }
}
