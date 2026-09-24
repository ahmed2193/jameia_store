import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/recent_searches.dart';
import '../repositories/search_repository.dart';

class SaveRecentSearchesParams extends Equatable {
  const SaveRecentSearchesParams(this.recents);

  /// What to store — [RecentSearches.empty] clears the history.
  final RecentSearches recents;

  @override
  List<Object?> get props => [recents];
}

/// Persists the recent search terms on this device.
class SaveRecentSearchesUseCase
    implements UseCase<Unit, SaveRecentSearchesParams> {
  const SaveRecentSearchesUseCase(this._repository);

  final SearchRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SaveRecentSearchesParams params) =>
      _repository.saveRecentSearches(params.recents);
}
