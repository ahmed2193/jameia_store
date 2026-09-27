import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../domain/entities/recipes_feed.dart';

class RecipesState extends Equatable implements ScreenLoadState<RecipesState> {
  const RecipesState({
    this.load = const ScreenLoad(),
    this.feed = RecipesFeed.empty,
  });

  /// The first page's read, its freshness, the next page and the failure
  /// that goes with them.
  @override
  final ScreenLoad load;
  final RecipesFeed feed;

  LoadPhase get status => load.phase;
  Failure? get failure => load.failure;
  bool get isLoaded => load.isLoaded;
  bool get isLoadingMore => load.isLoadingMore;
  bool get loadMoreFailed => load.nextPageFailed;
  bool get isEmpty => isLoaded && feed.isEmpty;
  bool get canLoadMore => isLoaded && feed.hasMore && !isLoadingMore;

  @override
  RecipesState withLoad(ScreenLoad load) => copyWith(load: load);

  RecipesState copyWith({ScreenLoad? load, RecipesFeed? feed}) =>
      RecipesState(load: load ?? this.load.settled(), feed: feed ?? this.feed);

  @override
  List<Object?> get props => [load, feed];
}
