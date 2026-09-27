import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../domain/entities/recipe_detail.dart';

class RecipeDetailState extends Equatable
    implements ScreenLoadState<RecipeDetailState> {
  const RecipeDetailState({this.load = const ScreenLoad(), this.detail});

  /// The recipe's read, its freshness (the device copy, a failed refresh …)
  /// and the failure that goes with them (not found, offline, error).
  @override
  final ScreenLoad load;
  final RecipeDetail? detail;

  LoadPhase get status => load.phase;
  Failure? get failure => load.failure;
  bool get isLoaded => load.isLoaded;

  /// The slug does not exist (any more): an empty state, not an error + retry.
  bool get isNotFound => load.isNotFound;

  @override
  RecipeDetailState withLoad(ScreenLoad load) => copyWith(load: load);

  RecipeDetailState copyWith({ScreenLoad? load, RecipeDetail? detail}) =>
      RecipeDetailState(
        load: load ?? this.load.settled(),
        detail: detail ?? this.detail,
      );

  @override
  List<Object?> get props => [load, detail];
}
