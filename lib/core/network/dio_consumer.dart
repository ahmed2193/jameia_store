import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../error/exceptions.dart';
import 'api_consumer.dart';

/// The ONE and only Dio wrapper. Owns the shared [Dio], installs interceptors
/// once, and translates every `DioException` into a typed [ServerException] so
/// callers above never see Dio types leak through the boundary.
class DioConsumer implements ApiConsumer {
  final Dio _dio;

  DioConsumer(this._dio) {
    _dio
      ..options.baseUrl = AppConstants.baseUrl
      ..options.connectTimeout = AppConstants.connectTimeout
      ..options.receiveTimeout = AppConstants.receiveTimeout
      ..options.responseType = ResponseType.json;

    // Single place to attach auth/app headers + (debug) logging.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // options.headers['Authorization'] = 'Bearer <token from storage>';
          handler.next(options);
        },
      ),
    );
  }

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) =>
      _request(() => _dio.get(
            path,
            queryParameters: queryParameters,
            options: Options(headers: headers),
          ));

  @override
  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) =>
      _request(() => _dio.post(
            path,
            data: body,
            queryParameters: queryParameters,
            options: Options(headers: headers),
          ));

  @override
  Future<dynamic> put(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) =>
      _request(() => _dio.put(
            path,
            data: body,
            queryParameters: queryParameters,
            options: Options(headers: headers),
          ));

  @override
  Future<dynamic> patch(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) =>
      _request(() => _dio.patch(
            path,
            data: body,
            queryParameters: queryParameters,
            options: Options(headers: headers),
          ));

  @override
  Future<dynamic> delete(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) =>
      _request(() => _dio.delete(
            path,
            data: body,
            queryParameters: queryParameters,
            options: Options(headers: headers),
          ));

  /// Runs the request and maps any failure to a typed exception.
  Future<dynamic> _request(Future<Response> Function() send) async {
    try {
      final response = await send();
      return response.data;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  ServerException _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();
      case DioExceptionType.connectionError:
        return const NoInternetConnectionException();
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final msg = _messageFromBody(e.response?.data) ?? 'Request failed';
        switch (code) {
          case 400:
            return BadRequestException(msg);
          case 401:
            return UnauthorizedException(msg);
          case 404:
            return NotFoundException(msg);
          default:
            return ServerException(msg, code);
        }
      default:
        return ServerException(e.message ?? 'Unexpected network error');
    }
  }

  String? _messageFromBody(dynamic data) {
    if (data is Map && data['message'] is String) return data['message'] as String;
    if (data is Map && data['errors'] is Map) {
      final errors = data['errors'] as Map;
      if (errors['message'] is String) return errors['message'] as String;
    }
    return null;
  }
}
