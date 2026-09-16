import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';

/// Offline auth repository — resolves sign-in through [AuthLocalDataSource] and
/// wraps the result in `Either<Failure, T>`. The seeded demo profile the
/// datasource returns is discarded (the presentation only needs success), so
/// the core `UserProfile` DTO never leaves this data layer.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.local});

  final AuthLocalDataSource local;

  @override
  Future<Either<Failure, Unit>> login(String phone) async {
    try {
      local.login(phone); // offline no-op; seeded profile discarded.
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
