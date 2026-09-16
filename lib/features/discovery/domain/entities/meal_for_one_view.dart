import 'package:equatable/equatable.dart';

import 'shop_entity.dart';

/// Loaded snapshot for the KeeTa "Meal for One" channel — the filter chips and
/// the full shop pool the chips curate.
///
/// [GetMealForOneUseCase] seeds the view from the full shop set + real filters;
/// this immutable view then curates the feed synchronously via [curatedFor] as
/// the user taps a chip (an async use case cannot serve a tap).
class MealForOneView extends Equatable {
  const MealForOneView({required this.filters, required this.shops});

  /// Filter chips beneath the banner (`filterId` / `filterDisplayName`).
  final List<String> filters;

  /// Full shop pool the chips curate.
  final List<ShopEntity> shops;

  /// Curated single-person-meal feed for [filter], seeded from the full pool:
  /// 0 Recommended (as-is) · 1 Nearby (by distance) · 2 Fastest (delivery time) ·
  /// 3 Free delivery (only free-delivery shops).
  List<ShopEntity> curatedFor(int filter) {
    final base = shops;
    return switch (filter) {
      1 =>
        (base.toList()..sort((a, b) => a.distanceKm.compareTo(b.distanceKm))),
      2 =>
        (base.toList()
          ..sort((a, b) => _deliveryMinutes(a).compareTo(_deliveryMinutes(b)))),
      3 => base.where((s) => s.freeDelivery).toList(growable: false),
      _ => base,
    };
  }

  /// [ShopEntity.deliveryTime] is a display String (e.g. `'9 min'`,
  /// `'15-25 min'`); extract the leading integer so "Fastest" sorts numerically
  /// instead of lexicographically. Shops with no parseable number sink to the
  /// bottom.
  static int _deliveryMinutes(ShopEntity shop) {
    final match = RegExp(r'\d+').firstMatch(shop.deliveryTime);
    return match == null ? 1 << 30 : int.parse(match.group(0)!);
  }

  @override
  List<Object?> get props => [filters, shops];
}
