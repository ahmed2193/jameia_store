import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/recipe_detail.dart';

enum RecipeDetailStatus { initial, loading, loaded, error }

class RecipeDetailState extends Equatable {
  const RecipeDetailState({
    this.status = RecipeDetailStatus.initial,
    this.detail,
    this.failure,
  });

  static const int _notFound = 404;

  final RecipeDetailStatus status;
  final RecipeDetail? detail;

  /// Transient — cleared on every [copyWith]; the page localizes it.
  final Failure? failure;

  bool get isLoaded => status == RecipeDetailStatus.loaded;

  /// The slug does not exist (any more): an empty state, not an error + retry.
  bool get isNotFound {
    final current = failure;
    return status == RecipeDetailStatus.error &&
        current is ServerFailure &&
        current.statusCode == _notFound;
  }

  RecipeDetailState copyWith({
    RecipeDetailStatus? status,
    RecipeDetail? detail,
    Failure? failure,
  }) => RecipeDetailState(
    status: status ?? this.status,
    detail: detail ?? this.detail,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, detail, failure];
}
