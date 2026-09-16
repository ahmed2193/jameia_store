import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/models/models.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/repositories/shop_repository.dart';

enum ShopFavoritesStatus { initial, loading, loaded, empty, error }

/// State for the favourited-shops feed (`shop_favorites`, bundle 49). The whole
/// shop catalogue stands in for "favourites" (dummy data — no persistence).
///
/// TODO(P2.9-boundary): [shops] stays as the core [Shop] DTO — the list feeds
/// the shared `ShopCard` core widget, which is typed on the core model, so
/// converting to a `ShopEntity` here would only be re-inflated at that call
/// site. The core type is kept at the boundary per the P2.9 boundary rule.
class ShopFavoritesState extends Equatable {
  const ShopFavoritesState({
    this.status = ShopFavoritesStatus.initial,
    this.shops = const [],
    this.error,
  });

  final ShopFavoritesStatus status;
  final List<Shop> shops;
  final String? error;

  ShopFavoritesState copyWith({
    ShopFavoritesStatus? status,
    List<Shop>? shops,
    String? error,
  }) =>
      ShopFavoritesState(
        status: status ?? this.status,
        shops: shops ?? this.shops,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => [status, shops, error];
}

/// Page-scoped cubit — resolved via `sl<ShopFavoritesCubit>()`; loads the
/// favourites feed on construction. Calls the [ShopRepository] directly (the
/// pass-through `GetFavoriteShopsUseCase` was collapsed).
class ShopFavoritesCubit extends Cubit<ShopFavoritesState>
    with SafeCubitMixin<ShopFavoritesState> {
  ShopFavoritesCubit(this._repository) : super(const ShopFavoritesState()) {
    load();
  }

  final ShopRepository _repository;

  Future<void> load() async {
    safeEmit(state.copyWith(status: ShopFavoritesStatus.loading));
    final result = await _repository.getFavoriteShops();
    result.fold(
      (failure) => safeEmit(state.copyWith(
        status: ShopFavoritesStatus.error,
        error: failure.message,
      )),
      (shops) => safeEmit(state.copyWith(
        status: shops.isEmpty
            ? ShopFavoritesStatus.empty
            : ShopFavoritesStatus.loaded,
        shops: shops,
      )),
    );
  }
}
