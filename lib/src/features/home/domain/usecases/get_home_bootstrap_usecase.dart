import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/home_bootstrap.dart';
import '../repositories/home_repository.dart';

/// Loads what home shows of the launch snapshot (`GET /v1/init`): the delivery
/// place in the header, the Pro banner, the marketing popups. Secondary data:
/// the cubit keeps the screen up when this fails.
class GetHomeBootstrapUseCase implements UseCase<HomeBootstrap, NoParams> {
  const GetHomeBootstrapUseCase(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, HomeBootstrap>> call(NoParams params) =>
      _repository.getBootstrap();
}
