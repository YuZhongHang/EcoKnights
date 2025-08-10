import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'app_dio.dart';

import '../model/api/response/aqi_info_response.dart';

part 'aqi_client.g.dart';

@Riverpod(keepAlive: true)
AqiClient aqiClient(Ref ref) {
  final dio = ref.watch(appDioProvider);
  return AqiClient(dio);
}

// Real-time Air Quality data feed
// https://aqicn.org/json-api/doc/
@RestApi(baseUrl: 'https://api.waqi.info')
abstract class AqiClient {
  factory AqiClient(Dio dio, {String? baseUrl}) = _AqiClient;

  @GET('/feed/here')
  Future<AqiInfoResponse> fetchCurrentLocationAqi();
}
