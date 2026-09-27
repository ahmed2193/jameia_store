import 'package:dio/dio.dart';

import '../network_info.dart';

/// Feeds [NetworkInfo] from real traffic, so the connection state follows
/// what requests actually see:
///
///   * a response of ANY status (a 404 or a 500 included) proves the backend
///     is reachable — the offline banner leaves at once, without waiting for
///     the next poll;
///   * a transport failure (no route to the host, a timeout) asks for an
///     immediate re-check. It never flips the status by itself: a slow
///     backend is not an offline phone.
///
/// Signals only — every response and error passes through unchanged.
class ReachabilitySignalInterceptor extends Interceptor {
  ReachabilitySignalInterceptor(this._networkInfo);

  final NetworkInfo _networkInfo;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _networkInfo.reportReachable();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.badResponse:
        _networkInfo.reportReachable();
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        _networkInfo.reportTransportFailure();
      case DioExceptionType.transformTimeout:
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        break;
    }
    handler.next(err);
  }
}
