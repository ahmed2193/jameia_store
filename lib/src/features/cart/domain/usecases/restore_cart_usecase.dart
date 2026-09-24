import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/cart_repository.dart';

/// Paints the last known cart from the device before the network answers.
class RestoreCartUseCase implements UseCase<Unit, NoParams> {
  const RestoreCartUseCase(this._repository);
  final CartRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.restore();
}
