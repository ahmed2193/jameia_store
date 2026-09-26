import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/cart_offers_view.dart';
import '../../domain/usecases/get_deal_products_usecase.dart';
import 'cart_deals_state.dart';

/// The "Buy more, save more" sheet: the selected deal and the products to
/// add towards it (`GetDealProductsUseCase`). Each opening of the sheet
/// reads afresh; switching cards inside one opening reuses what was read.
/// A slow reply for a card the customer already left is dropped.
class CartDealsCubit extends Cubit<CartDealsState>
    with SafeCubitMixin<CartDealsState> {
  CartDealsCubit(this._getDealProducts) : super(const CartDealsState());

  final GetDealProductsUseCase _getDealProducts;

  /// Category id (`null` = on sale) → products, for this opening.
  final Map<String?, List<CatalogProductEntity>> _read =
      <String?, List<CatalogProductEntity>>{};
  String? _categoryId;
  int _generation = 0;

  /// The sheet opens: keeps the selected deal while the cart still has it,
  /// else starts on the next one to unlock ([CartOffersView.initial]).
  Future<void> open(CartOffersView view) async {
    _read.clear();
    final deal = view.byId(state.selectedOfferId) ?? view.initial;
    if (deal == null) return;
    await select(deal);
  }

  Future<void> select(CartDealEntity deal) async {
    _categoryId = deal.categoryId;
    final read = _read[_categoryId];
    if (read != null) {
      ++_generation; // a reply still on its way is for another card
      safeEmit(
        state.copyWith(
          selectedOfferId: deal.offerId,
          status: CartDealsStatus.loaded,
          products: read,
        ),
      );
      return;
    }
    await _load(deal.offerId);
  }

  Future<void> retry() async {
    final offerId = state.selectedOfferId;
    if (offerId != null) await _load(offerId);
  }

  Future<void> _load(String offerId) async {
    final generation = ++_generation;
    final categoryId = _categoryId;
    safeEmit(
      state.copyWith(selectedOfferId: offerId, status: CartDealsStatus.loading),
    );
    final result = await _getDealProducts(
      GetDealProductsParams(categoryId: categoryId),
    );
    if (generation != _generation) return;
    result.fold(
      (failure) => safeEmit(
        state.copyWith(status: CartDealsStatus.error, failure: failure),
      ),
      (products) {
        _read[categoryId] = products;
        safeEmit(
          state.copyWith(status: CartDealsStatus.loaded, products: products),
        );
      },
    );
  }
}
