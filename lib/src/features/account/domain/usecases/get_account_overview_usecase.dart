import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/account_overview.dart';
import '../repositories/account_repository.dart';

/// Profile + quick-stat counts + unread badge for the Mine tab.
class GetAccountOverviewUseCase implements UseCase<AccountOverview, NoParams> {
  const GetAccountOverviewUseCase(this._repository);

  final AccountRepository _repository;

  @override
  Future<Either<Failure, AccountOverview>> call(NoParams params) =>
      _repository.getAccountOverview();
}
