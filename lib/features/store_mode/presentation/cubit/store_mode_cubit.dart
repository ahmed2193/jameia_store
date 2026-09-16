import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/repositories/store_mode_repository.dart';

/// Global store-mode state (VIP ⇄ Mart). Single immutable [Equatable] state so
/// consumers rebuild via `BlocBuilder<StoreModeCubit, StoreModeState>` on
/// `state.isVip` — replacing the old `ValueListenableBuilder(valueListenable:
/// repo.isVip)` reads scattered across home / shop / product-details.
class StoreModeState extends Equatable {
  const StoreModeState({required this.isVip});

  /// `true` → VIP pricing, `false` → Mart.
  final bool isVip;

  StoreModeState copyWith({bool? isVip}) =>
      StoreModeState(isVip: isVip ?? this.isVip);

  @override
  List<Object?> get props => [isVip];
}

/// App-wide store-mode cubit — provided once at the root (see `main.dart`,
/// alongside `CartCubit`). It is the single writer of the active mode: [setVip]
/// writes through the [StoreModeRepository] (so the shared catalogue's
/// `product.priceFor(...)` / `modeCard` and any legacy `isVip` listeners stay
/// in sync) and emits the new state for [BlocBuilder] consumers.
class StoreModeCubit extends Cubit<StoreModeState>
    with SafeCubitMixin<StoreModeState> {
  StoreModeCubit(this._repo)
      : super(StoreModeState(isVip: _repo.isVip));

  final StoreModeRepository _repo;

  /// Flip / set the active mode. No-op when already in [vip] mode. Callers that
  /// need the "switching modes clears the active cart" invariant (the home
  /// toggle) clear the cart themselves after this returns.
  void setVip(bool vip) {
    if (state.isVip == vip) return;
    _repo.setVip(vip);
    safeEmit(StoreModeState(isVip: vip));
  }

  /// Convenience toggle (Mart ⇄ VIP).
  void toggle() => setVip(!state.isVip);
}
