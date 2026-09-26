import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/loyalty_rewards.dart';
import '../repositories/loyalty_repository.dart';

/// The Rewards screen: the programme (`GET /v1/init`) and the points balance
/// (`GET /v1/account/loyalty`, first page of one line — only the balance is
/// used) read together, turned into redemption tiers.
///
/// The ledger's failure wins: a guest gets `UnauthorizedFailure` (the sign-in
/// prompt) even when the programme failed too.
class GetLoyaltyRewardsUseCase implements UseCase<LoyaltyRewards, NoParams> {
  const GetLoyaltyRewardsUseCase(this._repository);

  static const int _firstPage = 1;

  /// The balance comes with any page; one line keeps the reply small.
  static const int _balanceOnly = 1;

  final LoyaltyRepository _repository;

  @override
  Future<Either<Failure, LoyaltyRewards>> call(NoParams params) async {
    final (programResult, ledgerResult) = await (
      _repository.getProgram(),
      _repository.getLedger(page: _firstPage, limit: _balanceOnly),
    ).wait;
    return ledgerResult.fold(
      (failure) => Left<Failure, LoyaltyRewards>(failure),
      (ledger) => programResult.map(
        (program) => LoyaltyRewards.from(program, ledger.balance),
      ),
    );
  }
}
