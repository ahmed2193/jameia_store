import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/support_hub.dart';
import '../repositories/support_repository.dart';

/// Help-center hub: the newest order's help card and the FAQ topics.
class GetSupportHubUseCase implements UseCase<SupportHub, NoParams> {
  const GetSupportHubUseCase(this._repository);

  final SupportRepository _repository;

  @override
  Future<Either<Failure, SupportHub>> call(NoParams params) =>
      _repository.getSupportHub();
}
