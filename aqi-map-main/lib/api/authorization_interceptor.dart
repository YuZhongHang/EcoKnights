import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthorizationInterceptor extends Interceptor {
  final String? apiToken = dotenv.env['API_TOKEN'];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.queryParameters['token'] = apiToken;

    return super.onRequest(options, handler);
  }
}
