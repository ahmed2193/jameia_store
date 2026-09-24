import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/recent_searches.dart';
import '../repositories/search_repository.dart';

/// The recent search terms stored on this device.
class GetRecentSearchesUseCase
    implements SyncUseCase<RecentSearches, NoParams> {
  const GetRecentSearchesUseCase(this._repository);

  final SearchRepository _repository;

  @override
  Either<Failure, RecentSearches> call(NoParams params) =>
      _repository.getRecentSearches();
}
