import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/support_repository.dart';

/// The rider the chat talks to (`null` when no order has one).
class GetActiveRiderNameUseCase implements UseCase<String?, NoParams> {
  const GetActiveRiderNameUseCase(this._repository);

  final SupportRepository _repository;

  @override
  Future<Either<Failure, String?>> call(NoParams params) =>
      _repository.getActiveRiderName();
}
