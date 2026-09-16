import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/shop_entity.dart';
import '../entities/shop_sort.dart';
import '../repositories/search_repository.dart';

/// Query the catalogue for shops matching [SearchParams.query], then apply the
/// results-page free-delivery filter + sort ordering.
///
/// Relocates the filtering/sorting business logic that previously lived inline
/// in `search_shop_screen.dart`'s `_results` getter.
class SearchUseCase implements UseCase<List<ShopEntity>, SearchParams> {
  final SearchRepository repository;
  const SearchUseCase(this.repository);

  @override
  Future<Either<Failure, List<ShopEntity>>> call(SearchParams params) async {
    final result = await repository.searchShops(params.query);
    return result.map(
      (shops) => _sortAndFilter(shops, params.sort, params.freeOnly),
    );
  }

  List<ShopEntity> _sortAndFilter(
      List<ShopEntity> shops, ShopSort sort, bool freeOnly) {
    var list = shops;
    if (freeOnly) {
      list = list.where((s) => s.freeDelivery).toList(growable: false);
    }
    final sorted = [...list];
    switch (sort) {
      case ShopSort.recommended:
        break;
      case ShopSort.rating:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
      case ShopSort.deliveryTime:
        sorted.sort(
          (a, b) => _deliveryMinutes(
            a.deliveryTime,
          ).compareTo(_deliveryMinutes(b.deliveryTime)),
        );
      case ShopSort.distance:
        sorted.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    }
    return sorted;
  }
}

/// Parses the leading minute count out of a KeeTa `deliveryTime` label such as
/// `"30-40 min"` → `30`. Shops with an unparseable / empty estimate sort last.
int _deliveryMinutes(String label) {
  final match = RegExp(r'\d+').firstMatch(label);
  return match == null ? 1 << 30 : int.parse(match.group(0)!);
}

/// Args for [SearchUseCase] — the committed/typed query plus the results-page
/// sort mode and free-delivery filter (both default to the discover-preview
/// behaviour: catalogue order, no filter).
class SearchParams extends Equatable {
  const SearchParams({
    required this.query,
    this.sort = ShopSort.recommended,
    this.freeOnly = false,
  });

  final String query;
  final ShopSort sort;
  final bool freeOnly;

  @override
  List<Object?> get props => [query, sort, freeOnly];
}
