import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/account_overview.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_local_data_source.dart';
import '../mappers/user_profile_mapper.dart';

/// Offline account repository — reads the seeded [AccountLocalDataSource] and
/// wraps the result in `Either<Failure, T>`.
class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl({required this.local});

  final AccountLocalDataSource local;

  @override
  Future<Either<Failure, AccountOverview>> getAccountOverview() async {
    try {
      return Right(AccountOverview(
        user: local.user().toEntity(),
        couponCount: local.couponCount(),
        favouriteCount: local.favouriteCount(),
        customerServiceUnread: local.customerServiceUnread(),
      ));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getDeliveryCode() async {
    try {
      return Right(local.user().deliveryCode);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
