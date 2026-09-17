import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/kingkong_landing_view.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/usecases/get_kingkong_landing_usecase.dart';

enum KingKongLandingStatus { initial, loading, loaded, error }

/// State for the Jameia `homepage_kingkong_page` (category/kingKongPage) — the
/// KingKong category landing. Holds the sub-category chip row and the filtered
/// [Shop] feed for the active chip, loaded through [GetKingKongLandingUseCase].
class KingKongLandingState extends Equatable {
  const KingKongLandingState({
    this.status = KingKongLandingStatus.initial,
    this.subCategories = const [],
    this.shops = const <ShopEntity>[],
    this.activeSub = 0,
    this.error,
  });

  final KingKongLandingStatus status;

  /// Sub-category chips under the category title (`subCategory` rail).
  final List<String> subCategories;

  /// Shop cards feed for the active sub-category.
  final List<ShopEntity> shops;

  /// Index of the selected sub-category chip.
  final int activeSub;
  final String? error;

  KingKongLandingState copyWith({
    KingKongLandingStatus? status,
    List<String>? subCategories,
    List<ShopEntity>? shops,
    int? activeSub,
    String? error,
  }) => KingKongLandingState(
    status: status ?? this.status,
    subCategories: subCategories ?? this.subCategories,
    shops: shops ?? this.shops,
    activeSub: activeSub ?? this.activeSub,
    error: error ?? this.error,
  );

  @override
  List<Object?> get props => [status, subCategories, shops, activeSub, error];
}

/// Page-scoped cubit — resolved via `sl<KingKongLandingCubit>()`; the screen
/// kicks off [load] with the tapped categoryId. The base pool + sub-category
/// chips are derived by the use case; tapping a chip re-filters the feed
/// synchronously off the loaded [KingKongLandingView].
class KingKongLandingCubit extends Cubit<KingKongLandingState>
    with SafeCubitMixin<KingKongLandingState> {
  KingKongLandingCubit(this._getKingKongLanding)
    : super(const KingKongLandingState());

  final GetKingKongLandingUseCase _getKingKongLanding;
  KingKongLandingView? _view;

  Future<void> load(String categoryId) async {
    safeEmit(state.copyWith(status: KingKongLandingStatus.loading));
    final result = await _getKingKongLanding(
      GetKingKongLandingParams(categoryId),
    );
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: KingKongLandingStatus.error,
          error: failure.message,
        ),
      ),
      (view) {
        _view = view;
        safeEmit(
          state.copyWith(
            status: KingKongLandingStatus.loaded,
            subCategories: view.subCategories,
            shops: view.shopsForSub(0),
            activeSub: 0,
          ),
        );
      },
    );
  }

  void selectSub(int index) {
    final view = _view;
    if (view == null || index == state.activeSub) return;
    safeEmit(state.copyWith(activeSub: index, shops: view.shopsForSub(index)));
  }
}
