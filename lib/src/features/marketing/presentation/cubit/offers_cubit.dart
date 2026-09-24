import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/usecases/get_offers_usecase.dart';
import 'offers_state.dart';

/// The store's active offers (`GET /v1/offers`).
class OffersCubit extends Cubit<OffersState> with SafeCubitMixin<OffersState> {
  OffersCubit(this._getOffers, {this._now = DateTime.now})
    : super(const OffersState());

  final GetOffersUseCase _getOffers;
  final DateTime Function() _now;
  int _generation = 0;

  Future<void> load() async {
    if (!state.isLoaded) safeEmit(state.copyWith(status: OffersStatus.loading));
    await refresh();
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    final result = await _getOffers(GetOffersParams(now: _now()));
    if (generation != _generation) return;
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: state.isLoaded ? OffersStatus.loaded : OffersStatus.error,
          failure: failure,
        ),
      ),
      (offers) =>
          safeEmit(state.copyWith(status: OffersStatus.loaded, offers: offers)),
    );
  }
}
