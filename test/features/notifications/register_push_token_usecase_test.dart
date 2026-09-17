import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:jameia_mart/src/features/notifications/domain/usecases/register_push_token_usecase.dart';

import 'notifications_test_fakes.dart';

void main() {
  late FakeNotificationsRemoteDataSource remote;
  late RegisterPushTokenUseCase useCase;

  setUp(() {
    remote = FakeNotificationsRemoteDataSource();
    useCase = RegisterPushTokenUseCase(NotificationsRepositoryImpl(remote));
  });

  test('a valid token + platform reaches the backend', () async {
    final result = await useCase(
      const RegisterPushTokenParams(
        token: 'fcm_0123456789abcdef',
        platform: RegisterPushTokenParams.platformAndroid,
      ),
    );

    expect(result, const Right<Failure, Unit>(unit));
    expect(remote.calls, isNotEmpty);
  });

  test('an invalid token or platform never reaches the network', () async {
    final tooShort = await useCase(
      const RegisterPushTokenParams(
        token: 'short',
        platform: RegisterPushTokenParams.platformIos,
      ),
    );
    final badPlatform = await useCase(
      const RegisterPushTokenParams(
        token: 'fcm_0123456789abcdef',
        platform: 'web',
      ),
    );

    expect(tooShort.isLeft(), isTrue);
    expect(badPlatform.isLeft(), isTrue);
    expect(remote.calls, isEmpty);
  });
}
