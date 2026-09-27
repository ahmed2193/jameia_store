import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/usecase/watch_params.dart';
import '../entities/pro_membership.dart';
import '../repositories/pro_membership_repository.dart';

/// The customer's Pro subscription (`GET /v1/account/subscription`) as the
/// Pro page reads it: the signed-in customer's saved copy first, then the
/// server's. `null` = none; a guest's read fails with `UnauthorizedFailure`.
class WatchProSubscriptionUseCase
    implements StreamUseCase<DataSnapshot<ProSubscription?>, WatchParams> {
  const WatchProSubscriptionUseCase(this._repository);

  final ProMembershipRepository _repository;

  @override
  Stream<DataSnapshot<ProSubscription?>> call(WatchParams params) =>
      _repository.watchSubscription(forceRefresh: params.forceRefresh);
}
