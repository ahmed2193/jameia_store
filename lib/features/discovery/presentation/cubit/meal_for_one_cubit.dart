import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/meal_for_one_view.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/usecases/get_meal_for_one_usecase.dart';

enum MealForOneStatus { initial, loading, loaded, error }

/// State for the "Meal for One" channel: filter chips + the curated shop feed,
/// loaded through [GetMealForOneUseCase]. Tapping a chip re-curates the feed
/// synchronously off the loaded [MealForOneView].
class MealForOneState extends Equatable {
  const MealForOneState({
    this.status = MealForOneStatus.initial,
    this.filters = const [],
    this.shops = const <ShopEntity>[],
    this.activeFilter = 0,
    this.error,
  });

  final MealForOneStatus status;

  /// Filter chips beneath the banner (`filterId` / `filterDisplayName`).
  final List<String> filters;

  /// Curated single-person-meal shop feed for the active filter.
  final List<ShopEntity> shops;

  final int activeFilter;
  final String? error;

  MealForOneState copyWith({
    MealForOneStatus? status,
    List<String>? filters,
    List<ShopEntity>? shops,
    int? activeFilter,
    String? error,
  }) => MealForOneState(
    status: status ?? this.status,
    filters: filters ?? this.filters,
    shops: shops ?? this.shops,
    activeFilter: activeFilter ?? this.activeFilter,
    error: error ?? this.error,
  );

  @override
  List<Object?> get props => [status, filters, shops, activeFilter, error];
}

/// Page-scoped cubit — resolved via `sl<MealForOneCubit>()`; loads the curated
/// channel on construction.
class MealForOneCubit extends Cubit<MealForOneState>
    with SafeCubitMixin<MealForOneState> {
  MealForOneCubit(this._getMealForOne) : super(const MealForOneState()) {
    load();
  }

  final GetMealForOneUseCase _getMealForOne;
  MealForOneView? _view;

  Future<void> load() async {
    safeEmit(state.copyWith(status: MealForOneStatus.loading));
    final result = await _getMealForOne(const NoParams());
    result.fold(
      (failure) => safeEmit(
        state.copyWith(status: MealForOneStatus.error, error: failure.message),
      ),
      (view) {
        _view = view;
        safeEmit(
          state.copyWith(
            status: MealForOneStatus.loaded,
            filters: view.filters,
            shops: view.curatedFor(0),
            activeFilter: 0,
          ),
        );
      },
    );
  }

  void selectFilter(int index) {
    final view = _view;
    if (view == null || index == state.activeFilter) return;
    safeEmit(
      state.copyWith(activeFilter: index, shops: view.curatedFor(index)),
    );
  }
}
