import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/home_feed.dart';
import '../repositories/home_repository.dart';

/// Loads the home screen (`GET /v1/home`).
class GetHomeFeedUseCase implements UseCase<HomeFeed, NoParams> {
  const GetHomeFeedUseCase(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, HomeFeed>> call(NoParams params) =>
      _repository.getHomeFeed();
}
