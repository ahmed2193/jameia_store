/// Abstract HTTP client used by every feature's `RemoteDataSource`.
///
/// Clean-arch boundary: the data layer depends on THIS, not on Dio directly.
/// The concrete [DioConsumer] is the ONLY place a `Dio` instance lives, and it
/// is registered once in `config/di/service_locator.dart`. Never call
/// `Dio()` ad-hoc inside a feature.
///
/// All methods return the DECODED body (`Map<String, dynamic>` / `List`). On any
/// HTTP or business error they throw a subclass of `AppException`.
abstract class ApiConsumer {
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  });

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  });

  Future<dynamic> put(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  });

  Future<dynamic> patch(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  });

  Future<dynamic> delete(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  });
}
