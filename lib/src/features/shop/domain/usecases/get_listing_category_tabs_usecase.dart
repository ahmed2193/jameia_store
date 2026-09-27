import 'dart:math' as math;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/domain/entities/catalog_product_query.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/catalog_browse_repository.dart';

class GetListingCategoryTabsParams extends Equatable {
  const GetListingCategoryTabsParams({required this.query});

  /// The list the tabs split ("Best sellers", a brand). Its own category
  /// scope, if any, is ignored: every tab sets its own.
  final CatalogProductQuery query;

  @override
  List<Object?> get props => [query];
}

/// The top-level categories a product list has products in — its category
/// tabs ("All | Snacks & Chocolate | Ice Cream"), in tree order.
///
/// The backend has no facets and a list row carries no category, so each
/// root is probed: `GET /v1/products` with the list's query scoped to that
/// root (a parent includes its descendants), one row, and only the `total`
/// is read. At most [maxProbesInFlight] probes run at once. A failed probe
/// drops its root; a failed tree read fails the whole call, and so do probes
/// that ALL failed (offline): "no tab has products" would be a guess.
class GetListingCategoryTabsUseCase
    implements
        UseCase<List<CatalogCategoryEntity>, GetListingCategoryTabsParams> {
  const GetListingCategoryTabsUseCase(this._repository);

  /// Probes running at the same time, to spare the backend a burst.
  static const int maxProbesInFlight = 4;
  static const int _probePage = 1;
  static const int _probeLimit = 1;

  final CatalogBrowseRepository _repository;

  @override
  Future<Either<Failure, List<CatalogCategoryEntity>>> call(
    GetListingCategoryTabsParams params,
  ) async {
    final tree = await _repository.getCategoryTree();
    return tree.fold<Future<Either<Failure, List<CatalogCategoryEntity>>>>(
      (failure) async => Left(failure),
      (tree) => _stockedRoots(
        tree.roots,
        params.query.copyWith(clearCategorySlug: true),
      ),
    );
  }

  /// [roots] that have at least one product of [base], in their order — or
  /// the first failure when no probe answered at all.
  /// Runs a small pool of workers over the roots; each worker takes the next
  /// unprobed root until none is left.
  Future<Either<Failure, List<CatalogCategoryEntity>>> _stockedRoots(
    List<CatalogCategoryEntity> roots,
    CatalogProductQuery base,
  ) async {
    final probes = List<Either<Failure, bool>?>.filled(roots.length, null);
    var next = 0;
    Future<void> worker() async {
      while (next < roots.length) {
        final index = next++;
        probes[index] = await _hasProducts(
          base.copyWith(categorySlug: roots[index].slug),
        );
      }
    }

    await Future.wait<void>([
      for (var i = 0; i < math.min(maxProbesInFlight, roots.length); i++)
        worker(),
    ]);
    final answered = probes.any((probe) => probe?.isRight() ?? false);
    if (roots.isNotEmpty && !answered) {
      return Left(probes.first!.swap().getOrElse(UnexpectedFailure.new));
    }
    return Right([
      for (var i = 0; i < roots.length; i++)
        if (probes[i]?.getOrElse(() => false) ?? false) roots[i],
    ]);
  }

  Future<Either<Failure, bool>> _hasProducts(CatalogProductQuery query) async =>
      (await _repository.getProducts(
        query: query,
        page: _probePage,
        limit: _probeLimit,
      )).map((page) => page.total > 0);
}
