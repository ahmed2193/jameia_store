import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/home_bootstrap.dart';
import '../repositories/home_repository.dart';

class CheckFirstOrderWelcomeParams extends Equatable {
  const CheckFirstOrderWelcomeParams({required this.bootstrap});

  /// A launch snapshot from the server, never a saved copy.
  final HomeBootstrap bootstrap;

  @override
  List<Object?> get props => [bootstrap];
}

/// Whether home greets the customer with the first-order free-delivery gift:
/// unless the store switched it off (`firstOrderFreeDelivery`), and only for
/// someone with no order yet — a guest (an order needs an account), or a
/// signed-in customer whose order count is 0 (so also right after a sign-in:
/// the new session's home reads the new account's count). The count is asked
/// only when it matters; a failed count is returned as it is, and the caller
/// shows no gift rather than guess.
class CheckFirstOrderWelcomeUseCase
    implements UseCase<bool, CheckFirstOrderWelcomeParams> {
  const CheckFirstOrderWelcomeUseCase(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, bool>> call(
    CheckFirstOrderWelcomeParams params,
  ) async {
    final bootstrap = params.bootstrap;
    if (!bootstrap.firstOrderFreeDelivery) return const Right(false);
    if (!bootstrap.hasCustomer) return const Right(true);
    return (await _repository.countOrders()).map((total) => total == 0);
  }
}
