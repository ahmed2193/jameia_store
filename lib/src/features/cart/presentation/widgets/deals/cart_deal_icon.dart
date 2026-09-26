import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/design/jameia_assets.dart';
import '../../../../../core/domain/entities/offer_reward_entity.dart';
import '../../../../../core/responsive/app_size.dart';

/// The rounded glyph of a deal card: the scooter for free delivery, a gift
/// for a free product, a voucher for any discount.
class CartDealIcon extends StatelessWidget {
  const CartDealIcon({super.key, required this.type, this.size = AppSize.s20});

  final OfferRewardType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = switch (type) {
      OfferRewardType.freeDelivery => JameiaAssets.offerDelivery,
      OfferRewardType.freeProduct => JameiaAssets.offerGift,
      OfferRewardType.percentageDiscount ||
      OfferRewardType.fixedDiscount ||
      OfferRewardType.other => JameiaAssets.offerVoucher,
    };
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      excludeFromSemantics: true,
    );
  }
}
