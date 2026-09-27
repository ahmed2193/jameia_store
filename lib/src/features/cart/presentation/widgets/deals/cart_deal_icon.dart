import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/domain/entities/offer_reward_entity.dart';
import '../../../../../core/responsive/app_size.dart';

/// The rounded glyph of a deal card: the scooter for free delivery, a gift
/// for a free product, a voucher for any discount.
class CartDealIcon extends StatelessWidget {
  const CartDealIcon({super.key, required this.type});

  final OfferRewardType type;

  static const double _size = AppSize.s20;

  @override
  Widget build(BuildContext context) {
    final asset = switch (type) {
      OfferRewardType.freeDelivery => HeroAssets.offerDelivery,
      OfferRewardType.freeProduct => HeroAssets.offerGift,
      OfferRewardType.percentageDiscount ||
      OfferRewardType.fixedDiscount ||
      OfferRewardType.other => HeroAssets.offerVoucher,
    };
    return SvgPicture.asset(
      asset,
      width: _size,
      height: _size,
      excludeFromSemantics: true,
    );
  }
}
