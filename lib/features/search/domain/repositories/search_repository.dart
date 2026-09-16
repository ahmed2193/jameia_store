import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/shop_entity.dart';

/// Read/persist boundary for the global search feature. Offline, so every read
/// resolves from the in-memory catalogue (mapped to framework-free entities) and
/// the recents list is persisted through local storage; all methods still return
/// `Either<Failure, T>` so the presentation layer handles failure uniformly.
abstract class SearchRepository {
  /// Catalogue shops matching [query] (name / tag / dish), in catalogue order.
  Future<Either<Failure, List<ShopEntity>>> searchShops(String query);

  /// Popular-brands strip for the discover landing (catalogue shops with a logo).
  Future<Either<Failure, List<ShopEntity>>> popularBrands();

  /// Type-ahead completions for [query] (product / shop / category names).
  Future<Either<Failure, List<String>>> getSuggestions(String query);

  /// Hot-word chips for the discover landing (most common shop tags).
  Future<Either<Failure, List<String>>> hotWords();

  /// Persisted recent searches, most-recent first.
  Future<Either<Failure, List<String>>> recentSearches();

  /// Push [term] onto the recents (dedup + cap), returning the updated list.
  Future<Either<Failure, List<String>>> addRecentSearch(String term);

  /// Wipe the recents, returning the now-empty list.
  Future<Either<Failure, List<String>>> clearRecentSearches();
}
