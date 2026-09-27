import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/offer_entity.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../../../core/utils/performance/snapshot_loader_mixin.dart';
import '../../domain/usecases/watch_offers_usecase.dart';
import 'offers_state.dart';

/// The store's active offers (`GET /v1/offers`): the device copy first
/// (offline too), then the server's; the screen flow is the loader mixins'.
class OffersCubit extends Cubit<OffersState>
    with
        SafeCubitMixin<OffersState>,
        SnapshotLoaderMixin<OffersState>,
        ScreenLoaderMixin<OffersState> {
  OffersCubit(this._watchOffers, {this._now = DateTime.now})
    : super(const OffersState());

  final WatchOffersUseCase _watchOffers;
  final DateTime Function() _now;

  /// First load, retry, language switch; the list on screen stays meanwhile.
  Future<void> load() {
    showLoading();
    return _read(forceRefresh: false);
  }

  /// Pull-to-refresh: the server's.
  @override
  Future<void> refresh() => _read(forceRefresh: true);

  Future<void> _read({required bool forceRefresh}) =>
      readScreen<List<OfferEntity>>(
        _watchOffers(
          WatchOffersParams(now: _now(), forceRefresh: forceRefresh),
        ),
        show: (state, snapshot) => state.copyWith(offers: snapshot.data),
      );
}
