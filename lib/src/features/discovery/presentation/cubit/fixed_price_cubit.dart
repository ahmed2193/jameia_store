import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/usecases/get_fixed_price_usecase.dart';

enum FixedPriceStatus { initial, loading, loaded, error }

/// State for the fixed-price channel: the host flash [Shop] + its hot-selling
/// products (discounted lines first), loaded through [GetFixedPriceUseCase].
/// [shop] is null until the load resolves.
class FixedPriceState extends Equatable {
  const FixedPriceState({
    this.status = FixedPriceStatus.initial,
    this.shop,
    this.products = const <ProductEntity>[],
    this.error,
  });

  final FixedPriceStatus status;
  final ShopEntity? shop;
  final List<ProductEntity> products;
  final String? error;

  FixedPriceState copyWith({
    FixedPriceStatus? status,
    ShopEntity? shop,
    List<ProductEntity>? products,
    String? error,
  }) => FixedPriceState(
    status: status ?? this.status,
    shop: shop ?? this.shop,
    products: products ?? this.products,
    error: error ?? this.error,
  );

  @override
  List<Object?> get props => [status, shop, products, error];
}

/// Page-scoped cubit — resolved via `sl<FixedPriceCubit>()`; the screen kicks
/// off [load] with the tapped storefront id (or null for the default host).
class FixedPriceCubit extends Cubit<FixedPriceState>
    with SafeCubitMixin<FixedPriceState> {
  FixedPriceCubit(this._getFixedPrice) : super(const FixedPriceState());

  final GetFixedPriceUseCase _getFixedPrice;
  String? _lastShopId;

  Future<void> load(String? shopId) async {
    _lastShopId = shopId;
    safeEmit(state.copyWith(status: FixedPriceStatus.loading));
    final result = await _getFixedPrice(GetFixedPriceParams(shopId));
    result.fold(
      (failure) => safeEmit(
        state.copyWith(status: FixedPriceStatus.error, error: failure.message),
      ),
      (view) => safeEmit(
        state.copyWith(
          status: FixedPriceStatus.loaded,
          shop: view.shop,
          products: view.products,
        ),
      ),
    );
  }

  /// Re-run the last load (error-retry).
  Future<void> retry() => load(_lastShopId);
}
