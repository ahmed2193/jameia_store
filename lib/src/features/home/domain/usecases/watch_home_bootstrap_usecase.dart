import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/usecase/watch_params.dart';
import '../entities/home_bootstrap.dart';
import '../repositories/home_repository.dart';

/// What home shows of the launch snapshot (`GET /v1/init`): the delivery
/// place in the header, the Pro banner, the marketing popups — the saved copy
/// first, then the server's. Secondary data: the screen stays up when this
/// fails.
class WatchHomeBootstrapUseCase
    implements StreamUseCase<DataSnapshot<HomeBootstrap>, WatchParams> {
  const WatchHomeBootstrapUseCase(this._repository);

  final HomeRepository _repository;

  @override
  Stream<DataSnapshot<HomeBootstrap>> call(WatchParams params) =>
      _repository.watchBootstrap(forceRefresh: params.forceRefresh);
}
