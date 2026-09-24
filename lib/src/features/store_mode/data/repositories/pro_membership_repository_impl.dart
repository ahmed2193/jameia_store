import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/pro_membership.dart';
import '../../domain/repositories/pro_membership_repository.dart';
import '../datasources/pro_membership_remote_data_source.dart';
import '../mappers/pro_membership_mapper.dart';

class ProMembershipRepositoryImpl
    with BaseRepositoryMixin
    implements ProMembershipRepository {
  const ProMembershipRepositoryImpl(this._remote);

  final ProMembershipRemoteDataSource _remote;

  @override
  Future<Either<Failure, ProProgram>> getProgram() =>
      execute(() async => (await _remote.getProgram()).toEntity());

  @override
  Future<Either<Failure, ProSubscription?>> getSubscription() =>
      execute(() async => (await _remote.getSubscription())?.toEntity());

  @override
  Future<Either<Failure, ProSubscription>> subscribe(String planId) =>
      execute(() async => (await _remote.subscribe(planId)).toEntity());

  @override
  Future<Either<Failure, ProSubscription>> cancel() =>
      execute(() async => (await _remote.cancel()).toEntity());
}
