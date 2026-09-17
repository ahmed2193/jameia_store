import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/account_repository.dart';

/// The saved 4-digit delivery code.
class GetDeliveryCodeUseCase implements UseCase<String, NoParams> {
  const GetDeliveryCodeUseCase(this._repository);

  final AccountRepository _repository;

  @override
  Future<Either<Failure, String>> call(NoParams params) =>
      _repository.getDeliveryCode();
}
