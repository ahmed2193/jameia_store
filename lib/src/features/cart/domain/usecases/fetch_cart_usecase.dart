import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/cart_repository.dart';

/// Reloads the cart from the server (pull to refresh, language change).
class FetchCartUseCase implements UseCase<Unit, NoParams> {
  const FetchCartUseCase(this._repository);
  final CartRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.fetch();
}
