import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/cart_repository.dart';

/// Sends every pending change now (before checkout, when back online).
class FlushCartUseCase implements UseCase<Unit, NoParams> {
  const FlushCartUseCase(this._repository);
  final CartRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.flush();
}
