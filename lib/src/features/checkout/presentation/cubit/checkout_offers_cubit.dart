import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/offer_entity.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/usecases/get_store_offers_usecase.dart';
import 'checkout_offers_state.dart';

/// Page-scoped (checkout and its "Coupons & offers" page each provide one):
/// the store's offers that enrich the cart's offer rows. The read is cached
/// by the shared catalogue datasource, so the second page's read is free.
class CheckoutOffersCubit extends Cubit<CheckoutOffersState>
    with SafeCubitMixin<CheckoutOffersState> {
  CheckoutOffersCubit(this._getStoreOffers)
    : super(const CheckoutOffersState());

  final GetStoreOffersUseCase _getStoreOffers;

  Future<void> load() async {
    final result = await _getStoreOffers(const NoParams());
    safeEmit(
      CheckoutOffersState(
        status: CheckoutOffersStatus.ready,
        offers: result.getOrElse(() => const <OfferEntity>[]),
      ),
    );
  }
}
