import 'package:flutter/widgets.dart';

import '../design/hero_assets.dart';
import '../domain/entities/offer_reward_entity.dart';
import 'hero_svg_glyph.dart';

/// The Hero offer plate of a reward kind (colours baked in): the scooter for
/// free delivery, "%" for a percentage off, the voucher for money off, the
/// gift for a free product ([assetFor]; none for any other offer).
/// Decorative: the offer's words always sit beside it.
class OfferPlate extends StatelessWidget {
  const OfferPlate({super.key, required this.asset, required this.size});

  /// A `HeroAssets.offer*` path, from [assetFor].
  final String asset;
  final double size;

  static String? assetFor(OfferRewardType type) => switch (type) {
    OfferRewardType.freeDelivery => HeroAssets.offerDelivery,
    OfferRewardType.percentageDiscount => HeroAssets.offerPercent,
    OfferRewardType.fixedDiscount => HeroAssets.offerVoucher,
    OfferRewardType.freeProduct => HeroAssets.offerGift,
    OfferRewardType.other => null,
  };

  @override
  Widget build(BuildContext context) => HeroSvgGlyph.art(asset, size: size);
}
