import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// The points a new account is given today (`GET /v1/init` →
/// `store.loyalty`), which the login screen offers new customers; 0 when the
/// store runs no welcome bonus (`LoyaltyProgram.welcomeBonusOnOffer`).
class GetWelcomeBonusUseCase implements UseCase<int, NoParams> {
  const GetWelcomeBonusUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, int>> call(NoParams params) async =>
      (await _repository.getLoyaltyProgram()).map(
        (program) => program.welcomeBonusOnOffer,
      );
}
