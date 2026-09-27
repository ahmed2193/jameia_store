import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/usecases/get_rail_products_usecase.dart';
import 'checkout_rail_state.dart';

/// The "deals you might have missed" rail of the checkout. It is decided
/// once, before the page's content first paints, and never changes height
/// afterwards: the page waits for [CheckoutRailState.isSettled], so a reply
/// slower than [settleLimit] is dropped and the rail stays hidden.
class CheckoutRailCubit extends Cubit<CheckoutRailState>
    with SafeCubitMixin<CheckoutRailState> {
  CheckoutRailCubit(this._getRailProducts) : super(const CheckoutRailState());

  final GetRailProductsUseCase _getRailProducts;

  /// The longest the page waits for the rail.
  static const Duration settleLimit = Duration(milliseconds: 1200);

  bool _started = false;

  /// One load per page: [excludeProductIds] are the basket's products when
  /// the page opened.
  Future<void> load({required Set<String> excludeProductIds}) async {
    if (_started) return;
    _started = true;
    try {
      final result = await _getRailProducts(
        GetRailProductsParams(excludeProductIds: excludeProductIds),
      ).timeout(settleLimit);
      result.fold(
        (_) => safeEmit(
          const CheckoutRailState(status: CheckoutRailStatus.hidden),
        ),
        (products) => safeEmit(
          products.isEmpty
              ? const CheckoutRailState(status: CheckoutRailStatus.hidden)
              : CheckoutRailState(
                  status: CheckoutRailStatus.ready,
                  products: products,
                ),
        ),
      );
    } on TimeoutException {
      // Too late to join the page without moving it: the rail stays away.
      safeEmit(const CheckoutRailState(status: CheckoutRailStatus.hidden));
    }
  }
}
