import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/channel_list_view.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/usecases/get_channel_list_usecase.dart';

enum ChannelListStatus { initial, loading, loaded, error }

/// State for the KeeTa `channel_list_main` landing — the channel/category
/// landing list (scene tabs + filter bar + shop feed), loaded through
/// [GetChannelListUseCase].
class ChannelListState extends Equatable {
  const ChannelListState({
    this.status = ChannelListStatus.initial,
    this.scenes = const [],
    this.filters = const [],
    this.shops = const <ShopEntity>[],
    this.activeScene = 0,
    this.activeFilter = 0,
    this.error,
  });

  final ChannelListStatus status;

  /// Scene tabs across the top (`tab_selected*` / `scence_item_selected`).
  final List<String> scenes;

  /// Filter chips beneath the scene tabs (`filterId` / `filterDisplayName`).
  final List<String> filters;

  /// Shop cards feed for the active scene/filter.
  final List<ShopEntity> shops;

  final int activeScene;
  final int activeFilter;
  final String? error;

  ChannelListState copyWith({
    ChannelListStatus? status,
    List<String>? scenes,
    List<String>? filters,
    List<ShopEntity>? shops,
    int? activeScene,
    int? activeFilter,
    String? error,
  }) => ChannelListState(
    status: status ?? this.status,
    scenes: scenes ?? this.scenes,
    filters: filters ?? this.filters,
    shops: shops ?? this.shops,
    activeScene: activeScene ?? this.activeScene,
    activeFilter: activeFilter ?? this.activeFilter,
    error: error ?? this.error,
  );

  @override
  List<Object?> get props => [
    status,
    scenes,
    filters,
    shops,
    activeScene,
    activeFilter,
    error,
  ];
}

/// Page-scoped cubit — resolved via `sl<ChannelListCubit>()`; loads the channel
/// landing on construction. Scene tabs are derived from the distinct shop tags
/// by the use case; tapping a tab/filter re-derives the feed synchronously off
/// the loaded [ChannelListView].
class ChannelListCubit extends Cubit<ChannelListState>
    with SafeCubitMixin<ChannelListState> {
  ChannelListCubit(this._getChannelList) : super(const ChannelListState()) {
    load();
  }

  final GetChannelListUseCase _getChannelList;
  ChannelListView? _view;

  Future<void> load() async {
    safeEmit(state.copyWith(status: ChannelListStatus.loading));
    final result = await _getChannelList(const NoParams());
    result.fold(
      (failure) => safeEmit(
        state.copyWith(status: ChannelListStatus.error, error: failure.message),
      ),
      (view) {
        _view = view;
        safeEmit(
          state.copyWith(
            status: ChannelListStatus.loaded,
            scenes: view.scenes,
            filters: view.filters,
            shops: view.shopsForScene(0),
            activeScene: 0,
            activeFilter: 0,
          ),
        );
      },
    );
  }

  void selectScene(int index) {
    final view = _view;
    if (view == null || index == state.activeScene) return;
    safeEmit(
      state.copyWith(activeScene: index, shops: view.shopsForScene(index)),
    );
  }

  void selectFilter(int index) {
    final view = _view;
    if (view == null || index == state.activeFilter) return;
    safeEmit(
      state.copyWith(
        activeFilter: index,
        shops: view.shopsForScene(state.activeScene),
      ),
    );
  }
}
