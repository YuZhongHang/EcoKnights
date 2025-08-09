import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';

import 'authorization_interceptor.dart';

part 'app_dio.g.dart';

@Riverpod(keepAlive: true)
Dio appDio(Ref ref) {
  final dio = Dio();
  dio.interceptors.add(AuthorizationInterceptor());

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    );
  }

  return dio;
}
