import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../constants/app_env.dart';
import 'api_headers.dart';

/// The Dio configuration of [ExternalApiConsumer] (third-party map services):
/// the app's timeouts and JSON, no Hero host, and a user agent that names the
/// app, as public services such as OSRM ask.
BaseOptions buildExternalBaseOptions() => BaseOptions(
  connectTimeout: AppConstants.connectTimeout,
  receiveTimeout: AppConstants.receiveTimeout,
  sendTimeout: AppConstants.sendTimeout,
  responseType: ResponseType.json,
  contentType: ApiHeaders.jsonMediaType,
  headers: <String, Object?>{
    ApiHeaders.accept: ApiHeaders.jsonMediaType,
    ApiHeaders.userAgent: ApiHeaders.externalUserAgent,
  },
);

/// The shared Dio configuration. Used by the main `DioConsumer` client AND by
/// the bare token-refresh client, so both talk to the same host with the same
/// timeouts and JSON defaults.
BaseOptions buildApiBaseOptions() => BaseOptions(
  baseUrl: AppEnv.apiBaseUrl,
  connectTimeout: AppConstants.connectTimeout,
  receiveTimeout: AppConstants.receiveTimeout,
  sendTimeout: AppConstants.sendTimeout,
  responseType: ResponseType.json,
  contentType: ApiHeaders.jsonMediaType,
  headers: <String, Object?>{ApiHeaders.accept: ApiHeaders.jsonMediaType},
);
