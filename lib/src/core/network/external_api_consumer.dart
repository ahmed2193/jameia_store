import 'package:dio/dio.dart';

import '../error/exceptions.dart';
import 'api_exception_mapper.dart';

/// A JSON client for third-party map services (road routing): full URLs, no
/// Hero envelope, and none of the Hero chain — no Bearer, cart token or
/// guest id ever travels to another company's server, and a third-party
/// outage never marks the app offline. Returns the decoded body; errors
/// arrive as `AppException`, as from `ApiConsumer`.
///
/// A call given a [timeout] is aborted once it runs longer (the socket is
/// released, the late body never downloaded) and throws
/// `RequestTimeoutException`.
abstract class ExternalApiConsumer {
  Future<Object?> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
  });

  Future<Object?> post(
    String url, {
    Object? body,
    Map<String, String>? headers,
    Duration? timeout,
  });
}

class DioExternalApiConsumer implements ExternalApiConsumer {
  const DioExternalApiConsumer(this._dio);

  final Dio _dio;

  @override
  Future<Object?> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
  }) => _send(
    (cancelToken) => _dio.get<Object?>(
      url,
      queryParameters: queryParameters,
      options: Options(headers: headers),
      cancelToken: cancelToken,
    ),
    timeout,
  );

  @override
  Future<Object?> post(
    String url, {
    Object? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) => _send(
    (cancelToken) => _dio.post<Object?>(
      url,
      data: body,
      options: Options(headers: headers),
      cancelToken: cancelToken,
    ),
    timeout,
  );

  /// Runs [request]; past [timeout] the request is cancelled (not just no
  /// longer awaited) and the call fails as timed out, never as cancelled.
  Future<Object?> _send(
    Future<Response<Object?>> Function(CancelToken? cancelToken) request,
    Duration? timeout,
  ) async {
    final cancelToken = timeout == null ? null : CancelToken();
    var pending = request(cancelToken);
    if (timeout != null) {
      pending = pending.timeout(
        timeout,
        onTimeout: () {
          cancelToken?.cancel();
          throw const RequestTimeoutException();
        },
      );
    }
    try {
      return (await pending).data;
    } on DioException catch (error) {
      throw ApiExceptionMapper.fromDio(error);
    }
  }
}
