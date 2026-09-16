import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/usecases/get_pick_up_shops_usecase.dart';

enum PickUpStatus { initial, loading, loaded, error }

/// State for the KeeTa `pick_up_page_main` — the self-pickup shop list. Pickup
/// serves a single distance-sorted shop feed (the real `v2/homePage/
/// pickUpShopList`) built by [GetPickUpShopsUseCase], so the state is just the
/// ordered [shops].
class PickUpState extends Equatable {
  const PickUpState({
    this.status = PickUpStatus.initial,
    this.shops = const <ShopEntity>[],
    this.error,
  });

  final PickUpStatus status;

  /// Distance-sorted pickup shop feed (nearest first).
  final List<ShopEntity> shops;
  final String? error;

  PickUpState copyWith({
    PickUpStatus? status,
    List<ShopEntity>? shops,
    String? error,
  }) => PickUpState(
    status: status ?? this.status,
    shops: shops ?? this.shops,
    error: error ?? this.error,
  );

  @override
  List<Object?> get props => [status, shops, error];
}

/// Page-scoped cubit — resolved via `sl<PickUpCubit>()`; loads the distance-
/// sorted pickup feed on construction.
class PickUpCubit extends Cubit<PickUpState> with SafeCubitMixin<PickUpState> {
  PickUpCubit(this._getPickUpShops) : super(const PickUpState()) {
    load();
  }

  final GetPickUpShopsUseCase _getPickUpShops;

  Future<void> load() async {
    safeEmit(state.copyWith(status: PickUpStatus.loading));
    final result = await _getPickUpShops(const NoParams());
    result.fold(
      (failure) => safeEmit(
        state.copyWith(status: PickUpStatus.error, error: failure.message),
      ),
      (shops) =>
          safeEmit(state.copyWith(status: PickUpStatus.loaded, shops: shops)),
    );
  }
}
