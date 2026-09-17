import 'package:dio/dio.dart';

import 'api_base_options.dart';
import 'api_consumer.dart';
import 'api_envelope.dart';
import 'api_exception_mapper.dart';

/// The ONE and only Dio wrapper for request/response calls. In the app the
/// shared [Dio] arrives fully configured from `service_locator.dart` (the SSE
/// client shares it); the constructor still applies [buildApiBaseOptions] and
/// any [interceptors] passed, so tests can build one from a bare `Dio()`. It:
///
///   * unwraps the jm3eia envelope — callers receive `results`, never the
///     `{ success, statusCode, statusMessage, results, error }` wrapper;
///   * translates every `DioException` (and a 2xx with `success: false`) into
///     a typed `AppException` through [ApiExceptionMapper], so no Dio type
///     leaks above this boundary.
///
/// Interceptor order matters and is fixed in `config/di/service_locator.dart`:
/// auth (Bearer + 401 refresh) → app headers → 429 retry → debug log.
class DioConsumer implements ApiConsumer {
  DioConsumer(this._dio, {List<Interceptor> interceptors = const []}) {
    _dio.options = buildApiBaseOptions();
    _dio.interceptors.addAll(interceptors);
  }

  final Dio _dio;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) => _request(
    () => _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
      options: Options(headers: headers),
    ),
  );

  @override
  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) => _request(
    () => _dio.post<dynamic>(
      path,
      data: body,
      queryParameters: queryParameters,
      options: Options(headers: headers),
    ),
  );

  @override
  Future<dynamic> put(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) => _request(
    () => _dio.put<dynamic>(
      path,
      data: body,
      queryParameters: queryParameters,
      options: Options(headers: headers),
    ),
  );

  @override
  Future<dynamic> patch(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) => _request(
    () => _dio.patch<dynamic>(
      path,
      data: body,
      queryParameters: queryParameters,
      options: Options(headers: headers),
    ),
  );

  @override
  Future<dynamic> delete(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) => _request(
    () => _dio.delete<dynamic>(
      path,
      data: body,
      queryParameters: queryParameters,
      options: Options(headers: headers),
    ),
  );

  /// Runs the request, unwraps the envelope, maps any failure to a typed
  /// exception.
  Future<dynamic> _request(Future<Response<dynamic>> Function() send) async {
    try {
      final response = await send();
      return _unwrap(response.data);
    } on DioException catch (exception) {
      throw ApiExceptionMapper.fromDio(exception);
    }
  }

  /// `results` from an envelope; a body that is not an envelope (streams,
  /// non-jm3eia hosts) passes through unchanged.
  static Object? _unwrap(Object? body) {
    final envelope = ApiEnvelope.tryParse(body);
    if (envelope == null) return body;
    if (!envelope.success) throw ApiExceptionMapper.fromEnvelope(envelope);
    return envelope.results;
  }
}
