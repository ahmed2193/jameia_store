// ReachabilitySignalInterceptor on the real DioConsumer over a scripted
// transport: any HTTP response (2xx, 4xx, 5xx) proves the backend reachable;
// a connection error or a timeout asks for a re-check; a cancel says
// nothing. Every response and error still reaches the caller unchanged.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/error/exceptions.dart';
import 'package:hero_mart/src/core/network/dio_consumer.dart';
import 'package:hero_mart/src/core/network/interceptors/reachability_signal_interceptor.dart';

import 'network_test_fakes.dart';

void main() {
  late FakeNetworkInfo networkInfo;

  DioConsumer consumerWith(FakeHttpClientAdapter adapter) {
    networkInfo = FakeNetworkInfo(isReachable: false);
    return DioConsumer(
      Dio()..httpClientAdapter = adapter,
      interceptors: [ReachabilitySignalInterceptor(networkInfo)],
    );
  }

  test('a 200 reports reachable and passes the results through', () async {
    final consumer = consumerWith(
      FakeHttpClientAdapter((_, _) => okBody({'ok': true})),
    );
    expect(await consumer.get('/v1/home'), {'ok': true});
    expect(networkInfo.reachableReports, 1);
    expect(networkInfo.transportFailureReports, 0);
  });

  for (final status in [404, 500]) {
    test('a $status still proves the backend is reachable', () async {
      final consumer = consumerWith(
        FakeHttpClientAdapter(
          (_, _) => envelope(
            status: status,
            statusMessage: 'ERROR',
            errorMessage: 'nope',
          ),
        ),
      );
      await expectLater(consumer.get('/x'), throwsA(isA<ServerException>()));
      expect(networkInfo.reachableReports, 1);
      expect(networkInfo.transportFailureReports, 0);
    });
  }

  test('a connection error asks for a re-check and still fails', () async {
    final consumer = consumerWith(
      FakeHttpClientAdapter(
        (options, _) => throw DioException.connectionError(
          requestOptions: options,
          reason: 'no route',
        ),
      ),
    );
    await expectLater(
      consumer.get('/x'),
      throwsA(isA<NoInternetConnectionException>()),
    );
    expect(networkInfo.transportFailureReports, 1);
    expect(networkInfo.reachableReports, 0);
  });

  test('a timeout asks for a re-check', () async {
    final consumer = consumerWith(
      FakeHttpClientAdapter(
        (options, _) => throw DioException.receiveTimeout(
          timeout: const Duration(seconds: 1),
          requestOptions: options,
        ),
      ),
    );
    await expectLater(
      consumer.get('/x'),
      throwsA(isA<RequestTimeoutException>()),
    );
    expect(networkInfo.transportFailureReports, 1);
  });

  test('a cancelled request says nothing about reachability', () async {
    final consumer = consumerWith(
      FakeHttpClientAdapter(
        (options, _) => throw DioException.requestCancelled(
          requestOptions: options,
          reason: 'screen closed',
        ),
      ),
    );
    await expectLater(consumer.get('/x'), throwsA(isA<AppException>()));
    expect(networkInfo.transportFailureReports, 0);
    expect(networkInfo.reachableReports, 0);
  });
}
