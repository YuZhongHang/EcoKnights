import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/aqi_client.dart';
import '../model/api/aqi_info/aqi_info.dart';

part 'aqi_repository.g.dart';

@riverpod
AqiRepository aqiRepository(Ref ref) {
  final client = ref.watch(aqiClientProvider);
  return AqiRepository(client);
}

class AqiRepository {
  final AqiClient _client;

  AqiRepository(this._client);

  Future<AqiInfo> fetchCurrentLocationAqi() async {
    try {
      final currentLocationAqi = await _client.fetchCurrentLocationAqi();
      return currentLocationAqi.aqiInfo;
    } catch (e) {
      throw Exception('Failed to retrieve the current AQI: $e');
    }
  }
}
