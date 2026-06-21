import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';

/// State for the KeeTa `channel_list_main` landing — the channel/category
/// landing list (scene tabs + filter bar + shop feed).
class ChannelListState {
  const ChannelListState({
    required this.scenes,
    required this.activeScene,
    required this.filters,
    required this.activeFilter,
    required this.shops,
  });

  /// Scene tabs across the top (`tab_selected*` / `scence_item_selected`).
  final List<String> scenes;
  final int activeScene;

  /// Filter chips beneath the scene tabs (`filterId` / `filterDisplayName`).
  final List<String> filters;
  final int activeFilter;

  /// Shop cards feed for the active scene/filter.
  final List<Shop> shops;

  ChannelListState copyWith({
    int? activeScene,
    int? activeFilter,
    List<Shop>? shops,
  }) {
    return ChannelListState(
      scenes: scenes,
      activeScene: activeScene ?? this.activeScene,
      filters: filters,
      activeFilter: activeFilter ?? this.activeFilter,
      shops: shops ?? this.shops,
    );
  }
}

/// Page-scoped cubit (constructed inline in the screen, NOT registered in the
/// service locator). Serves dummy data straight off [KeetaRepository].
class ChannelListCubit extends Cubit<ChannelListState> {
  ChannelListCubit(this._repo)
      : super(
          ChannelListState(
            scenes: const ['All', 'Restaurants', 'Groceries'],
            activeScene: 0,
            filters: _repo.filters,
            activeFilter: 0,
            shops: _repo.shops,
          ),
        );

  final KeetaRepository _repo;

  void selectScene(int index) {
    if (index == state.activeScene) return;
    emit(state.copyWith(activeScene: index, shops: _shopsFor(index)));
  }

  void selectFilter(int index) {
    if (index == state.activeFilter) return;
    emit(state.copyWith(activeFilter: index));
  }

  List<Shop> _shopsFor(int scene) => switch (scene) {
        1 => _repo.restaurants,
        2 => _repo.groceries,
        _ => _repo.shops,
      };
}
