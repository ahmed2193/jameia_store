import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_local_data_source.dart';
import '../mappers/shop_mapper.dart';

/// Offline search repository — reads the [SearchLocalDataSource] (catalogue +
/// persisted recents) and wraps each result in `Either<Failure, T>`.
class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl({required this.local});

  final SearchLocalDataSource local;

  /// Most-recent-first cap for the persisted recents (KeeTa keeps a short list).
  static const int _maxRecents = 10;

  @override
  Future<Either<Failure, List<ShopEntity>>> searchShops(String query) async {
    try {
      return Right(local.searchShops(query).toEntities());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ShopEntity>>> popularBrands() async {
    try {
      return Right(local.popularBrands().toEntities());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getSuggestions(String query) async {
    try {
      return Right(local.suggestions(query));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> hotWords() async {
    try {
      return Right(local.hotWords());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> recentSearches() async {
    try {
      return Right(local.recentSearches());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> addRecentSearch(String term) async {
    try {
      final t = term.trim();
      if (t.isEmpty) return Right(local.recentSearches());
      // Dedup (move-to-front) + cap — relocated from the screen's `_submit`.
      final current = local.recentSearches();
      final updated = <String>[t, ...current.where((e) => e != t)];
      final capped = updated.length > _maxRecents
          ? updated.sublist(0, _maxRecents)
          : updated;
      unawaited(_safeSave(capped));
      return Right(capped);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> clearRecentSearches() async {
    try {
      unawaited(_safeSave(const []));
      return const Right([]);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Fire-and-forget persist (best-effort — never blocks the UI).
  Future<void> _safeSave(List<String> terms) async {
    try {
      await local.saveRecentSearches(terms);
    } catch (_) {/* best-effort persistence */}
  }
}
