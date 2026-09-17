import 'package:dartz/dartz.dart';

import '../../../../core/data/mappers/customer_mapper.dart';
import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/domain/entities/auth_customer_entity.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/account_overview.dart';
import '../../domain/entities/profile_update.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_local_data_source.dart';
import '../datasources/account_remote_data_source.dart';
import '../mappers/profile_update_mapper.dart';
import '../mappers/user_profile_mapper.dart';

/// Offline overview / delivery code + the live profile over the API.
class AccountRepositoryImpl
    with BaseRepositoryMixin
    implements AccountRepository {
  const AccountRepositoryImpl({required this._local, required this._remote});

  final AccountLocalDataSource _local;
  final AccountRemoteDataSource _remote;

  @override
  Future<Either<Failure, AccountOverview>> getAccountOverview() => execute(
    () => AccountOverview(
      user: _local.user().toEntity(),
      couponCount: _local.couponCount(),
      favouriteCount: _local.favouriteCount(),
      customerServiceUnread: _local.customerServiceUnread(),
    ),
  );

  @override
  Future<Either<Failure, String>> getDeliveryCode() =>
      execute(() => _local.user().deliveryCode);

  @override
  Future<Either<Failure, AuthCustomerEntity>> getProfile() =>
      execute(() async => (await _remote.me()).toEntity());

  @override
  Future<Either<Failure, AuthCustomerEntity>> updateProfile(
    ProfileUpdate update,
  ) => execute(
    () async => (await _remote.updateProfile(update.toBody())).toEntity(),
  );
}
