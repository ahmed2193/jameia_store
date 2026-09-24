import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/recipes_feed.dart';

enum RecipesStatus { initial, loading, loaded, error }

class RecipesState extends Equatable {
  const RecipesState({
    this.status = RecipesStatus.initial,
    this.feed = RecipesFeed.empty,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.failure,
  });

  final RecipesStatus status;
  final RecipesFeed feed;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  /// Transient — cleared on every [copyWith]; the page localizes it.
  final Failure? failure;

  bool get isLoaded => status == RecipesStatus.loaded;
  bool get isEmpty => isLoaded && feed.isEmpty;
  bool get canLoadMore => isLoaded && feed.hasMore && !isLoadingMore;

  RecipesState copyWith({
    RecipesStatus? status,
    RecipesFeed? feed,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    Failure? failure,
  }) => RecipesState(
    status: status ?? this.status,
    feed: feed ?? this.feed,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    status,
    feed,
    isLoadingMore,
    loadMoreFailed,
    failure,
  ];
}
