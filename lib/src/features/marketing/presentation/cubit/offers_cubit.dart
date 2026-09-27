import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/data_freshness.dart';
import '../../../../core/domain/entities/offer_entity.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../../core/utils/performance/snapshot_loader_mixin.dart';
import '../../domain/usecases/watch_offers_usecase.dart';
import 'offers_state.dart';

/// The store's active offers (`GET /v1/offers`): the device copy first
/// (offline too), then the server's.
class OffersCubit extends Cubit<OffersState>
    with SafeCubitMixin<OffersState>, SnapshotLoaderMixin<OffersState> {
  OffersCubit(this._watchOffers, {this._now = DateTime.now})
    : super(const OffersState());

  final WatchOffersUseCase _watchOffers;
  final DateTime Function() _now;

  /// First load, retry, language switch; the list on screen stays meanwhile.
  Future<void> load() {
    if (!state.isLoaded) safeEmit(state.copyWith(status: OffersStatus.loading));
    return _read(forceRefresh: false);
  }

  /// Pull-to-refresh: the server's.
  Future<void> refresh() => _read(forceRefresh: true);

  /// The connection came back: one silent refresh when the list is a saved
  /// copy or failed.
  Future<void> onReconnected() => refreshOnReconnect(
    needed: state.freshness.isStale || state.status == OffersStatus.error,
    refresh: refresh,
  );

  Future<void> _read({required bool forceRefresh}) =>
      followSnapshots<List<OfferEntity>>(
        _watchOffers(
          WatchOffersParams(now: _now(), forceRefresh: forceRefresh),
        ),
        onSnapshot: (snapshot) => safeEmit(
          state.copyWith(
            status: OffersStatus.loaded,
            offers: snapshot.data,
            freshness: DataFreshness.of(snapshot),
          ),
        ),
        onFailure: (failure) => safeEmit(
          state.copyWith(
            status: state.isLoaded ? OffersStatus.loaded : OffersStatus.error,
            freshness: state.freshness.failed(),
            failure: failure,
          ),
        ),
      );
}
