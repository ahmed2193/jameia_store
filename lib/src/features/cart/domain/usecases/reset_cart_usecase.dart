import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/cart_repository.dart';

/// Forgets the cart on the device (sign-out, order placed).
class ResetCartUseCase implements UseCase<Unit, NoParams> {
  const ResetCartUseCase(this._repository);
  final CartRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.reset();
}
