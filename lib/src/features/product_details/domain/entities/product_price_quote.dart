import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';

/// Everything the buy bar prints for the selection, decided in one place
/// (`ProductDetail.quoteFor`): what the pieces cost, what they came to
/// before (and whether that is a deal, with its percent off), and the Pro
/// line — the Pro price offered to a customer who is not a member, or the
/// fact that a member pays it. Money is fils.
class ProductPriceQuote extends Equatable {
  const ProductPriceQuote({
    required this.unitFils,
    required this.amountFils,
    this.struckFils,
    this.isDeal = false,
    this.savePercent = 0,
    this.proHintFils,
    this.proApplied = false,
  });

  /// One piece of the selection, for this customer; `0` = nothing to price
  /// (a variant product before an option is chosen).
  final int unitFils;

  /// The pieces together.
  final int amountFils;

  /// What the pieces came to before: the deal's price, else the regular
  /// price a Pro member does not pay; `null` without one.
  final int? struckFils;

  /// [struckFils] is a deal's price before (not a Pro saving).
  final bool isDeal;

  /// Whole percent off the deal; `0` = none.
  final int savePercent;

  /// One piece at the Pro price, offered to a customer who is not a member;
  /// never an upsell to a member.
  final int? proHintFils;

  /// A Pro member pays the Pro price.
  final bool proApplied;

  bool get hasPrice => unitFils > 0;

  double get amountKd => amountFils / CatalogProductEntity.filsPerDinar;
  double? get struckKd => _kd(struckFils);
  double? get proHintKd => _kd(proHintFils);

  static double? _kd(int? fils) =>
      fils == null ? null : fils / CatalogProductEntity.filsPerDinar;

  @override
  List<Object?> get props => [
    unitFils,
    amountFils,
    struckFils,
    isDeal,
    savePercent,
    proHintFils,
    proApplied,
  ];
}
