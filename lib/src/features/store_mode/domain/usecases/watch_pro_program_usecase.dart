import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/usecase/watch_params.dart';
import '../entities/pro_membership.dart';
import '../repositories/pro_membership_repository.dart';

/// The Pro programme — perks + plans (`GET /v1/subscription-plans`) — as the
/// Pro page reads it: the copy saved on the device first, then the server's.
class WatchProProgramUseCase
    implements StreamUseCase<DataSnapshot<ProProgram>, WatchParams> {
  const WatchProProgramUseCase(this._repository);

  final ProMembershipRepository _repository;

  @override
  Stream<DataSnapshot<ProProgram>> call(WatchParams params) =>
      _repository.watchProgram(forceRefresh: params.forceRefresh);
}
