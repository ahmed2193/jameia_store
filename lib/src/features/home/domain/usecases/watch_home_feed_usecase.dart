import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/usecase/watch_params.dart';
import '../entities/home_feed.dart';
import '../repositories/home_repository.dart';

/// The home screen (`GET /v1/home`): the copy saved on the device first,
/// then the server's; failures on the error channel.
class WatchHomeFeedUseCase
    implements StreamUseCase<DataSnapshot<HomeFeed>, WatchParams> {
  const WatchHomeFeedUseCase(this._repository);

  final HomeRepository _repository;

  @override
  Stream<DataSnapshot<HomeFeed>> call(WatchParams params) =>
      _repository.watchHomeFeed(forceRefresh: params.forceRefresh);
}
