import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/invite_friends.dart';
import '../../domain/entities/punctual_landing.dart';
import '../../domain/repositories/marketing_repository.dart';
import '../datasources/marketing_local_data_source.dart';

/// Offline marketing repository — reads the scripted [MarketingLocalDataSource]
/// and wraps the result in `Either<Failure, T>`.
class MarketingRepositoryImpl implements MarketingRepository {
  MarketingRepositoryImpl({required this.local});

  final MarketingLocalDataSource local;

  @override
  Future<Either<Failure, PunctualLanding>> getPunctualLanding() async {
    try {
      return Right(local.punctualLanding());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, InviteFriends>> getInviteFriends() async {
    try {
      return Right(local.inviteFriends());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
