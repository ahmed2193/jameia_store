import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/data/models/models.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/account/data/datasources/account_local_data_source.dart';
import 'package:jameia_mart/src/features/account/data/datasources/account_remote_data_source.dart';
import 'package:jameia_mart/src/features/account/data/repositories/account_repository_impl.dart';
import 'package:jameia_mart/src/features/account/domain/entities/profile_update.dart';

class _FakeRemote implements AccountRemoteDataSource {
  Object? error;
  Map<String, Object?>? lastBody;
  CustomerModel reply = const CustomerModel(
    id: 'abc',
    phone: '+96512345678',
    nameEn: 'Ahmed',
    wallet: 1250,
  );

  @override
  Future<CustomerModel> me() async {
    if (error != null) throw error!;
    return reply;
  }

  @override
  Future<CustomerModel> updateProfile(Map<String, Object?> body) async {
    if (error != null) throw error!;
    lastBody = body;
    return reply;
  }
}

class _FakeLocal implements AccountLocalDataSource {
  Object? error;

  @override
  UserProfile user() {
    if (error != null) throw error!;
    return const UserProfile(
      id: 'u1',
      name: 'Seed',
      phone: '+9650',
      avatar: '',
      deliveryCode: '1234',
    );
  }

  @override
  int couponCount() => 2;

  @override
  int favouriteCount() => 3;

  @override
  int customerServiceUnread() => 1;
}

void main() {
  late _FakeRemote remote;
  late _FakeLocal local;
  late AccountRepositoryImpl repository;

  setUp(() {
    remote = _FakeRemote();
    local = _FakeLocal();
    repository = AccountRepositoryImpl(local: local, remote: remote);
  });

  test('getProfile maps the model to the entity', () async {
    final result = await repository.getProfile();

    final entity = result.getOrElse(() => throw StateError('left'));
    expect(entity.id, 'abc');
    expect(entity.walletFils, 1250);
  });

  test(
    'updateProfile sends the diff body and returns the updated customer',
    () async {
      final result = await repository.updateProfile(
        const ProfileUpdate(name: 'Ahmed Ali', email: ''),
      );

      expect(remote.lastBody, {'name': 'Ahmed Ali', 'email': null});
      expect(result.isRight(), isTrue);
    },
  );

  test('typed exceptions become failures', () async {
    remote.error = const UnauthorizedException(
      'Sign in',
      code: 'AUTHENTICATION_REQUIRED',
    );
    expect(
      await repository.getProfile(),
      const Left<Failure, Object>(UnauthorizedFailure('Sign in')),
    );

    remote.error = const BadRequestException(
      'Validation failed',
      code: 'VALIDATION_ERROR',
    );
    final failure = (await repository.updateProfile(
      const ProfileUpdate(name: ''),
    )).swap().getOrElse(() => throw StateError('right'));
    expect(failure, isA<ServerFailure>());
    expect((failure as ServerFailure).code, 'VALIDATION_ERROR');
  });

  test('offline overview + delivery code still come from the seed', () async {
    final overview = (await repository.getAccountOverview()).getOrElse(
      () => throw StateError('left'),
    );
    expect(overview.user.deliveryCode, '1234');
    expect(overview.couponCount, 2);

    expect(
      await repository.getDeliveryCode(),
      const Right<Failure, String>('1234'),
    );

    local.error = const CacheException('boom');
    expect((await repository.getDeliveryCode()).isLeft(), isTrue);
  });
}
