import 'dart:developer';

import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/domain/entities/auth_customer_entity.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/entities/phone_number.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../../../../core/data/mappers/customer_mapper.dart';
import '../mappers/otp_challenge_mapper.dart';

class AuthRepositoryImpl with BaseRepositoryMixin implements AuthRepository {
  const AuthRepositoryImpl({required this._remote, required this._local});

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<Either<Failure, OtpChallenge>> sendOtp(PhoneNumber phone) =>
      execute(() async => (await _remote.sendOtp(phone.e164)).toEntity(phone));

  @override
  Future<Either<Failure, AuthCustomerEntity>> verifyOtp({
    required PhoneNumber phone,
    required String code,
  }) => execute(() async {
    final session = await _remote.verifyOtp(phone: phone.e164, code: code);
    await _local.saveSession(session.tokens);
    return session.customer.toEntity();
  });

  @override
  Future<Either<Failure, AuthCustomerEntity?>> restoreSession() =>
      execute(() async {
        if (!await _local.hasSession()) return null;
        try {
          return (await _remote.me()).toEntity();
        } on UnauthorizedException {
          // The network layer already tried one refresh; the session is over.
          await _local.clearSession();
          rethrow;
        }
      });

  @override
  Future<Either<Failure, Unit>> logout() => execute(() async {
    try {
      await _remote.logout();
    } catch (error, stackTrace) {
      // Offline, already revoked, or a malformed reply: the user still
      // signs out locally — nothing may keep a session alive on device.
      log(
        'Remote logout failed; clearing the local session anyway',
        name: 'AuthRepositoryImpl',
        error: error,
        stackTrace: stackTrace,
      );
    }
    await _local.clearSession();
    return unit;
  });

  @override
  Stream<void> watchSessionExpiry() => _local.onSessionExpired;
}
