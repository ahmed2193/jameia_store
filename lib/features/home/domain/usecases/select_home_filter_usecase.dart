import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/featured_section_entity.dart';
import '../entities/home_filter_result.dart';
import '../entities/product_entity.dart';
import '../entities/shop_entity.dart';

/// Inputs for [SelectHomeFilterUseCase] — the tapped filter index plus the
/// immutable source lists the filter operates over (the full shop list, the
/// full featured-rail list, and the promo products used to detect offers).
class SelectHomeFilterParams extends Equatable {
  const SelectHomeFilterParams({
    required this.index,
    required this.filters,
    required this.shops,
    required this.sections,
    required this.promoProducts,
  });

  /// Index of the tapped filter chip within [filters].
  final int index;

  /// The (data-driven) filter labels.
  final List<String> filters;

  /// Full shop list (unfiltered source).
  final List<ShopEntity> shops;

  /// Full featured-rail list (unfiltered source, i.e. `allSections`).
  final List<FeaturedSectionEntity> sections;

  /// Promo products used to detect offer/promo rails.
  final List<ProductEntity> promoProducts;

  @override
  List<Object?> get props => [index, filters, shops, sections, promoProducts];
}

/// Apply a home filter chip: keyword-match the (data-driven) label to a real
/// subset/sort of both the shops AND the featured rails, so the feed visibly
/// shows just the related content for the tapped filter. Guards against a blank
/// feed if a subset filter matched nothing.
///
/// Pure business logic relocated verbatim from `HomeCubit.selectFilter`.
class SelectHomeFilterUseCase
    implements UseCase<HomeFilterResult, SelectHomeFilterParams> {
  const SelectHomeFilterUseCase();

  @override
  Future<Either<Failure, HomeFilterResult>> call(
      SelectHomeFilterParams params) async {
    final label = params.filters[params.index].toLowerCase();
    final all = params.shops;
    // Keyword-match the (data-driven) label → a real subset/sort so the feed
    // visibly shows just the related shops for the tapped filter.
    List<ShopEntity> shopResult;
    if (label.contains('free')) {
      shopResult = all.where((sh) => sh.freeDelivery).toList();
    } else if (label.contains('rating') ||
        label.contains('4.5') ||
        label.contains('top')) {
      shopResult = all.where((sh) => sh.rating >= 4.5).toList();
    } else if (label.contains('best') ||
        label.contains('selling') ||
        label.contains('popular')) {
      shopResult = [...all]
        ..sort((a, b) => b.ratingCount.compareTo(a.ratingCount));
    } else if (label.contains('fast') ||
        label.contains('quick') ||
        label.contains('min') ||
        label.contains('near')) {
      shopResult = [...all]..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    } else if (label.contains('featured') || label.contains('sponsor')) {
      shopResult = all.where((sh) => sh.sponsored).toList();
    } else if (label.contains('new')) {
      shopResult = all.reversed.toList();
    } else {
      shopResult = all; // Recommended / default — full list
    }
    // Guard against a blank feed if a subset filter matched nothing.
    if (shopResult.isEmpty) shopResult = all;

    // Filter the featured RAILS too: "Offers"/"Promo" → only rails that carry a
    // promo product; "Best"/"Popular" → best-selling rails first; else all.
    final promoSkus = {for (final p in params.promoProducts) p.sku};
    List<FeaturedSectionEntity> sectionResult;
    if (label.contains('offer') ||
        label.contains('promo') ||
        label.contains('deal') ||
        label.contains('discount')) {
      sectionResult = params.sections
          .where((sec) =>
              sec.products.any((p) => p.hasPromo || promoSkus.contains(p.sku)))
          .toList();
    } else if (label.contains('best') ||
        label.contains('selling') ||
        label.contains('popular')) {
      sectionResult = [...params.sections]
        ..sort((a, b) =>
            (b.isBestSelling ? 1 : 0).compareTo(a.isBestSelling ? 1 : 0));
    } else {
      sectionResult = params.sections; // Recommended / default — all rails
    }
    // Never blank the feed.
    if (sectionResult.isEmpty) sectionResult = params.sections;

    return Right(HomeFilterResult(shops: shopResult, sections: sectionResult));
  }
}
