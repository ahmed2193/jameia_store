import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/repositories/shop_repository.dart';

enum ShopDetailStatus { initial, loading, loaded, error }

/// State for the read-only shop-detail panel (`shop_detail`, bundle 48) — one
/// [ShopEntity] loaded through the [ShopRepository], plus a local (dummy)
/// favourite toggle that never persists.
class ShopDetailState extends Equatable {
  const ShopDetailState({
    this.status = ShopDetailStatus.initial,
    this.shop,
    this.favourite = false,
    this.error,
  });

  final ShopDetailStatus status;
  final ShopEntity? shop;
  final bool favourite;
  final String? error;

  ShopDetailState copyWith({
    ShopDetailStatus? status,
    ShopEntity? shop,
    bool? favourite,
    String? error,
  }) => ShopDetailState(
    status: status ?? this.status,
    shop: shop ?? this.shop,
    favourite: favourite ?? this.favourite,
    error: error ?? this.error,
  );

  @override
  List<Object?> get props => [status, shop, favourite, error];
}

/// Page-scoped cubit — resolved via `sl<ShopDetailCubit>()`; the screen calls
/// [load] with the routed shop id on first build. Calls the [ShopRepository]
/// directly (the pass-through `GetShopDetailUseCase` was collapsed).
class ShopDetailCubit extends Cubit<ShopDetailState>
    with SafeCubitMixin<ShopDetailState> {
  ShopDetailCubit(this._repository) : super(const ShopDetailState());

  final ShopRepository _repository;

  Future<void> load(String shopId) async {
    safeEmit(state.copyWith(status: ShopDetailStatus.loading));
    final result = await _repository.getShopDetail(shopId);
    result.fold(
      (failure) => safeEmit(
        state.copyWith(status: ShopDetailStatus.error, error: failure.message),
      ),
      (shop) =>
          safeEmit(state.copyWith(status: ShopDetailStatus.loaded, shop: shop)),
    );
  }

  /// Local (dummy) favourite toggle — transient UI state only, never persisted.
  void toggleFavourite() =>
      safeEmit(state.copyWith(favourite: !state.favourite));
}
