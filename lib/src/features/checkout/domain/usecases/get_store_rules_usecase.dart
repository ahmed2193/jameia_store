import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/checkout_store_rules.dart';
import '../repositories/checkout_repository.dart';

/// The store settings checkout obeys (`GET /v1/init` → `store.*`).
class GetStoreRulesUseCase implements UseCase<CheckoutStoreRules, NoParams> {
  const GetStoreRulesUseCase(this._repository);
  final CheckoutRepository _repository;

  @override
  Future<Either<Failure, CheckoutStoreRules>> call(NoParams params) =>
      _repository.getStoreRules();
}
